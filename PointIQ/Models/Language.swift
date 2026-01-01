//
//  Language.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

enum Language: String, CaseIterable {
    case english = "en"
    case japanese = "jp"
    case chinese = "cn"
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
}

