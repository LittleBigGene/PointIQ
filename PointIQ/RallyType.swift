//
//  RallyType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis rally stroke types with animal mnemonic tokens
enum RallyType: String, Codable, CaseIterable {
    case dragon = "dragon"
    case tiger = "tiger"
    case crane = "crane"
    case snake = "snake"
    case panda = "panda"
    
    var displayName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .crane: return "Crane"
        case .snake: return "Snake"
        case .panda: return "Panda"
        }
    }
    
    var emoji: String {
        switch self {
        case .dragon: return "🐉" // Dragon - powerful, dominant, Ma Long's signature
        case .tiger: return "🐅" // Tiger - aggressive, step around forehand
        case .crane: return "🦅" // Crane - graceful, slow spinny loop
        case .snake: return "🐍" // Snake - curving, sidespin stroke
        case .panda: return "🐼" // Panda - powerful, Fan Zhendong's backhand power drive
        }
    }
    
    var animalName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .crane: return "Crane"
        case .snake: return "Snake"
        case .panda: return "Panda"
        }
    }
    
    var spinType: String {
        switch self {
        case .dragon: return "Power Drive"
        case .tiger: return "Step Around"
        case .crane: return "Slow Spinny Loop"
        case .snake: return "Sidespin"
        case .panda: return "Power Drive"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .dragon: return "Ma Long's forehand power drive — dominant, powerful, signature stroke."
        case .tiger: return "Step around forehand — aggressive, positioning-based attack."
        case .crane: return "High spinny loop — graceful, controlled, high-spin arc."
        case .snake: return "Sidespin stroke — curving, deceptive, creates unpredictable bounce."
        case .panda: return "Fan Zhendong's backhand power drive — powerful, explosive, signature stroke."
        }
    }
}

