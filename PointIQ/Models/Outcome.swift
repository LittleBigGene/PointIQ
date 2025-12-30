//
//  Outcome.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import SwiftUI

/// Point result classification
enum Outcome: String, Codable, CaseIterable {
    case myWinner = "my_winner"    
    case opponentError = "opponent_error"
    case myError = "my_error"
    case iMissed = "i_missed"
    case unlucky = "unlucky"
    
    var displayName: String {
        switch self {
        case .myWinner: return "Cho-le"        
        case .opponentError: return "Opp Err"
        case .myError: return "Error"
        case .iMissed: return "Missed"
        case .unlucky: return "Net/Edge"
        }
    }
    
    var emoji: String {
        switch self {
        case .myWinner: return "💪"
        case .opponentError: return "🍀"
        case .myError: return "⚠️"
        case .iMissed: return "😿"
        case .unlucky: return "🙃"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .unlucky, .myError, .iMissed:
            // Red-ish background: point given to opponent
            return Color.red.opacity(0.15)
        case .opponentError, .myWinner:
            // Blue-ish background: point won by player
            return Color.blue.opacity(0.15)
        }
    }
}


