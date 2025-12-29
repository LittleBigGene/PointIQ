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
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase not configured. Please set your Supabase URL and key in SupabaseConfig.swift")
            return
        }
        
        #if canImport(Supabase)
        do {
            client = try SupabaseClient(
                supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
                supabaseKey: SupabaseConfig.supabaseKey
            )
            print("✅ Supabase client initialized successfully")
        } catch {
            print("❌ Error initializing Supabase client: \(error)")
        }
        #else
        print("⚠️ Supabase SDK not available. Please add the Supabase Swift package.")
        #endif
    }
    
    // MARK: - Point Data Operations
    
    /// Save a point to Supabase
    func savePoint(_ pointData: PointData) async throws {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let pointRow: [String: Any] = [
            "id": pointData.id,
            "timestamp": pointData.timestamp.ISO8601Format(),
            "stroke_tokens": pointData.strokeTokens,
            "outcome": pointData.outcome,
            "serve_type": pointData.serveType as Any,
            "receive_type": pointData.receiveType as Any,
            "rally_types": pointData.rallyTypes,
            "game_number": pointData.gameNumber as Any,
            "created_at": Date().ISO8601Format()
        ]
        
        try await client.database
            .from("points")
            .insert(pointRow)
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load all points from Supabase
    func loadAllPoints() async throws -> [PointData] {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: [PointRow] = try await client.database
            .from("points")
            .select()
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return response.compactMap { row in
            guard let timestamp = ISO8601DateFormatter().date(from: row.timestamp) else {
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
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Delete a point by ID
    func deletePoint(byID id: String) async throws {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.database
            .from("points")
            .delete()
            .eq("id", value: id)
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Clear all points (delete all records)
    func clearAllPoints() async throws {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.database
            .from("points")
            .delete()
            .neq("id", value: "") // Delete all rows
            .execute()
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Load points for a specific match (if you add match_id to PointData)
    func loadPointsForMatch(matchID: String) async throws -> [PointData] {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: [PointRow] = try await client.database
            .from("points")
            .select()
            .eq("match_id", value: matchID)
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return response.compactMap { row in
            guard let timestamp = ISO8601DateFormatter().date(from: row.timestamp) else {
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
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    // MARK: - Match Operations
    
    /// Upload a complete match (match, games, and points) to Supabase
    func uploadMatch(_ match: Match) async throws {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        // 1. Upload the match
        let matchRow: [String: Any] = [
            "id": match.id.uuidString,
            "start_date": match.startDate.ISO8601Format(),
            "end_date": match.endDate?.ISO8601Format() as Any,
            "opponent_name": match.opponentName as Any,
            "notes": match.notes as Any,
            "created_at": Date().ISO8601Format()
        ]
        
        try await client.database
            .from("matches")
            .insert(matchRow)
            .execute()
        
        print("✅ Match uploaded: \(match.id.uuidString)")
        
        // 2. Upload games
        if let games = match.games {
            for game in games {
                try await uploadGame(game, matchID: match.id.uuidString)
            }
        }
        
        // 3. Upload points
        if let games = match.games {
            for game in games {
                if let points = game.points {
                    for point in points {
                        let pointData = PointData(from: point, gameNumber: game.gameNumber)
                        var pointRow: [String: Any] = [
                            "id": pointData.id,
                            "match_id": match.id.uuidString,
                            "game_id": game.id.uuidString,
                            "timestamp": pointData.timestamp.ISO8601Format(),
                            "stroke_tokens": pointData.strokeTokens,
                            "outcome": pointData.outcome,
                            "serve_type": pointData.serveType as Any,
                            "receive_type": pointData.receiveType as Any,
                            "rally_types": pointData.rallyTypes,
                            "game_number": pointData.gameNumber as Any,
                            "created_at": Date().ISO8601Format()
                        ]
                        
                        try await client.database
                            .from("points")
                            .insert(pointRow)
                            .execute()
                    }
                }
            }
        }
        
        print("✅ Match upload complete: \(match.id.uuidString)")
        #else
        throw SupabaseError.sdkNotAvailable
        #endif
    }
    
    /// Upload a game to Supabase
    private func uploadGame(_ game: Game, matchID: String) async throws {
        guard SupabaseConfig.isConfigured else {
            throw SupabaseError.notConfigured
        }
        
        #if canImport(Supabase)
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let gameRow: [String: Any] = [
            "id": game.id.uuidString,
            "match_id": matchID,
            "game_number": game.gameNumber,
            "start_date": game.startDate.ISO8601Format(),
            "end_date": game.endDate?.ISO8601Format() as Any,
            "player_serves_first": game.playerServesFirst,
            "created_at": Date().ISO8601Format()
        ]
        
        try await client.database
            .from("games")
            .insert(gameRow)
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

