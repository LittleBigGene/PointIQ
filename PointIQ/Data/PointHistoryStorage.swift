//
//  PointHistoryStorage.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Codable representation of a Point for local storage
struct PointData: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let strokeTokens: [String] // StrokeToken raw values
    let outcome: String // Outcome raw value
    let serveType: String?
    let receiveType: String?
    let rallyTypes: [String]
    let gameNumber: Int?
    
    init(from point: Point, gameNumber: Int? = nil) {
        self.id = point.uniqueID
        self.timestamp = point.timestamp
        self.strokeTokens = point.strokeTokens.map { $0.rawValue }
        self.outcome = point.outcome.rawValue
        self.serveType = point.serveType
        self.receiveType = point.receiveType
        self.rallyTypes = point.rallyTypes
        self.gameNumber = gameNumber
    }
    
    /// Direct initializer for Supabase data
    init(
        id: String,
        timestamp: Date,
        strokeTokens: [String],
        outcome: String,
        serveType: String?,
        receiveType: String?,
        rallyTypes: [String],
        gameNumber: Int?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.strokeTokens = strokeTokens
        self.outcome = outcome
        self.serveType = serveType
        self.receiveType = receiveType
        self.rallyTypes = rallyTypes
        self.gameNumber = gameNumber
    }
    
    /// Convert back to a displayable format
    var strokeTokenValues: [StrokeToken] {
        strokeTokens.compactMap { StrokeToken(rawValue: $0) }
    }
    
    var outcomeValue: Outcome? {
        Outcome(rawValue: outcome)
    }
}

/// Service for storing point history with Supabase integration
/// Falls back to local storage if Supabase is not configured
class PointHistoryStorage {
    static let shared = PointHistoryStorage()
    
    private let fileName = "current_match_point_history.json"
    private var useSupabase: Bool {
        SupabaseConfig.isConfigured
    }
    
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {}
    
    /// Save a point to storage (Supabase if configured, otherwise local)
    func savePoint(_ point: Point, gameNumber: Int? = nil) {
        let pointData = PointData(from: point, gameNumber: gameNumber)
        
        if useSupabase {
            // Save to Supabase asynchronously
            Task {
                do {
                    try await SupabaseService.shared.savePoint(pointData)
                    print("✅ Point saved to Supabase: \(pointData.id)")
                } catch {
                    print("❌ Error saving to Supabase, falling back to local: \(error)")
                    // Fallback to local storage
                    saveToLocal(pointData)
                }
            }
            // Also save locally as backup
            saveToLocal(pointData)
        } else {
            // Save to local storage only
            saveToLocal(pointData)
        }
    }
    
    /// Load all stored points (from Supabase if configured, otherwise local)
    func loadAllPoints() -> [PointData] {
        if useSupabase {
            // Try to load from Supabase synchronously (using async wrapper)
            // For now, we'll load from local and sync in background
            let localPoints = loadFromLocal()
            
            // Sync from Supabase in background
            Task {
                do {
                    let supabasePoints = try await SupabaseService.shared.loadAllPoints()
                    // Merge and save locally for offline access
                    let mergedPoints = mergePoints(local: localPoints, remote: supabasePoints)
                    saveAllPointsLocally(mergedPoints)
                } catch {
                    print("⚠️ Error loading from Supabase: \(error)")
                }
            }
            
            return localPoints
        } else {
            return loadFromLocal()
        }
    }
    
    /// Load all points asynchronously (preferred for Supabase)
    func loadAllPointsAsync() async -> [PointData] {
        if useSupabase {
            do {
                let points = try await SupabaseService.shared.loadAllPoints()
                // Cache locally for offline access
                saveAllPointsLocally(points)
                return points
            } catch {
                print("⚠️ Error loading from Supabase, using local: \(error)")
                return loadFromLocal()
            }
        } else {
            return loadFromLocal()
        }
    }
    
    /// Clear all stored points (called on resetMatch)
    func clearAllPoints() {
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.clearAllPoints()
                    print("✅ All points cleared from Supabase")
                } catch {
                    print("❌ Error clearing Supabase: \(error)")
                }
            }
        }
        
        // Always clear local storage
        clearLocalStorage()
    }
    
    /// Remove a point by its unique ID (for undo functionality)
    func removePoint(byID id: String) {
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.deletePoint(byID: id)
                    print("✅ Point removed from Supabase: \(id)")
                } catch {
                    print("❌ Error removing from Supabase: \(error)")
                }
            }
        }
        
        // Always remove from local storage
        var allPoints = loadFromLocal()
        allPoints.removeAll { $0.id == id }
        saveAllPointsLocally(allPoints)
    }
    
    /// Remove the last point (for undo functionality - fallback)
    func removeLastPoint() {
        var allPoints = loadFromLocal()
        if !allPoints.isEmpty {
            let lastPoint = allPoints.removeLast()
            removePoint(byID: lastPoint.id)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveToLocal(_ pointData: PointData) {
        var allPoints = loadFromLocal()
        // Avoid duplicates
        if !allPoints.contains(where: { $0.id == pointData.id }) {
            allPoints.append(pointData)
            saveAllPointsLocally(allPoints)
        }
    }
    
    private func loadFromLocal() -> [PointData] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([PointData].self, from: data)
        } catch {
            print("Error loading point history: \(error)")
            return []
        }
    }
    
    private func saveAllPointsLocally(_ points: [PointData]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(points)
            try data.write(to: fileURL)
        } catch {
            print("Error saving point history: \(error)")
        }
    }
    
    private func clearLocalStorage() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing point history: \(error)")
        }
    }
    
    private func mergePoints(local: [PointData], remote: [PointData]) -> [PointData] {
        var merged: [String: PointData] = [:]
        
        // Add local points
        for point in local {
            merged[point.id] = point
        }
        
        // Add/update with remote points (remote takes precedence)
        for point in remote {
            merged[point.id] = point
        }
        
        // Sort by timestamp
        return Array(merged.values).sorted { $0.timestamp > $1.timestamp }
    }
}

