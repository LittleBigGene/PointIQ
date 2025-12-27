//
//  StrokeType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Unified protocol for all stroke types
protocol StrokeTypeProtocol: Codable, CaseIterable, Hashable {
    var displayName: String { get }
    var emoji: String { get }
}

/// Enum representing any stroke type in a point sequence
enum StrokeType: Codable, Hashable {
    case serve(ServeType)
    case receive(ReceiveType)
    case rally(RallyType)
    
    var displayName: String {
        switch self {
        case .serve(let serve): return serve.displayName
        case .receive(let receive): return receive.displayName
        case .rally(let rally): return rally.displayName
        }
    }
    
    var emoji: String {
        switch self {
        case .serve: return "🥬" // Vegetable emoji for serve
        case .receive(let receive): return receive.emoji
        case .rally(let rally): return rally.emoji
        }
    }
    
    var shortName: String? {
        switch self {
        case .serve(let serve): return serve.shortName
        case .receive, .rally: return nil
        }
    }
}

// MARK: - StrokeType Extensions for ServeType, ReceiveType, RallyType
extension ServeType: StrokeTypeProtocol {
    var emoji: String {
        return ""
    }
}

extension ReceiveType: StrokeTypeProtocol {
    // Already has emoji property
}

extension RallyType: StrokeTypeProtocol {
    // Already has emoji property
}

