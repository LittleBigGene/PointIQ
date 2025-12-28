//
//  Rules.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table Tennis Rules and Business Logic
struct Rules {
    
    // MARK: - Game Rules
    
    /// Standard points required to win a game
    static let pointsToWinGame = 11
    
    /// Minimum lead required to win (must win by 2 points)
    static let minimumLeadToWin = 2
    
    /// Maximum points in a game (if deuce continues)
    static let maximumGamePoints = 30 // Safety limit
    
    // MARK: - Serve Rules
    
    /// Serve alternates every 2 points
    static let serveRotationPoints = 2
    
    /// At deuce (10-10), serve alternates every point
    static let deuceThreshold = 10
    
    // MARK: - Game Completion Logic
    
    /// Determines if a game is complete based on score
    /// - Parameters:
    ///   - playerPoints: Points scored by the player
    ///   - opponentPoints: Points scored by the opponent
    /// - Returns: True if the game is complete
    static func isGameComplete(playerPoints: Int, opponentPoints: Int) -> Bool {
        // Check if either player has reached the winning threshold
        let maxScore = max(playerPoints, opponentPoints)
        let minScore = min(playerPoints, opponentPoints)
        
        // Game is complete if:
        // 1. A player has reached 11+ points AND
        // 2. They have a lead of at least 2 points
        if maxScore >= pointsToWinGame {
            return (maxScore - minScore) >= minimumLeadToWin
        }
        
        // Safety: prevent infinite games
        if maxScore >= maximumGamePoints {
            return true
        }
        
        return false
    }
    
    /// Determines who won the game
    /// - Parameters:
    ///   - playerPoints: Points scored by the player
    ///   - opponentPoints: Points scored by the opponent
    /// - Returns: True if player won, false if opponent won, nil if game not complete
    static func gameWinner(playerPoints: Int, opponentPoints: Int) -> Bool? {
        guard isGameComplete(playerPoints: playerPoints, opponentPoints: opponentPoints) else {
            return nil
        }
        return playerPoints > opponentPoints
    }
    
    // MARK: - Match Completion Logic
    
    /// Determines if a match is complete based on games won
    /// Note: Matches are never automatically complete - users can reset matches at any time
    /// - Parameters:
    ///   - playerGamesWon: Number of games won by player
    ///   - opponentGamesWon: Number of games won by opponent
    /// - Returns: Always returns false (matches never auto-complete)
    static func isMatchComplete(
        playerGamesWon: Int,
        opponentGamesWon: Int
    ) -> Bool {
        // Matches never auto-complete - users can reset whenever they want
        return false
    }
    
    /// Determines who won the match
    /// Note: Matches are never automatically complete - users can reset matches at any time
    /// - Parameters:
    ///   - playerGamesWon: Number of games won by player
    ///   - opponentGamesWon: Number of games won by opponent
    /// - Returns: Always returns nil (matches never auto-complete)
    static func matchWinner(
        playerGamesWon: Int,
        opponentGamesWon: Int
    ) -> Bool? {
        // Matches never auto-complete - users can reset whenever they want
        return nil
    }
    
    // MARK: - Serve Rotation Logic
    
    /// Determines if serve should rotate based on total points played
    /// - Parameter totalPoints: Total points played in the current game
    /// - Parameter isDeuce: Whether the game is at deuce (10-10)
    /// - Returns: True if serve should rotate
    static func shouldRotateServe(totalPoints: Int, isDeuce: Bool) -> Bool {
        if isDeuce {
            // At deuce, rotate every point
            return totalPoints % 2 == 0
        } else {
            // Normal play, rotate every 2 points
            return totalPoints % serveRotationPoints == 0
        }
    }
    
    /// Checks if game is at deuce
    /// - Parameters:
    ///   - playerPoints: Points scored by the player
    ///   - opponentPoints: Points scored by the opponent
    /// - Returns: True if at deuce (10-10 or higher tie)
    static func isDeuce(playerPoints: Int, opponentPoints: Int) -> Bool {
        return playerPoints >= deuceThreshold &&
               opponentPoints >= deuceThreshold &&
               playerPoints == opponentPoints
    }
    
    // MARK: - Score Display Helpers
    
    /// Formats the game score for display
    /// - Parameters:
    ///   - playerPoints: Points scored by the player
    ///   - opponentPoints: Points scored by the opponent
    /// - Returns: Formatted score string
    static func formatGameScore(playerPoints: Int, opponentPoints: Int) -> String {
        if isDeuce(playerPoints: playerPoints, opponentPoints: opponentPoints) {
            return "Deuce"
        }
        return "\(playerPoints) - \(opponentPoints)"
    }
    
    /// Gets the current game status message
    /// - Parameters:
    ///   - playerPoints: Points scored by the player
    ///   - opponentPoints: Points scored by the opponent
    /// - Returns: Status message
    static func gameStatus(playerPoints: Int, opponentPoints: Int) -> String {
        if isGameComplete(playerPoints: playerPoints, opponentPoints: opponentPoints) {
            if let winner = gameWinner(playerPoints: playerPoints, opponentPoints: opponentPoints) {
                return winner ? "Game Won" : "Game Lost"
            }
        }
        
        if isDeuce(playerPoints: playerPoints, opponentPoints: opponentPoints) {
            return "Deuce"
        }
        
        let difference = abs(playerPoints - opponentPoints)
        if difference >= 2 && max(playerPoints, opponentPoints) >= pointsToWinGame - 1 {
            return "Game Point"
        }
        
        return "In Progress"
    }
}

