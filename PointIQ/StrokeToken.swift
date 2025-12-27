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
    case fruit = "fruit"        // Receive
    case animal = "animal"     // Rally
    
    var displayName: String {
        switch self {
        case .vegetable: return "Serve"
        case .fruit: return "Receive"
        case .animal: return "Rally"
        }
    }
    
    var emoji: String {
        switch self {
        case .vegetable: return "🥬"
        case .fruit: return "🍎"
        case .animal: return "🐾"
        }
    }
}


