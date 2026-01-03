//
//  SupabaseService.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

/// Service for interacting with Supabase database
class SupabaseService {
    static let shared = SupabaseService()
    
    #if canImport(Supabase)
    private var client: SupabaseClient?
    #endif
    
    // MARK: - Constants
    
    private enum Table {
        static let points = "points"
        static let matches = "matches"
        static let games = "games"
        static let playerProfiles = "player_profiles"
    }
    
    /// Cached ISO8601 date formatter for parsing timestamps from database
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Helper to format current date as ISO8601 string
    private static var currentTimestamp: String {
        Date().ISO8601Format()
    }
    
    // MARK: - Initialization
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase not configured. Please set your Supabase URL and key in SupabaseConfig.swift")
            return
        }
        
        #if canImport(Supabase)
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            print("❌ Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
            return
        }
        
        // Initialize client
        // Note: "Initial session emitted" warnings are non-critical for anonymous access
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseKey
        )
        
        // Clear any invalid session on startup to prevent refresh errors
        Task {
            try? await client?.auth.signOut()
        }
        
        print("✅ Supabase client initialized successfully")
        #else
        print("⚠️ Supabase SDK not available. Please add the Supabase Swift package.")
        #endif
    }
    
    // MARK: - Helper Methods
    
    #if canImport(Supabase)
    /// Validates configuration and returns client, or throws appropriate error
    private func requireClient() throws -> SupabaseClient {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        return client
    }
    
    /// Converts a PointRow from database to PointData
    private func pointData(from row: PointRow) -> PointData? {
        guard let timestamp = Self.dateFormatter.date(from: row.timestamp) else {
            return nil
        }
        
        return PointData(
            id: row.id,
            timestamp: timestamp,
            strokeTokens: row.strokeTokens,
            outcome: row.outcome,
            serveType: row.serveType,
            receiveType: row.receiveType,
            rallyTypes: row.rallyTypes,
            gameNumber: row.gameNumber
        )
    }
    
    /// Creates a PointInsert from PointData with optional match and game IDs
    private func pointInsert(
        from pointData: PointData,
        matchId: String? = nil,
        gameId: String? = nil
    ) -> PointInsert {
        // Derive point_winner, contact_made, and luck_factor from outcome
        let (pointWinner, contactMade, luckFactor) = derivePointFields(from: pointData.outcome)
        
        return PointInsert(
            id: pointData.id,
            timestamp: pointData.timestamp.ISO8601Format(),
            strokeTokens: pointData.strokeTokens,
            outcome: pointData.outcome,
            serveType: pointData.serveType,
            receiveType: pointData.receiveType,
            rallyTypes: pointData.rallyTypes,
            gameNumber: pointData.gameNumber,
            pointWinner: pointWinner,
            contactMade: contactMade,
            luckFactor: luckFactor,
            createdAt: Self.currentTimestamp,
            matchId: matchId,
            gameId: gameId
        )
    }
    
    /// Derives point_winner, contact_made, and luck_factor from outcome
    private func derivePointFields(from outcome: String) -> (pointWinner: String, contactMade: Bool, luckFactor: String?) {
        switch outcome {
        case "my_winner", "opponent_error":
            // Point won by player
            return ("me", true, "none")
        case "i_missed":
            // Didn't touch the ball
            return ("opponent", false, "none")
        case "my_error":
            // Touched ball but didn't land it
            return ("opponent", true, "none")
        case "unlucky":
            // Edge or net ball
            return ("opponent", true, "net or edge")
        default:
            // Fallback (shouldn't happen with valid outcomes)
            return ("opponent", true, "none")
        }
    }
    
    /// Creates a PlayerProfileInsert from profile data
    private func profileInsert(
        profileType: String,
        name: String,
        grip: String,
        handedness: String,
        blade: String,
        forehandRubber: String,
        backhandRubber: String,
        eloRating: Int?,
        clubName: String
    ) -> PlayerProfileInsert {
        PlayerProfileInsert(
            userId: nil, // For future multi-user support
            profileType: profileType,
            name: name,
            grip: grip,
            handedness: handedness,
            blade: blade,
            forehandRubber: forehandRubber,
            backhandRubber: backhandRubber,
            eloRating: eloRating,
            clubName: clubName,
            createdAt: Self.currentTimestamp
        )
    }
    
    /// Generic method to save/update a profile
    /// Uses check-then-insert/update approach to avoid issues with deferrable constraints
    private func saveProfile(
        profileType: String,
        name: String,
        grip: String,
        handedness: String,
        blade: String,
        forehandRubber: String,
        backhandRubber: String,
        eloRating: Int?,
        clubName: String,
        onConflict: String,
        returnId: Bool = false
    ) async throws -> String? {
        let client = try requireClient()
        let profileInsert = profileInsert(
            profileType: profileType,
            name: name,
            grip: grip,
            handedness: handedness,
            blade: blade,
            forehandRubber: forehandRubber,
            backhandRubber: backhandRubber,
            eloRating: eloRating,
            clubName: clubName
        )
        
        // Check if profile exists first (to avoid deferrable constraint issues)
        var existingProfile: PlayerProfileRow?
        
        if onConflict == "user_id,profile_type" {
            // For player profiles: check by user_id and profile_type
            let profiles: [PlayerProfileRow] = try await client.from(Table.playerProfiles)
                .select()
                .is("user_id", value: nil)
                .eq("profile_type", value: profileType)
                .is("deleted_at", value: nil)
                .limit(1)
                .execute()
                .value
            existingProfile = profiles.first
        } else if onConflict == "user_id,profile_type,name" {
            // For opponent profiles: check by user_id, profile_type, and name
            let profiles: [PlayerProfileRow] = try await client.from(Table.playerProfiles)
                .select()
                .is("user_id", value: nil)
                .eq("profile_type", value: profileType)
                .eq("name", value: name)
                .is("deleted_at", value: nil)
                .limit(1)
                .execute()
                .value
            existingProfile = profiles.first
        }
        
        if let existing = existingProfile {
            // Update existing profile
            let profileUpdate = PlayerProfileUpdate(
                grip: grip,
                handedness: handedness,
                blade: blade,
                forehandRubber: forehandRubber,
                backhandRubber: backhandRubber,
                eloRating: eloRating,
                clubName: clubName
            )
            
            try await client.from(Table.playerProfiles)
                .update(profileUpdate)
                .eq("id", value: existing.id)
                .execute()
            
            if returnId {
                return existing.id
            }
            return nil
        } else {
            // Insert new profile
            if returnId {
                let response: [PlayerProfileRow] = try await client.from(Table.playerProfiles)
                    .insert(profileInsert)
                    .select()
                    .execute()
                    .value
                
                guard let profile = response.first else {
                    throw SupabaseError.decodingError(NSError(
                        domain: "SupabaseService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get created profile ID"]
                    ))
                }
                return profile.id
            } else {
                try await client.from(Table.playerProfiles)
                    .insert(profileInsert)
                    .execute()
                return nil
            }
        }
    }
    
    /// Generic method to load profiles by type
    private func loadProfiles(
        profileType: String,
        limit: Int? = nil,
        orderBy: String? = nil
    ) async throws -> [PlayerProfileRow] {
        let client = try requireClient()
        
        let baseQuery = client.from(Table.playerProfiles)
            .select()
            .eq("profile_type", value: profileType)
            .is("deleted_at", value: nil)
        
        // Build query with optional ordering and limiting
        // Note: Order matters - order() must come before limit()
        if let orderBy = orderBy, let limit = limit {
            return try await baseQuery
                .order(orderBy, ascending: true)
                .limit(limit)
                .execute()
                .value
        } else if let orderBy = orderBy {
            return try await baseQuery
                .order(orderBy, ascending: true)
                .execute()
                .value
        } else if let limit = limit {
            return try await baseQuery
                .limit(limit)
                .execute()
                .value
        } else {
            return try await baseQuery
                .execute()
                .value
        }
    }
    
    /// Uploads all points for a game
    private func uploadPoints(
        for game: Game,
        matchID: String,
        client: SupabaseClient
    ) async throws -> Int {
        // Access points relationship - SwiftData may need to load it
        let points = game.points ?? []
        
        print("📊 Game \(game.gameNumber): Found \(points.count) points to upload")
        
        if points.isEmpty {
            print("⚠️ Game \(game.gameNumber): No points found (points relationship: \(game.points != nil ? "loaded" : "nil"))")
            return 0
        }
        
        var count = 0
        var errorCount = 0
        
        for (index, point) in points.enumerated() {
            do {
                let pointData = PointData(from: point, gameNumber: game.gameNumber)
                let pointInsert = pointInsert(
                    from: pointData,
                    matchId: matchID,
                    gameId: game.id.uuidString
                )
                
                try await client.from(Table.points)
                    .insert(pointInsert)
                    .execute()
                
                count += 1
                if (index + 1) % 10 == 0 {
                    print("   ✅ Uploaded \(index + 1)/\(points.count) points for game \(game.gameNumber)")
                }
            } catch {
                errorCount += 1
                print("❌ Error uploading point \(index + 1) for game \(game.gameNumber): \(error.localizedDescription)")
                // Continue with next point instead of failing completely
            }
        }
        
        if errorCount > 0 {
            print("⚠️ Game \(game.gameNumber): \(errorCount) points failed to upload out of \(points.count)")
        } else {
            print("✅ Game \(game.gameNumber): Successfully uploaded all \(count) points")
        }
        
        return count
    }
    #endif
    
    // MARK: - Point Data Operations
    
    /// Save a point to Supabase
    func savePoint(_ pointData: PointData) async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        let insert = pointInsert(from: pointData)
        
        try await client.from(Table.points)
            .insert(insert)
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load all points from Supabase
    func loadAllPoints() async throws -> [PointData] {
        #if canImport(Supabase)
        let client = try requireClient()
        
        let response: [PointRow] = try await client.from(Table.points)
            .select()
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return response.compactMap { pointData(from: $0) }
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Delete a point by ID
    func deletePoint(byID id: String) async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        
        try await client.from(Table.points)
            .delete()
            .eq("id", value: id)
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Clear all points (delete all records)
    func clearAllPoints() async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        
        try await client.from(Table.points)
            .delete()
            .neq("id", value: "") // Delete all rows
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load points for a specific match
    func loadPointsForMatch(matchID: String) async throws -> [PointData] {
        #if canImport(Supabase)
        let client = try requireClient()
        
        let response: [PointRow] = try await client.from(Table.points)
            .select()
            .eq("match_id", value: matchID)
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return response.compactMap { pointData(from: $0) }
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    // MARK: - Match Operations
    
    /// Upload a complete match (match, games, and points) to Supabase
    func uploadMatch(_ match: Match, opponentProfileId: String? = nil) async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        let matchID = match.id.uuidString
        
        // 1. Upload the match
        let matchInsert = MatchInsert(
            id: matchID,
            startDate: match.startDate.ISO8601Format(),
            endDate: match.endDate?.ISO8601Format(),
            opponentName: match.opponentName,
            opponentProfileId: opponentProfileId,
            notes: match.notes,
            bestOf: match.bestOf,
            createdAt: Self.currentTimestamp
        )
        
        try await client.from(Table.matches)
            .insert(matchInsert)
            .execute()
        
        print("✅ Match uploaded: \(matchID)")
        
        // 2. Upload games and their points
        guard let games = match.games else {
            print("✅ Match upload complete: \(matchID) (no games)")
            return
        }
        
        var totalGamesUploaded = 0
        var totalPointsUploaded = 0
        
        print("📊 Starting upload for \(games.count) games")
        
        // Also check match.points as an alternative source
        let matchPointsCount = match.points?.count ?? 0
        print("📊 Match has \(matchPointsCount) total points (via match.points relationship)")
        
        for game in games {
            print("🔄 Uploading game \(game.gameNumber)...")
            try await uploadGame(game, matchID: matchID)
            totalGamesUploaded += 1
            
            // Upload points for this game
            // Note: Access points property to ensure SwiftData loads the relationship
            let pointsCount = game.points?.count ?? 0
            print("   📍 Game \(game.gameNumber) has \(pointsCount) points in relationship")
            
            // If game.points is empty but match has points, try to filter match points by game
            if pointsCount == 0 && matchPointsCount > 0 {
                print("   ⚠️ Game \(game.gameNumber) has no points in relationship, checking match.points...")
                if let matchPoints = match.points {
                    let gamePoints = matchPoints.filter { point in
                        // Try to match points to this game by checking if point.game matches
                        point.game?.id == game.id
                    }
                    print("   📍 Found \(gamePoints.count) points for game \(game.gameNumber) via match.points")
                    
                    // Upload these points
                    for point in gamePoints {
                        do {
                            let pointData = PointData(from: point, gameNumber: game.gameNumber)
                            let pointInsert = pointInsert(
                                from: pointData,
                                matchId: matchID,
                                gameId: game.id.uuidString
                            )
                            
                            try await client.from(Table.points)
                                .insert(pointInsert)
                                .execute()
                            
                            totalPointsUploaded += 1
                        } catch {
                            print("❌ Error uploading point: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                totalPointsUploaded += try await uploadPoints(for: game, matchID: matchID, client: client)
            }
        }
        
        print("✅ Match upload complete: \(matchID)")
        print("   📊 Summary: 1 match, \(totalGamesUploaded) games, \(totalPointsUploaded) points")
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Upload a game to Supabase
    private func uploadGame(_ game: Game, matchID: String) async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        
        let gameInsert = GameInsert(
            id: game.id.uuidString,
            matchId: matchID,
            gameNumber: game.gameNumber,
            startDate: game.startDate.ISO8601Format(),
            endDate: game.endDate?.ISO8601Format(),
            playerServesFirst: game.playerServesFirst,
            createdAt: Self.currentTimestamp
        )
        
        try await client.from(Table.games)
            .insert(gameInsert)
            .execute()
        
        print("✅ Game uploaded: \(game.id.uuidString)")
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    // MARK: - Profile Operations
    
    /// Save or update player profile to Supabase
    func savePlayerProfile(
        name: String,
        grip: String,
        handedness: String,
        blade: String = "",
        forehandRubber: String = "",
        backhandRubber: String = "",
        eloRating: Int? = nil,
        clubName: String = ""
    ) async throws {
        #if canImport(Supabase)
        _ = try await saveProfile(
            profileType: "player",
            name: name,
            grip: grip,
            handedness: handedness,
            blade: blade,
            forehandRubber: forehandRubber,
            backhandRubber: backhandRubber,
            eloRating: eloRating,
            clubName: clubName,
            onConflict: "user_id,profile_type",
            returnId: false
        )
        print("✅ Player profile saved")
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Save or update opponent profile to Supabase
    func saveOpponentProfile(
        name: String,
        grip: String,
        handedness: String,
        blade: String = "",
        forehandRubber: String = "",
        backhandRubber: String = "",
        eloRating: Int? = nil,
        clubName: String = ""
    ) async throws -> String {
        #if canImport(Supabase)
        guard let profileId = try await saveProfile(
            profileType: "opponent",
            name: name,
            grip: grip,
            handedness: handedness,
            blade: blade,
            forehandRubber: forehandRubber,
            backhandRubber: backhandRubber,
            eloRating: eloRating,
            clubName: clubName,
            onConflict: "user_id,profile_type,name",
            returnId: true
        ) else {
            throw SupabaseError.decodingError(NSError(
                domain: "SupabaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get created profile ID"]
            ))
        }
        
        print("✅ Opponent profile saved: \(profileId)")
        return profileId
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load player profile from Supabase
    fileprivate func loadPlayerProfile() async throws -> PlayerProfileRow? {
        #if canImport(Supabase)
        let profiles = try await loadProfiles(profileType: "player", limit: 1)
        return profiles.first
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load all opponent profiles from Supabase
    fileprivate func loadOpponentProfiles() async throws -> [PlayerProfileRow] {
        #if canImport(Supabase)
        return try await loadProfiles(profileType: "opponent", orderBy: "name")
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
}

// MARK: - Supabase Error Types

enum SupabaseError: LocalizedError {
    case notConfigured
    case clientNotInitialized
    case sdkNotAvailable
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please set your URL and key in SupabaseConfig.swift"
        case .clientNotInitialized:
            return "Supabase client failed to initialize"
        case .sdkNotAvailable:
            return "Supabase SDK is not available. Please add the Supabase Swift package."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Database Row Models

#if canImport(Supabase)
// Insert models (for writing to database)
private struct PointInsert: Encodable {
    let id: String
    let timestamp: String
    let strokeTokens: [String]
    let outcome: String
    let serveType: String?
    let receiveType: String?
    let rallyTypes: [String]
    let gameNumber: Int?
    let pointWinner: String
    let contactMade: Bool
    let luckFactor: String?
    let createdAt: String
    let matchId: String?
    let gameId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case strokeTokens = "stroke_tokens"
        case outcome
        case serveType = "serve_type"
        case receiveType = "receive_type"
        case rallyTypes = "rally_types"
        case gameNumber = "game_number"
        case pointWinner = "point_winner"
        case contactMade = "contact_made"
        case luckFactor = "luck_factor"
        case createdAt = "created_at"
        case matchId = "match_id"
        case gameId = "game_id"
    }
}

private struct MatchInsert: Encodable {
    let id: String
    let startDate: String
    let endDate: String?
    let opponentName: String?
    let opponentProfileId: String?
    let notes: String?
    let bestOf: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDate = "start_date"
        case endDate = "end_date"
        case opponentName = "opponent_name"
        case opponentProfileId = "opponent_profile_id"
        case notes
        case bestOf = "best_of"
        case createdAt = "created_at"
    }
}

private struct GameInsert: Encodable {
    let id: String
    let matchId: String
    let gameNumber: Int
    let startDate: String
    let endDate: String?
    let playerServesFirst: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case gameNumber = "game_number"
        case startDate = "start_date"
        case endDate = "end_date"
        case playerServesFirst = "player_serves_first"
        case createdAt = "created_at"
    }
}

// Read models (for reading from database)
private struct PointRow: Codable {
    let id: String
    let timestamp: String
    let strokeTokens: [String]
    let outcome: String
    let serveType: String?
    let receiveType: String?
    let rallyTypes: [String]
    let gameNumber: Int?
    let pointWinner: String?
    let contactMade: Bool?
    let luckFactor: String?
    let matchId: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case strokeTokens = "stroke_tokens"
        case outcome
        case serveType = "serve_type"
        case receiveType = "receive_type"
        case rallyTypes = "rally_types"
        case gameNumber = "game_number"
        case pointWinner = "point_winner"
        case contactMade = "contact_made"
        case luckFactor = "luck_factor"
        case matchId = "match_id"
        case createdAt = "created_at"
    }
}

private struct PlayerProfileInsert: Encodable {
    let userId: String?
    let profileType: String
    let name: String
    let grip: String
    let handedness: String
    let blade: String
    let forehandRubber: String
    let backhandRubber: String
    let eloRating: Int?
    let clubName: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profileType = "profile_type"
        case name
        case grip
        case handedness
        case blade
        case forehandRubber = "forehand_rubber"
        case backhandRubber = "backhand_rubber"
        case eloRating = "elo_rating"
        case clubName = "club_name"
        case createdAt = "created_at"
    }
}

private struct PlayerProfileUpdate: Encodable {
    let grip: String
    let handedness: String
    let blade: String
    let forehandRubber: String
    let backhandRubber: String
    let eloRating: Int?
    let clubName: String
    
    enum CodingKeys: String, CodingKey {
        case grip
        case handedness
        case blade
        case forehandRubber = "forehand_rubber"
        case backhandRubber = "backhand_rubber"
        case eloRating = "elo_rating"
        case clubName = "club_name"
    }
}

private struct PlayerProfileRow: Codable {
    let id: String
    let userId: String?
    let profileType: String
    let name: String
    let grip: String
    let handedness: String
    let blade: String
    let forehandRubber: String
    let backhandRubber: String
    let eloRating: Int?
    let clubName: String
    let createdAt: String
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case profileType = "profile_type"
        case name
        case grip
        case handedness
        case blade
        case forehandRubber = "forehand_rubber"
        case backhandRubber = "backhand_rubber"
        case eloRating = "elo_rating"
        case clubName = "club_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}
#endif
