//
//  Match.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import SwiftData

@Model
final class Match {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \Point.match) var points: [Point]?
    var opponentName: String?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        opponentName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.opponentName = opponentName
        self.notes = notes
    }
    
    var isActive: Bool {
        endDate == nil
    }
    
    var pointCount: Int {
        points?.count ?? 0
    }
}

