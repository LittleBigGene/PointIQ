//
//  ServeType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis serve types
enum ServeType: String, Codable, CaseIterable {
    case SS = "SS" // Spinny & Short
    case DS = "DS" // Dead & Short
    case DL = "DL" // Dead & Long
    case SL = "SL" // Spinny & Long
    case FL = "FL" // Fast & Long
    
    var displayName: String {
        switch self {
        case .SS: return "Spinny & Short"
        case .DS: return "Dead & Short"
        case .DL: return "Dead & Long"
        case .SL: return "Spinny & Long"
        case .FL: return "Fast & Long"
        }
    }
    
    var shortName: String {
        switch self {
        case .SS: return "SS"
        case .DS: return "DS"
        case .DL: return "DL"
        case .SL: return "SL"
        case .FL: return "FL"
        }
    }
}

