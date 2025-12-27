//
//  Game.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \Point.game) var points: [Point]?
    var match: Match?
    var gameNumber: Int
    
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        match: Match? = nil,
        gameNumber: Int = 1
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.match = match
        self.gameNumber = gameNumber
    }
    
    var isActive: Bool {
        endDate == nil
    }
    
    var pointCount: Int {
        points?.count ?? 0
    }
    
    var pointsWon: Int {
        points?.filter { 
            $0.outcome == .myWinner || 
            $0.outcome == .opponentError || 
            $0.outcome == .unlucky
        }.count ?? 0
    }
    
    var pointsLost: Int {
        points?.filter { $0.outcome == .iMissed }.count ?? 0
    }
    
    // MARK: - Game Rules Logic
    
    var isComplete: Bool {
        TableTennisRules.isGameComplete(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var winner: Bool? {
        TableTennisRules.gameWinner(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var isDeuce: Bool {
        TableTennisRules.isDeuce(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var statusMessage: String {
        TableTennisRules.gameStatus(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
}

