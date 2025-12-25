//
//  Outcome.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Point result classification
enum Outcome: String, Codable, CaseIterable {
    case winner = "winner"
    case unforcedError = "unforced_error"
    case forcedError = "forced_error"
    case opponentWinner = "opponent_winner"
    
    var displayName: String {
        switch self {
        case .winner: return "Winner"
        case .unforcedError: return "Unforced Error"
        case .forcedError: return "Forced Error"
        case .opponentWinner: return "Opponent Winner"
        }
    }
    
    var emoji: String {
        switch self {
        case .winner: return "✅"
        case .unforcedError: return "❌"
        case .forcedError: return "⚠️"
        case .opponentWinner: return "👤"
        }
    }
}


