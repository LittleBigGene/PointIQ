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
    @Relationship(deleteRule: .cascade, inverse: \Game.match) var games: [Game]?
    var opponentName: String?
    var notes: String?
    var matchFormat: String // Store as string: "bestOf5", "bestOf7", etc.
    
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        opponentName: String? = nil,
        notes: String? = nil,
        matchFormat: String = "bestOf5"
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.opponentName = opponentName
        self.notes = notes
        self.matchFormat = matchFormat
    }
    
    var isActive: Bool {
        endDate == nil
    }
    
    var pointCount: Int {
        points?.count ?? 0
    }
    
    var pointsWon: Int {
        points?.filter { $0.outcome == .winner }.count ?? 0
    }
    
    var pointsLost: Int {
        points?.filter { $0.outcome == .opponentWinner }.count ?? 0
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
    
    var format: TableTennisRules.MatchFormat {
        switch matchFormat {
        case "bestOf3": return .bestOf3
        case "bestOf7": return .bestOf7
        case "bestOf5": return .bestOf5
        default: return .bestOf5
        }
    }
    
    var isComplete: Bool {
        TableTennisRules.isMatchComplete(
            playerGamesWon: gamesWon,
            opponentGamesWon: gamesLost,
            format: format
        )
    }
    
    var winner: Bool? {
        TableTennisRules.matchWinner(
            playerGamesWon: gamesWon,
            opponentGamesWon: gamesLost,
            format: format
        )
    }
}


