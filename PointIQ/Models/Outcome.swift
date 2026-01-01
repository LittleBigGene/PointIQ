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
    
    var displayNameJapanese: String {
        switch self {
        case .myWinner: return "チョレ"
        case .opponentError: return "相手のミス"
        case .myError: return "自分のミス"
        case .iMissed: return "ノータッチ"
        case .unlucky: return "ネット/エッジ"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .myWinner: return "得分好球"
        case .opponentError: return "對手失誤"
        case .myError: return "自己失誤"
        case .iMissed: return "沒碰到球"
        case .unlucky: return "擦網擦邊"
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
    
    func displayName(for language: Language) -> String {
        switch language {
        case .english: return displayName
        case .japanese: return displayNameJapanese
        case .chinese: return displayNameChinese
        }
    }
}


