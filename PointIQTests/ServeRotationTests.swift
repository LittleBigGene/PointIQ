//
//  ServeRotationTests.swift
//  PointIQTests
//
//  Created by Jin Cai on 12/24/25.
//

import XCTest
import SwiftData
@testable import PointIQ

final class ServeRotationTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    /// Creates a game with the specified points
    private func createGame(
        playerServesFirst: Bool,
        playerPoints: Int,
        opponentPoints: Int
    ) -> Game {
        let game = Game(playerServesFirst: playerServesFirst)
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
    
    // MARK: - Tests: Before 11 Points (Alternates Every 2 Points)
    
    func testServeRotation_Before11_PlayerServesFirst_0Points() {
        let game = createGame(playerServesFirst: true, playerPoints: 0, opponentPoints: 0)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve first point")
    }
    
    func testServeRotation_Before11_PlayerServesFirst_1Point() {
        let game = createGame(playerServesFirst: true, playerPoints: 1, opponentPoints: 0)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve second point (points 1-2 are player serves)")
    }
    
    func testServeRotation_Before11_PlayerServesFirst_2Points() {
        let game = createGame(playerServesFirst: true, playerPoints: 2, opponentPoints: 0)
        XCTAssertFalse(game.isPlayerServingNext, "Opponent should serve third point (points 3-4 are opponent serves)")
    }
    
    func testServeRotation_Before11_PlayerServesFirst_3Points() {
        let game = createGame(playerServesFirst: true, playerPoints: 2, opponentPoints: 1)
        XCTAssertFalse(game.isPlayerServingNext, "Opponent should serve fourth point (points 3-4 are opponent serves)")
    }
    
    func testServeRotation_Before11_PlayerServesFirst_4Points() {
        let game = createGame(playerServesFirst: true, playerPoints: 2, opponentPoints: 2)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve fifth point (points 5-6 are player serves)")
    }
    
    func testServeRotation_Before11_PlayerServesFirst_10Points() {
        let game = createGame(playerServesFirst: true, playerPoints: 5, opponentPoints: 5)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve 11th point (points 9-10 are player serves)")
    }
    
    func testServeRotation_Before11_OpponentServesFirst_0Points() {
        let game = createGame(playerServesFirst: false, playerPoints: 0, opponentPoints: 0)
        XCTAssertFalse(game.isPlayerServingNext, "Opponent should serve first point")
    }
    
    func testServeRotation_Before11_OpponentServesFirst_1Point() {
        let game = createGame(playerServesFirst: false, playerPoints: 0, opponentPoints: 1)
        XCTAssertFalse(game.isPlayerServingNext, "Opponent should serve second point (points 1-2 are opponent serves)")
    }
    
    func testServeRotation_Before11_OpponentServesFirst_2Points() {
        let game = createGame(playerServesFirst: false, playerPoints: 1, opponentPoints: 1)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve third point (points 3-4 are player serves)")
    }
    
    func testServeRotation_Before11_OpponentServesFirst_3Points() {
        let game = createGame(playerServesFirst: false, playerPoints: 1, opponentPoints: 2)
        XCTAssertTrue(game.isPlayerServingNext, "Player should serve fourth point (points 3-4 are player serves)")
    }
    
    func testServeRotation_Before11_OpponentServesFirst_4Points() {
        let game = createGame(playerServesFirst: false, playerPoints: 2, opponentPoints: 2)
        XCTAssertFalse(game.isPlayerServingNext, "Opponent should serve fifth point (points 5-6 are opponent serves)")
    }
    
    // MARK: - Tests: After 11 Points (Alternates Every Point)
    
    func testServeRotation_After11_PlayerReaches11_PlayerServesFirst() {
        // Player reaches 11, opponent has 0
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 0)
        // At 11 points total, if player served first and pointCount is even, player serves
        XCTAssertTrue(game.isPlayerServingNext, "After player reaches 11, serve alternates every point")
    }
    
    func testServeRotation_After11_PlayerReaches11_PlayerServesFirst_12Points() {
        // Player has 11, opponent has 1 (12 total points)
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 1)
        // At 12 points (even), if player served first, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "After 11, serve alternates every point - opponent should serve")
    }
    
    func testServeRotation_After11_PlayerReaches11_PlayerServesFirst_13Points() {
        // Player has 11, opponent has 2 (13 total points)
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 2)
        // At 13 points (odd), if player served first, player serves
        XCTAssertTrue(game.isPlayerServingNext, "After 11, serve alternates every point - player should serve")
    }
    
    func testServeRotation_After11_OpponentReaches11_PlayerServesFirst() {
        // Opponent reaches 11, player has 0
        let game = createGame(playerServesFirst: true, playerPoints: 0, opponentPoints: 11)
        // At 11 points total, if player served first and pointCount is even, player serves
        XCTAssertTrue(game.isPlayerServingNext, "After opponent reaches 11, serve alternates every point")
    }
    
    func testServeRotation_After11_OpponentReaches11_PlayerServesFirst_12Points() {
        // Opponent has 11, player has 1 (12 total points)
        let game = createGame(playerServesFirst: true, playerPoints: 1, opponentPoints: 11)
        // At 12 points (even), if player served first, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "After 11, serve alternates every point - opponent should serve")
    }
    
    func testServeRotation_After11_OpponentReaches11_OpponentServesFirst() {
        // Opponent reaches 11, player has 0
        let game = createGame(playerServesFirst: false, playerPoints: 0, opponentPoints: 11)
        // At 11 points total, if opponent served first and pointCount is odd, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "After opponent reaches 11, serve alternates every point")
    }
    
    func testServeRotation_After11_OpponentReaches11_OpponentServesFirst_12Points() {
        // Opponent has 11, player has 1 (12 total points)
        let game = createGame(playerServesFirst: false, playerPoints: 1, opponentPoints: 11)
        // At 12 points (even), if opponent served first, player serves
        XCTAssertTrue(game.isPlayerServingNext, "After 11, serve alternates every point - player should serve")
    }
    
    func testServeRotation_After11_BothReach11_PlayerServesFirst() {
        // Both players have 11+ points
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 11)
        // At 22 points (even), if player served first, player serves
        XCTAssertTrue(game.isPlayerServingNext, "After both reach 11, serve alternates every point")
    }
    
    func testServeRotation_After11_BothReach11_PlayerServesFirst_23Points() {
        // Both players have 11+ points, 23 total
        let game = createGame(playerServesFirst: true, playerPoints: 12, opponentPoints: 11)
        // At 23 points (odd), if player served first, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "After both reach 11, serve alternates every point")
    }
    
    // MARK: - Tests: Edge Cases
    
    func testServeRotation_Exactly11_PlayerServesFirst() {
        // Player has exactly 11, opponent has 0
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 0)
        XCTAssertTrue(game.isPlayerServingNext, "At exactly 11 points, serve should alternate every point")
    }
    
    func testServeRotation_Exactly11_OpponentServesFirst() {
        // Opponent has exactly 11, player has 0
        let game = createGame(playerServesFirst: false, playerPoints: 0, opponentPoints: 11)
        XCTAssertFalse(game.isPlayerServingNext, "At exactly 11 points, serve should alternate every point")
    }
    
    func testServeRotation_Player10_Opponent10() {
        // Both at 10, neither has reached 11
        let game = createGame(playerServesFirst: true, playerPoints: 10, opponentPoints: 10)
        // At 20 points total, still before 11, so block = 20/2 = 10, 10 % 2 = 0, player serves
        XCTAssertTrue(game.isPlayerServingNext, "At 10-10, still before 11, serve alternates every 2 points")
    }
    
    func testServeRotation_Player10_Opponent11() {
        // Player at 10, opponent at 11 (opponent reached 11)
        let game = createGame(playerServesFirst: true, playerPoints: 10, opponentPoints: 11)
        // At 21 points (odd), if player served first, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "Opponent reached 11, serve alternates every point")
    }
    
    func testServeRotation_Player11_Opponent10() {
        // Player at 11, opponent at 10 (player reached 11)
        let game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 10)
        // At 21 points (odd), if player served first, opponent serves
        XCTAssertFalse(game.isPlayerServingNext, "Player reached 11, serve alternates every point")
    }
    
    // MARK: - Tests: Realistic Game Scenarios
    
    func testServeRotation_RealisticGame_PlayerServesFirst() {
        // Simulate a realistic game progression
        // Points 1-2: Player serves (player wins both)
        var game = createGame(playerServesFirst: true, playerPoints: 2, opponentPoints: 0)
        XCTAssertFalse(game.isPlayerServingNext, "After 2 points, opponent should serve")
        
        // Points 3-4: Opponent serves (opponent wins both)
        game = createGame(playerServesFirst: true, playerPoints: 2, opponentPoints: 2)
        XCTAssertTrue(game.isPlayerServingNext, "After 4 points, player should serve")
        
        // Continue to 10-10
        game = createGame(playerServesFirst: true, playerPoints: 10, opponentPoints: 10)
        XCTAssertTrue(game.isPlayerServingNext, "At 10-10, player should serve")
        
        // Player wins to reach 11
        game = createGame(playerServesFirst: true, playerPoints: 11, opponentPoints: 10)
        XCTAssertFalse(game.isPlayerServingNext, "After player reaches 11, serve alternates every point")
    }
}

