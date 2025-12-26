//
//  BackhandType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis backhand stroke types with fruit mnemonic tokens
enum BackhandType: String, Codable, CaseIterable {
    case chopBlock = "chop_block"
    case flick = "flick"
    case reverseFlick = "reverse_flick"
    
    var displayName: String {
        switch self {        
        case .chopBlock: return "Chop-Block"
        case .flick: return "Flick"
        case .reverseFlick: return "Reverse Flick"        
        }
    }
    
    var emoji: String {
        switch self {
        case .chopBlock: return "🍉" // Watermelon - big and defensive yet fast
        case .flick: return "🍌" // Banana - curved, attacking short stroke
        case .reverseFlick: return "🍓" // Strawberry - deceptive, sweet twist
        }
    }
    
    var fruitName: String {
        switch self {       
        case .chopBlock: return "Watermelon"
        case .flick: return "Banana"
        case .reverseFlick: return "Strawberry"
        }
    }
    
    var spinType: String {
        switch self {
        case .chopBlock: return "Underspin / sidespin / absorb"
        case .flick: return "Topspin / sidespin"
        case .reverseFlick: return "Topspin / sidespin"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .chopBlock: return "Combines heavy underspin with defensive blocking action."
        case .flick: return "Quick, attacking stroke with spin variation."
        case .reverseFlick: return "Deceptive stroke with reverse spin variation."
        }
    }
}

