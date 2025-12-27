//
//  ReceiveType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis receive stroke types with fruit mnemonic tokens
enum ReceiveType: String, Codable, CaseIterable {
    case push = "push"
    case forehandFlick = "forehand_flick"
    case backhandFlick = "backhand_flick"
    case reverseFlick = "reverse_flick"
    case chopBlock = "chop_block"
    
    var displayName: String {
        switch self {        
        case .push: return "Push"
        case .forehandFlick: return "Forehand Flick"
        case .backhandFlick: return "Backhand Flick"
        case .reverseFlick: return "Reverse Flick"
        case .chopBlock: return "Chop-Block"
        }
    }
    
    var emoji: String {
        switch self {
        case .push: return "🍎" // Apple - basic, controlled defensive stroke
        case .forehandFlick: return "🥝" // Kiwi - forehand flick variation
        case .backhandFlick: return "🍌" // Banana - curved, attacking short stroke
        case .reverseFlick: return "🍓" // Strawberry - deceptive, sweet twist
        case .chopBlock: return "🍉" // Watermelon - big and defensive yet fast
        }
    }
    
    var fruitName: String {
        switch self {       
        case .push: return "Apple"
        case .forehandFlick: return "Kiwi"
        case .backhandFlick: return "Banana"
        case .reverseFlick: return "Strawberry"
        case .chopBlock: return "Watermelon"
        }
    }
    
    var spinType: String {
        switch self {
        case .push: return "Underspin"
        case .forehandFlick: return "Topspin / Sidespin"
        case .backhandFlick: return "Topspin / Sidespin"
        case .reverseFlick: return "Topspin / Sidespin"
        case .chopBlock: return "Underspin / Sidespin / Absorb"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .push: return "Controlled defensive stroke with underspin — fundamental receive technique."
        case .forehandFlick: return "Forehand variation of the flick — attacking stroke with topspin and sidespin."
        case .backhandFlick: return "Backhand variation of the flick — attacking stroke with topspin and sidespin."
        case .reverseFlick: return "Deceptive stroke with reverse spin variation."
        case .chopBlock: return "Combines heavy underspin with defensive blocking action."
        }
    }
}

