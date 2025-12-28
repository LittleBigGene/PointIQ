//
//  Match.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import SwiftData

@Model
final class Match: Identifiable {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \Point.match) var points: [Point]?
    @Relationship(deleteRule: .cascade, inverse: \Game.match) var games: [Game]?
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
    
    var pointsWon: Int {
        points?.filter { $0.outcome == .myWinner }.count ?? 0
    }
    
    var pointsLost: Int {
        points?.filter { $0.outcome == .iMissed }.count ?? 0
    }
    
    var currentGame: Game? {
        games?.first { $0.isActive }
    }
    
    var gamesWon: Int {
        games?.filter { $0.winner == true }.count ?? 0
    }
    
    var gamesLost: Int {
        games?.filter { $0.winner == false }.count ?? 0
    }
    
    // MARK: - Match Rules Logic
    
    var isComplete: Bool {
        Rules.isMatchComplete(
            playerGamesWon: gamesWon,
            opponentGamesWon: gamesLost
        )
    }
    
    var winner: Bool? {
        Rules.matchWinner(
            playerGamesWon: gamesWon,
            opponentGamesWon: gamesLost
        )
    }
}


