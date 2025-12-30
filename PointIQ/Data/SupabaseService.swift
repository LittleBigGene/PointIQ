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
    }
    
    /// Cached ISO8601 date formatter for parsing timestamps from database
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
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
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseKey
        )
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
        PointInsert(
            id: pointData.id,
            timestamp: pointData.timestamp.ISO8601Format(),
            strokeTokens: pointData.strokeTokens,
            outcome: pointData.outcome,
            serveType: pointData.serveType,
            receiveType: pointData.receiveType,
            rallyTypes: pointData.rallyTypes,
            gameNumber: pointData.gameNumber,
            createdAt: Date().ISO8601Format(),
            matchId: matchId,
            gameId: gameId
        )
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
    func uploadMatch(_ match: Match) async throws {
        #if canImport(Supabase)
        let client = try requireClient()
        let matchID = match.id.uuidString
        
        // 1. Upload the match
        let matchInsert = MatchInsert(
            id: matchID,
            startDate: match.startDate.ISO8601Format(),
            endDate: match.endDate?.ISO8601Format(),
            opponentName: match.opponentName,
            notes: match.notes,
            createdAt: Date().ISO8601Format()
        )
        
        try await client.from(Table.matches)
            .insert(matchInsert)
            .execute()
        
        print("✅ Match uploaded: \(matchID)")
        
        // 2. Upload games and their points
        guard let games = match.games else {
            print("✅ Match upload complete: \(matchID)")
            return
        }
        
        for game in games {
            try await uploadGame(game, matchID: matchID)
            
            // Upload points for this game
            if let points = game.points {
                for point in points {
                    let pointData = PointData(from: point, gameNumber: game.gameNumber)
                    let pointInsert = pointInsert(
                        from: pointData,
                        matchId: matchID,
                        gameId: game.id.uuidString
                    )
                    
                    try await client.from(Table.points)
                        .insert(pointInsert)
                        .execute()
                }
            }
        }
        
        print("✅ Match upload complete: \(matchID)")
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
            createdAt: Date().ISO8601Format()
        )
        
        try await client.from(Table.games)
            .insert(gameInsert)
            .execute()
        
        print("✅ Game uploaded: \(game.id.uuidString)")
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
    let notes: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDate = "start_date"
        case endDate = "end_date"
        case opponentName = "opponent_name"
        case notes
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
        case matchId = "match_id"
        case createdAt = "created_at"
    }
}
#endif
