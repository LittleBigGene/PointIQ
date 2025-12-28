//
//  GameSideSwapTests.swift
//  PointIQTests
//
//  Created by Jin Cai on 12/24/25.
//

import XCTest
@testable import PointIQ

final class GameSideSwapTests: XCTestCase {
    
    // MARK: - shouldSwapPlayers Tests
    
    func testShouldSwapPlayers_Game1_NoOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 1, manualSwapOverride: false)
        XCTAssertFalse(result, "Game 1 should not swap (odd game number)")
    }
    
    func testShouldSwapPlayers_Game2_NoOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 2, manualSwapOverride: false)
        XCTAssertTrue(result, "Game 2 should swap (even game number)")
    }
    
    func testShouldSwapPlayers_Game3_NoOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 3, manualSwapOverride: false)
        XCTAssertFalse(result, "Game 3 should not swap (odd game number)")
    }
    
    func testShouldSwapPlayers_Game1_WithOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 1, manualSwapOverride: true)
        XCTAssertTrue(result, "Game 1 with override should swap")
    }
    
    func testShouldSwapPlayers_Game2_WithOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 2, manualSwapOverride: true)
        XCTAssertFalse(result, "Game 2 with override should not swap")
    }
    
    func testShouldSwapPlayers_Game3_WithOverride() {
        let result = GameSideSwap.shouldSwapPlayers(gameNumber: 3, manualSwapOverride: true)
        XCTAssertTrue(result, "Game 3 with override should swap")
    }
    
    // MARK: - determinePlayerServesFirst Tests
    
    func testDeterminePlayerServesFirst_NoPreviousGame() {
        let result = GameSideSwap.determinePlayerServesFirst(previousGame: nil)
        XCTAssertTrue(result, "First game should have player serve first")
    }
    
    func testDeterminePlayerServesFirst_PlayerServedFirst() {
        let previousGame = Game(playerServesFirst: true)
        let result = GameSideSwap.determinePlayerServesFirst(previousGame: previousGame)
        XCTAssertFalse(result, "Should alternate - opponent serves first after player served first")
    }
    
    func testDeterminePlayerServesFirst_OpponentServedFirst() {
        let previousGame = Game(playerServesFirst: false)
        let result = GameSideSwap.determinePlayerServesFirst(previousGame: previousGame)
        XCTAssertTrue(result, "Should alternate - player serves first after opponent served first")
    }
    
    func testDeterminePlayerServesFirst_GameNumber1_NoPrevious() {
        let result = GameSideSwap.determinePlayerServesFirst(gameNumber: 1, previousGame: nil)
        XCTAssertTrue(result, "Game 1 should have player serve first")
    }
    
    func testDeterminePlayerServesFirst_GameNumber2_WithPrevious() {
        let previousGame = Game(gameNumber: 1, playerServesFirst: true)
        let result = GameSideSwap.determinePlayerServesFirst(gameNumber: 2, previousGame: previousGame)
        XCTAssertFalse(result, "Game 2 should alternate from game 1")
    }
    
    func testDeterminePlayerServesFirst_GameNumber3_NoPrevious() {
        let result = GameSideSwap.determinePlayerServesFirst(gameNumber: 3, previousGame: nil)
        XCTAssertTrue(result, "Game 3 (odd) should default to player serve first")
    }
    
    func testDeterminePlayerServesFirst_GameNumber4_NoPrevious() {
        let result = GameSideSwap.determinePlayerServesFirst(gameNumber: 4, previousGame: nil)
        XCTAssertFalse(result, "Game 4 (even) should default to opponent serve first")
    }
}


