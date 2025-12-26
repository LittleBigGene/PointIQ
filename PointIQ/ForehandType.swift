//
//  ForehandType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis forehand stroke types with animal mnemonic tokens
enum ForehandType: String, Codable, CaseIterable {
    case dragon = "dragon"
    case tiger = "tiger"
    case phoenix = "phoenix"
    case snake = "snake"
    
    var displayName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .phoenix: return "Phoenix"
        case .snake: return "Snake"
        }
    }
    
    var emoji: String {
        switch self {
        case .dragon: return "🐉" // Dragon - powerful, dominant, Ma Long's signature
        case .tiger: return "🐅" // Tiger - aggressive, step around forehand
        case .phoenix: return "🦅" // Phoenix - graceful, slow spinny loop
        case .snake: return "🐍" // Snake - curving, sidespin stroke
        }
    }
    
    var proteinName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .phoenix: return "Phoenix"
        case .snake: return "Snake"
        }
    }
    
    var spinType: String {
        switch self {
        case .dragon: return "Power Drive"
        case .tiger: return "Step Around"
        case .phoenix: return "Slow Spinny Loop"
        case .snake: return "Sidespin"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .dragon: return "Ma Long's forehand power drive — dominant, powerful, signature stroke."
        case .tiger: return "Step around forehand — aggressive, positioning-based attack."
        case .phoenix: return "Slow spinny loop — graceful, controlled, high-spin arc."
        case .snake: return "Sidespin stroke — curving, deceptive, creates unpredictable bounce."
        }
    }
}

