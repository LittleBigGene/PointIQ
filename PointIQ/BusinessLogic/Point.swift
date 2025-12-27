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
    var strokeTokens: [StrokeToken]
    var outcome: Outcome
    var match: Match?
    var game: Game?
    var serveType: String?
    
    init(
        timestamp: Date = Date(),
        strokeTokens: [StrokeToken] = [],
        outcome: Outcome,
        match: Match? = nil,
        game: Game? = nil,
        serveType: String? = nil
    ) {
        self.timestamp = timestamp
        self.strokeTokens = strokeTokens
        self.outcome = outcome
        self.match = match
        self.game = game
        self.serveType = serveType
    }
    
    /// JSON-like representation for analytics
    var jsonRepresentation: [String: Any] {
        [
            "timestamp": timestamp.timeIntervalSince1970,
            "strokes": strokeTokens.map { $0.rawValue },
            "outcome": outcome.rawValue
        ]
    }
    
    /// Unique identifier for SwiftUI ForEach
    var uniqueID: String {
        "\(timestamp.timeIntervalSince1970)-\(outcome.rawValue)-\(strokeTokens.map { $0.rawValue }.joined(separator: ","))"
    }
}


