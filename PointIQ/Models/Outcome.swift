//
//  Outcome.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Point result classification
enum Outcome: String, Codable, CaseIterable {
    case unlucky = "unlucky"
    case myError = "my_error"
    case iMissed = "i_missed"
    case opponentError = "opponent_error"
    case myWinner = "my_winner"    
    
    var displayName: String {
        switch self {
        case .unlucky: return "Net/Edge"
        case .myError: return "Error"
        case .iMissed: return "Missed"
        case .opponentError: return "Opp Err"
        case .myWinner: return "Cho-le"        
        }
    }
    
    var emoji: String {
        switch self {
        case .unlucky: return "🙃"
        case .myError: return "⚠️"
        case .iMissed: return "😿"
        case .opponentError: return "🍀"
        case .myWinner: return "💪"
        }
    }
}


