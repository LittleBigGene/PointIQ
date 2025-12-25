//
//  ServiceType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis serve types with vegetable mnemonic tokens
enum ServiceType: String, Codable, CaseIterable {
    case longFast = "long_fast"
    case shortSoft = "short_soft"
    case spinny = "spinny"
    case dead = "dead"
    
    var displayName: String {
        switch self {
        case .longFast: return "Long + Fast / Penetrating"
        case .shortSoft: return "Short + Soft / Touch"
        case .spinny: return "Spinny / Tricky"
        case .dead: return "Dead / No-spin"
        }
    }
    
    var emoji: String {
        switch self {
        case .longFast: return "🥕" // Carrot - sharp, straight, goes far
        case .shortSoft: return "🫛" // Pea - tiny, subtle, stays close
        case .spinny: return "🍒" // Cherry Tomato - small, round, unpredictable spin
        case .dead: return "🥔" // Potato - heavy, plops straight, minimal movement
        }
    }
    
    var vegetableName: String {
        switch self {
        case .longFast: return "Carrot"
        case .shortSoft: return "Pea"
        case .spinny: return "Cherry Tomato"
        case .dead: return "Potato"
        }
    }
}

