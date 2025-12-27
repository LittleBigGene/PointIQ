//
//  Outcome.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

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
        case .opponentError: return "Opponent's Error"
        case .myError: return "My Error"
        case .iMissed: return "I Missed"
        case .unlucky: return "Net and/or edge"
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
}


