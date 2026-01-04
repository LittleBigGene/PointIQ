//
//  Point.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import SwiftData

@Model
final class Point {
    var timestamp: Date
    var strokeTokens: [String] // Store actual stroke types: serve types (SS, SL, DS, etc.), receive types, rally types
    var outcome: Outcome
    var match: Match?
    var game: Game?
    var serveType: String?
    var receiveType: String? // Store specific receive type
    var rallyTypes: [String] // Store specific rally types
    
    init(
        timestamp: Date = Date(),
        strokeTokens: [String] = [],
        outcome: Outcome,
        match: Match? = nil,
        game: Game? = nil,
        serveType: String? = nil,
        receiveType: String? = nil,
        rallyTypes: [String] = []
    ) {
        self.timestamp = timestamp
        self.strokeTokens = strokeTokens
        self.outcome = outcome
        self.match = match
        self.game = game
        self.serveType = serveType
        self.receiveType = receiveType
        self.rallyTypes = rallyTypes
    }
    
    /// JSON-like representation for analytics
    var jsonRepresentation: [String: Any] {
        [
            "timestamp": timestamp.timeIntervalSince1970,
            "strokes": strokeTokens,
            "outcome": outcome.rawValue
        ]
    }
    
    /// Unique identifier for SwiftUI ForEach
    var uniqueID: String {
        "\(timestamp.timeIntervalSince1970)-\(outcome.rawValue)-\(strokeTokens.joined(separator: ","))"
    }
}


