//
//  StrokeToken.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Semantic categorization of strokes using voice tokens
enum StrokeToken: String, Codable, CaseIterable {
    case vegetable = "vegetable" // Serve
    case fruit = "fruit"        // Backhand
    case protein = "protein"     // Forehand
    
    var displayName: String {
        switch self {
        case .vegetable: return "Serve"
        case .fruit: return "Backhand"
        case .protein: return "Forehand"
        }
    }
    
    var emoji: String {
        switch self {
        case .vegetable: return "🥬"
        case .fruit: return "🍎"
        case .protein: return "🥩"
        }
    }
}


