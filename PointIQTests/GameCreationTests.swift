//
//  GameCreationTests.swift
//  PointIQTests
//
//  Created by Jin Cai on 12/24/25.
//

import XCTest
import SwiftData
@testable import PointIQ

final class GameCreationTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    private func createGame(
        gameNumber: Int,
        playerServesFirst: Bool,
        playerPoints: Int,
        opponentPoints: Int
    ) -> Game {
        let game = Game(gameNumber: gameNumber, playerServesFirst: playerServesFirst)
        var points: [Point] = []
        
        // Add player wins
        for _ in 0..<playerPoints {
            points.append(Point(outcome: .myWinner, game: game))
        }
        
        // Add opponent wins (player losses)
        for _ in 0..<opponentPoints {
            points.append(Point(outcome: .iMissed, game: game))
        }
        
        game.points = points
        return game
    }
    
    // MARK: - Game Side Swapping Tests
    
    func testGame1_PlayerServesFirst() {
        let game1 = Game(gameNumber: 1, playerServesFirst: true)
        XCTAssertTrue(game1.playerServesFirst, "Game 1 should have player serve first")
        XCTAssertEqual(game1.gameNumber, 1)
    }
    
    func testGame2_AlternatesFromGame1() {
        let game1 = Game(gameNumber: 1, playerServesFirst: true)
        let playerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game1)
        let game2 = Game(gameNumber: 2, playerServesFirst: playerServesFirst)
        
        XCTAssertFalse(game2.playerServesFirst, "Game 2 should alternate - opponent serves first")
        XCTAssertEqual(game2.gameNumber, 2)
    }
    
    func testGame3_AlternatesFromGame2() {
        let game1 = Game(gameNumber: 1, playerServesFirst: true)
        let game2PlayerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game1)
        let game2 = Game(gameNumber: 2, playerServesFirst: game2PlayerServesFirst)
        
        let game3PlayerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game2)
        let game3 = Game(gameNumber: 3, playerServesFirst: game3PlayerServesFirst)
        
        XCTAssertTrue(game3.playerServesFirst, "Game 3 should alternate back - player serves first")
        XCTAssertEqual(game3.gameNumber, 3)
    }
    
    func testGame4_AlternatesFromGame3() {
        let game1 = Game(gameNumber: 1, playerServesFirst: true)
        let game2PlayerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game1)
        let game2 = Game(gameNumber: 2, playerServesFirst: game2PlayerServesFirst)
        let game3PlayerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game2)
        let game3 = Game(gameNumber: 3, playerServesFirst: game3PlayerServesFirst)
        
        let game4PlayerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: game3)
        let game4 = Game(gameNumber: 4, playerServesFirst: game4PlayerServesFirst)
        
        XCTAssertFalse(game4.playerServesFirst, "Game 4 should alternate - opponent serves first")
        XCTAssertEqual(game4.gameNumber, 4)
    }
    
    // MARK: - Game Scoring Tests
    
    func testGamePointsWon() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 5, opponentPoints: 3)
        XCTAssertEqual(game.pointsWon, 5, "Player should have 5 points won")
        XCTAssertEqual(game.pointsLost, 3, "Opponent should have 3 points (player lost 3)")
    }
    
    func testGamePointsWon_WithOpponentErrors() {
        let game = Game(gameNumber: 1, playerServesFirst: true)
        var points: [Point] = []
        
        // Player wins (myWinner)
        points.append(Point(outcome: .myWinner, game: game))
        // Player wins (opponentError)
        points.append(Point(outcome: .opponentError, game: game))
        // Opponent wins (iMissed)
        points.append(Point(outcome: .iMissed, game: game))
        
        game.points = points
        
        XCTAssertEqual(game.pointsWon, 2, "Player should have 2 points won (myWinner + opponentError)")
        XCTAssertEqual(game.pointsLost, 1, "Player should have 1 point lost (iMissed)")
    }
    
    func testGamePointsLost_WithAllLossTypes() {
        let game = Game(gameNumber: 1, playerServesFirst: true)
        var points: [Point] = []
        
        points.append(Point(outcome: .iMissed, game: game))
        points.append(Point(outcome: .myError, game: game))
        points.append(Point(outcome: .unlucky, game: game))
        
        game.points = points
        
        XCTAssertEqual(game.pointsLost, 3, "Player should have 3 points lost")
        XCTAssertEqual(game.pointsWon, 0, "Player should have 0 points won")
    }
    
    // MARK: - Game Completion Tests
    
    func testGameComplete_11to9() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 11, opponentPoints: 9)
        XCTAssertTrue(game.isComplete, "Game should be complete at 11-9")
        XCTAssertEqual(game.winner, true, "Player should win")
    }
    
    func testGameComplete_9to11() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 9, opponentPoints: 11)
        XCTAssertTrue(game.isComplete, "Game should be complete at 9-11")
        XCTAssertEqual(game.winner, false, "Opponent should win")
    }
    
    func testGameNotComplete_10to10() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 10, opponentPoints: 10)
        XCTAssertFalse(game.isComplete, "Game should not be complete at 10-10 (deuce)")
        XCTAssertTrue(game.isDeuce, "Game should be at deuce")
        XCTAssertNil(game.winner, "No winner at deuce")
    }
    
    func testGameNotComplete_11to10() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 11, opponentPoints: 10)
        XCTAssertFalse(game.isComplete, "Game should not be complete at 11-10 (need 2 point lead)")
        XCTAssertFalse(game.isDeuce, "Game should not be at deuce")
        XCTAssertNil(game.winner, "No winner yet")
    }
    
    func testGameComplete_12to10() {
        let game = createGame(gameNumber: 1, playerServesFirst: true, playerPoints: 12, opponentPoints: 10)
        XCTAssertTrue(game.isComplete, "Game should be complete at 12-10 (2 point lead)")
        XCTAssertEqual(game.winner, true, "Player should win")
    }
}

