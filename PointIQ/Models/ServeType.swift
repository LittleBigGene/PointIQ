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
    case SL = "SL" // Spinny & Long
    case DS = "DS" // Dead & Short
    case DL = "DL" // Dead & Long
    case HU = "HU" // Heavy Underspin
    case FL = "FL" // Fast & Long
    
    var displayName: String {
        switch self {
        case .SS: return "Spinny & Short"
        case .SL: return "Spinny & Long"
        case .DS: return "Dead & Short"
        case .DL: return "Dead & Long"
        case .HU: return "Heavy Underspin"
        case .FL: return "Fast & Long"
        }
    }
    
    var displayNameJapanese: String {
        switch self {
        case .SS: return "回転・ショート"
        case .SL: return "回転・ロング"
        case .DS: return "無回転・ショート"
        case .DL: return "無回転・ロング"
        case .HU: return "強い下回転"
        case .FL: return "速い・ロング"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .SS: return "转的短球"
        case .SL: return "转的长球"
        case .DS: return "不转短球"
        case .DL: return "不转长球"
        case .HU: return "强下旋球"
        case .FL: return "急快长球"
        }
    }
    
    var shortName: String {
        switch self {
        case .SS: return "SS"
        case .SL: return "SL"
        case .DS: return "DS"
        case .DL: return "DL"
        case .HU: return "HU"
        case .FL: return "FL"
        }
    }
    
    func displayName(for language: Language) -> String {
        switch language {
        case .english: return displayName
        case .japanese: return displayNameJapanese
        case .chinese: return displayNameChinese
        }
    }
}

