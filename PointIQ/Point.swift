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
    
    init(
        timestamp: Date = Date(),
        strokeTokens: [StrokeToken] = [],
        outcome: Outcome,
        match: Match? = nil
    ) {
        self.timestamp = timestamp
        self.strokeTokens = strokeTokens
        self.outcome = outcome
        self.match = match
    }
    
    /// JSON-like representation for analytics
    var jsonRepresentation: [String: Any] {
        [
            "timestamp": timestamp.timeIntervalSince1970,
            "strokes": strokeTokens.map { $0.rawValue },
            "outcome": outcome.rawValue
        ]
    }
}


