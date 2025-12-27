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
    case tortoise = "tortoise"
    
    var displayName: String {
        switch self {
        case .tortoise: return "Tortoise"
        case .crane: return "Crane"
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .panda: return "Panda"
        case .snake: return "Snake"
        }
    }
    
    var emoji: String {
        switch self {
        case .tortoise: return "🐢" // Tortoise - calm, stable redirection of opponent’s power with precise control
        case .crane: return "🦅" // Crane - graceful, slow spinny loop
        case .dragon: return "🐉" // Dragon - powerful, dominant, Ma Long's signature
        case .tiger: return "🐅" // Tiger - aggressive, step around forehand
        case .panda: return "🐼" // Panda - powerful, Fan Zhendong's backhand power drive
        case .snake: return "🐍" // Snake - curving, sidespin stroke
        }
    }
    
    var animalName: String {
        switch self {
        case .tortoise: return "Tortoise"
        case .crane: return "Crane"
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .panda: return "Panda"
        case .snake: return "Snake"
        }
    }
    
    var spinType: String {
        switch self {
        case .tortoise: return "Block / Control"
        case .crane: return "Slow Spinny Loop"
        case .dragon: return "Power Drive"
        case .tiger: return "Step Around"
        case .panda: return "Power Drive"
        case .snake: return "Sidespin"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .tortoise: return "Block — calm, stable redirection of opponent’s power with precise control."
        case .crane: return "Slow high-arc spinny loop — graceful, controlled, high-spin arc."
        case .dragon: return "Ma Long's forehand power drive — dominant, powerful, signature stroke."
        case .tiger: return "Step around forehand — aggressive, positioning-based attack."
        case .panda: return "Fan Zhendong's backhand power drive — powerful, explosive, signature stroke."
        case .snake: return "Sidespin stroke — curving, deceptive, creates unpredictable bounce."
        }
    }
}

