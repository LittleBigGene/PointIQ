//
//  GameSideSwap.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Utility for determining player side swap logic
struct GameSideSwap {
    /// Determines if players should be swapped based on game number and manual override
    /// - Parameters:
    ///   - gameNumber: The current game number
    ///   - manualSwapOverride: Manual override toggle from user
    /// - Returns: True if players should be swapped (opponent on left, player on right)
    static func shouldSwapPlayers(gameNumber: Int, manualSwapOverride: Bool) -> Bool {
        // Automatic swap: Even game numbers = swapped
        let automaticSwap = gameNumber % 2 == 0
        // Combine with manual override (XOR: if manual override is true, flip the automatic swap)
        return automaticSwap != manualSwapOverride
    }
    
    /// Determines who serves first for a new game based on the previous game
    /// - Parameter previousGame: The previous game in the match
    /// - Returns: True if player serves first, false if opponent serves first
    static func determinePlayerServesFirst(previousGame: Game?) -> Bool {
        if let previousGame = previousGame {
            // Alternate from previous game
            return !previousGame.playerServesFirst
        } else {
            // First game: player serves first
            return true
        }
    }
    
    /// Determines who serves first for a game number when previous game may not exist
    /// - Parameters:
    ///   - gameNumber: The game number
    ///   - previousGame: Optional previous game
    /// - Returns: True if player serves first, false if opponent serves first
    static func determinePlayerServesFirst(gameNumber: Int, previousGame: Game?) -> Bool {
        if gameNumber == 1 {
            // First game: player serves first
            return true
        } else if let previousGame = previousGame {
            // Alternate from previous game
            return !previousGame.playerServesFirst
        } else {
            // Fallback: alternate based on game number (odd = player serves first)
            return (gameNumber % 2 == 1)
        }
    }
}


