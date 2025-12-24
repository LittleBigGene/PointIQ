//
//  StrokeToken.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Semantic categorization of strokes using voice tokens
enum StrokeToken: String, Codable, CaseIterable {
    case fruit = "fruit"        // Backhand
    case protein = "protein"     // Forehand
    case vegetable = "vegetable" // Serve
    
    var displayName: String {
        switch self {
        case .fruit: return "Backhand"
        case .protein: return "Forehand"
        case .vegetable: return "Serve"
        }
    }
    
    var emoji: String {
        switch self {
        case .fruit: return "🍎"
        case .protein: return "🥩"
        case .vegetable: return "🥬"
        }
    }
}

