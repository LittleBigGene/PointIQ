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
    case opponentWinner = "opponent_winner"
    case net = "net"
    case edge = "edge"
    case doubleHappiness = "double_happiness"
    
    var displayName: String {
        switch self {
        case .myWinner: return "Cho-le"        
        case .opponentError: return "Lucky"
        case .myError: return "My Error"
        case .opponentWinner: return "Opponent's Point"
        case .net: return "Net"
        case .edge: return "Edge"
        case .doubleHappiness: return "Double Happiness"
        }
    }
    
    var emoji: String {
        switch self {
        case .myWinner: return "💪"
        case .opponentError: return "🍀"
        case .myError: return "⚠️"
        case .opponentWinner: return "😿"
        case .net: return "🕸️"
        case .edge: return "⚡"
        case .doubleHappiness: return "囍"
        }
    }
}


