//
//  MatchRulesTests.swift
//  PointIQTests
//
//  Created by Jin Cai on 12/24/25.
//

import XCTest
@testable import PointIQ

final class MatchRulesTests: XCTestCase {
    
    // MARK: - Game Rules Tests
    
    func testIsGameComplete_11to9() {
        let result = Rules.isGameComplete(playerPoints: 11, opponentPoints: 9)
        XCTAssertTrue(result, "Game should be complete at 11-9")
    }
    
    func testIsGameComplete_9to11() {
        let result = Rules.isGameComplete(playerPoints: 9, opponentPoints: 11)
        XCTAssertTrue(result, "Game should be complete at 9-11")
    }
    
    func testIsGameComplete_10to10() {
        let result = Rules.isGameComplete(playerPoints: 10, opponentPoints: 10)
        XCTAssertFalse(result, "Game should not be complete at 10-10 (deuce)")
    }
    
    func testIsGameComplete_11to10() {
        let result = Rules.isGameComplete(playerPoints: 11, opponentPoints: 10)
        XCTAssertFalse(result, "Game should not be complete at 11-10 (need 2 point lead)")
    }
    
    func testIsGameComplete_12to10() {
        let result = Rules.isGameComplete(playerPoints: 12, opponentPoints: 10)
        XCTAssertTrue(result, "Game should be complete at 12-10 (2 point lead)")
    }
    
    func testIsGameComplete_15to13() {
        let result = Rules.isGameComplete(playerPoints: 15, opponentPoints: 13)
        XCTAssertTrue(result, "Game should be complete at 15-13 (2 point lead after 11)")
    }
    
    func testIsGameComplete_MaximumPoints() {
        let result = Rules.isGameComplete(playerPoints: 30, opponentPoints: 28)
        XCTAssertTrue(result, "Game should be complete at maximum points")
    }
    
    func testGameWinner_PlayerWins() {
        let result = Rules.gameWinner(playerPoints: 11, opponentPoints: 9)
        XCTAssertEqual(result, true, "Player should win at 11-9")
    }
    
    func testGameWinner_OpponentWins() {
        let result = Rules.gameWinner(playerPoints: 9, opponentPoints: 11)
        XCTAssertEqual(result, false, "Opponent should win at 9-11")
    }
    
    func testGameWinner_NotComplete() {
        let result = Rules.gameWinner(playerPoints: 10, opponentPoints: 10)
        XCTAssertNil(result, "No winner when game not complete")
    }
    
    // MARK: - Deuce Tests
    
    func testIsDeuce_10to10() {
        let result = Rules.isDeuce(playerPoints: 10, opponentPoints: 10)
        XCTAssertTrue(result, "Should be deuce at 10-10")
    }
    
    func testIsDeuce_11to11() {
        let result = Rules.isDeuce(playerPoints: 11, opponentPoints: 11)
        XCTAssertTrue(result, "Should be deuce at 11-11")
    }
    
    func testIsDeuce_12to12() {
        let result = Rules.isDeuce(playerPoints: 12, opponentPoints: 12)
        XCTAssertTrue(result, "Should be deuce at 12-12")
    }
    
    func testIsDeuce_9to10() {
        let result = Rules.isDeuce(playerPoints: 9, opponentPoints: 10)
        XCTAssertFalse(result, "Should not be deuce at 9-10")
    }
    
    func testIsDeuce_10to9() {
        let result = Rules.isDeuce(playerPoints: 10, opponentPoints: 9)
        XCTAssertFalse(result, "Should not be deuce at 10-9")
    }
    
    func testIsDeuce_11to10() {
        let result = Rules.isDeuce(playerPoints: 11, opponentPoints: 10)
        XCTAssertFalse(result, "Should not be deuce at 11-10")
    }
    
    // MARK: - Game Status Tests
    
    func testGameStatus_Complete_PlayerWins() {
        let result = Rules.gameStatus(playerPoints: 11, opponentPoints: 9)
        XCTAssertEqual(result, "Game Won", "Status should be 'Game Won'")
    }
    
    func testGameStatus_Complete_OpponentWins() {
        let result = Rules.gameStatus(playerPoints: 9, opponentPoints: 11)
        XCTAssertEqual(result, "Game Lost", "Status should be 'Game Lost'")
    }
    
    func testGameStatus_Deuce() {
        let result = Rules.gameStatus(playerPoints: 10, opponentPoints: 10)
        XCTAssertEqual(result, "Deuce", "Status should be 'Deuce'")
    }
    
    func testGameStatus_GamePoint() {
        let result = Rules.gameStatus(playerPoints: 10, opponentPoints: 8)
        XCTAssertEqual(result, "Game Point", "Status should be 'Game Point' at 10-8")
    }
    
    func testGameStatus_InProgress() {
        let result = Rules.gameStatus(playerPoints: 5, opponentPoints: 3)
        XCTAssertEqual(result, "In Progress", "Status should be 'In Progress'")
    }
    
    // MARK: - Match Rules Tests
    
    func testIsMatchComplete_AlwaysFalse() {
        let result = Rules.isMatchComplete(playerGamesWon: 3, opponentGamesWon: 0)
        XCTAssertFalse(result, "Matches never auto-complete")
    }
    
    func testMatchWinner_AlwaysNil() {
        let result = Rules.matchWinner(playerGamesWon: 3, opponentGamesWon: 0)
        XCTAssertNil(result, "Matches never have a winner (never auto-complete)")
    }
}


