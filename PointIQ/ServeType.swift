//
//  ServeType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis serve types
enum ServeType: String, Codable, CaseIterable {
    case FL = "FL" // Fast & Long
    case DL = "DL" // Dead & Long
    case SL = "SL" // Spinny & Long
    case DS = "DS" // Dead & Short
    case SS = "SS" // Spinny & Short
    
    var displayName: String {
        switch self {
        case .FL: return "Fast & Long"
        case .DL: return "Dead & Long"
        case .SL: return "Spinny & Long"
        case .DS: return "Dead & Short"
        case .SS: return "Spinny & Short"
        }
    }
}

