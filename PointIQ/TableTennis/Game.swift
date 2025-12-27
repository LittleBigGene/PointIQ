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
    var playerServesFirst: Bool // True if player serves first, false if opponent serves first
    
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        match: Match? = nil,
        gameNumber: Int = 1,
        playerServesFirst: Bool = true
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.match = match
        self.gameNumber = gameNumber
        self.playerServesFirst = playerServesFirst
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
            $0.outcome == .opponentError
        }.count ?? 0
    }
    
    var pointsLost: Int {
        points?.filter { 
            $0.outcome == .iMissed || 
            $0.outcome == .myError || 
            $0.outcome == .unlucky
        }.count ?? 0
    }
    
    // MARK: - Game Rules Logic
    
    var isComplete: Bool {
        Rules.isGameComplete(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var winner: Bool? {
        Rules.gameWinner(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var isDeuce: Bool {
        Rules.isDeuce(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
    
    var statusMessage: String {
        Rules.gameStatus(
            playerPoints: pointsWon,
            opponentPoints: pointsLost
        )
    }
}

