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
    
    // MARK: - Serve Rotation Logic
    
    /// Determines who is serving for the NEXT point
    /// - Before either player reaches 11: serve alternates every 2 points
    /// - After either player reaches 11: serve alternates every 1 point
    var isPlayerServingNext: Bool {
        let playerPoints = pointsWon
        let opponentPoints = pointsLost
        
        // Check if either player has reached 11 points
        let hasReached11 = playerPoints >= 11 || opponentPoints >= 11
        
        if hasReached11 {
            // After either player reaches 11, serve alternates every point
            // Use pointCount to determine who serves next (alternates every point)
            if playerServesFirst {
                return pointCount % 2 == 0
            } else {
                return pointCount % 2 == 1
            }
        } else {
            // Before 11, serve alternates every 2 points
            // Block 0: points 1-2, Block 1: points 3-4, Block 2: points 5-6, etc.
            let nextPointBlock = pointCount / 2
            if playerServesFirst {
                return nextPointBlock % 2 == 0
            } else {
                return nextPointBlock % 2 == 1
            }
        }
    }
}

