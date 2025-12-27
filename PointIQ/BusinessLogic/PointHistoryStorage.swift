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
    
    /// Convert back to a displayable format
    var strokeTokenValues: [StrokeToken] {
        strokeTokens.compactMap { StrokeToken(rawValue: $0) }
    }
    
    var outcomeValue: Outcome? {
        Outcome(rawValue: outcome)
    }
}

/// Service for storing point history locally until resetMatch
class PointHistoryStorage {
    static let shared = PointHistoryStorage()
    
    private let fileName = "current_match_point_history.json"
    
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {}
    
    /// Save a point to local storage
    func savePoint(_ point: Point, gameNumber: Int? = nil) {
        let pointData = PointData(from: point, gameNumber: gameNumber)
        var allPoints = loadAllPoints()
        allPoints.append(pointData)
        saveAllPoints(allPoints)
    }
    
    /// Load all stored points
    func loadAllPoints() -> [PointData] {
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
    
    /// Clear all stored points (called on resetMatch)
    func clearAllPoints() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing point history: \(error)")
        }
    }
    
    /// Remove a point by its unique ID (for undo functionality)
    func removePoint(byID id: String) {
        var allPoints = loadAllPoints()
        allPoints.removeAll { $0.id == id }
        saveAllPoints(allPoints)
    }
    
    /// Remove the last point (for undo functionality - fallback)
    func removeLastPoint() {
        var allPoints = loadAllPoints()
        if !allPoints.isEmpty {
            allPoints.removeLast()
            saveAllPoints(allPoints)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveAllPoints(_ points: [PointData]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(points)
            try data.write(to: fileURL)
        } catch {
            print("Error saving point history: \(error)")
        }
    }
}

