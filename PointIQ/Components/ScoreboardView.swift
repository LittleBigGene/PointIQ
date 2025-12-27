//
//  ScoreboardView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

// MARK: - Scoreboard View (Top Section)
struct ScoreboardView: View {
    let match: Match?
    let game: Game?
    let modelContext: ModelContext
    let isLandscape: Bool
    let onStartNewGame: () -> Void
    let onResetMatch: () -> Void
    
    // Scale factors for landscape mode
    private var titleFontSize: CGFloat { isLandscape ? 32 : 14 }
    private var scoreFontSize: CGFloat { isLandscape ? 180 : 56 }
    private var matchScoreFontSize: CGFloat { isLandscape ? 120 : 40 }
    private var matchLabelFontSize: CGFloat { isLandscape ? 24 : 12 }
    private var statusFontSize: CGFloat { isLandscape ? 20 : 10 }
    private var serveIndicatorFontSize: CGFloat { isLandscape ? 24 : 12 }
    private var verticalPadding: CGFloat { isLandscape ? 10 : 20 }
    private var spacing: CGFloat { isLandscape ? 24 : 8 }
    private let tabBarHeight: CGFloat = 83
    
    // Determine who is serving based on point count (serve switches every 2 points)
    private var isPlayerServing: Bool {
        guard let game = game else { return true } // Default to player serving
        let pointCount = game.pointCount
        let playerServesFirst = game.playerServesFirst
        
        if playerServesFirst {
            // Points 1-2: player serves, Points 3-4: opponent serves, etc.
            return (pointCount % 4) < 2
        } else {
            // Points 1-2: opponent serves, Points 3-4: player serves, etc.
            return (pointCount % 4) >= 2
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                Spacer()
            }
            
            if let match = match, let game = game {
                // Single row with 3 columns: Game Points (YOU) | Match Games | Game Points (OPP)
                HStack(spacing: 0) {
                    // Column 1: YOU Game Points
                    VStack(spacing: spacing) {
                        Text("YOU")
                            .font(.system(size: titleFontSize, weight: .black))
                            .foregroundColor(.primary)
                        Text("\(game.pointsWon)")
                            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(game.isComplete && game.winner == true ? .green : .primary)
                        // Serve/Receive indicator
                        Text(isPlayerServing ? "SERVE" : "RECEIVE")
                            .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                            .foregroundColor(isPlayerServing ? .blue : .secondary)
                            .onTapGesture {
                                // Flip serving order only if no points have been played yet
                                if isLandscape && game.pointCount == 0 {
                                    game.playerServesFirst.toggle()
                                    try? modelContext.save()
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, verticalPadding)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                let verticalMovement = value.translation.height
                                if abs(verticalMovement) > abs(value.translation.width) {
                                    if game.isComplete {
                                        // Game is complete - end game and start new one
                                        resetGame(game: game, match: match)
                                    } else {
                                        if verticalMovement < 0 {
                                            // Swipe up - increase score
                                            increasePlayerScore(game: game, match: match)
                                        } else {
                                            // Swipe down - decrease score
                                            decreasePlayerScore(game: game, match: match)
                                        }
                                    }
                                }
                            }
                    )
                    
                    // Column 2: Match Games Counter
                    VStack(alignment: .center, spacing: spacing) {
                        Text("MATCH")
                            .font(.system(size: matchLabelFontSize, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: isLandscape ? 32 : 16) {
                            Text("\(match.gamesWon)")
                                .font(.system(size: matchScoreFontSize, weight: .bold, design: .rounded))
                                .foregroundColor(match.isComplete && match.winner == true ? .green : .primary)
                            Text(":")
                                .font(.system(size: isLandscape ? 80 : 32, weight: .light))
                                .foregroundColor(.secondary)
                            Text("\(match.gamesLost)")
                                .font(.system(size: matchScoreFontSize, weight: .bold, design: .rounded))
                                .foregroundColor(match.isComplete && match.winner == false ? .red : .primary)
                        }
                        // Status indicator
                        if game.isComplete {
                            Text(game.winner == true ? "GAME WON" : "GAME LOST")
                                .font(.system(size: statusFontSize, weight: .bold))
                                .foregroundColor(game.winner == true ? .green : .red)
                        } else if game.isDeuce {
                            Text("DEUCE")
                                .font(.system(size: statusFontSize, weight: .bold))
                                .foregroundColor(.orange)
                        } else {
                            let status = game.statusMessage
                            if status == "Game Point" {
                                Text("GAME POINT")
                                    .font(.system(size: statusFontSize, weight: .bold))
                                    .foregroundColor(.orange)
                            } else {
                                Text(" ")
                                    .font(.system(size: statusFontSize))
                            }
                        }
                        Spacer() // Push content to top
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, verticalPadding)
                    .padding(.bottom, verticalPadding)
                    .background(
                        Color.secondary.opacity(0.1)
                            .ignoresSafeArea(.container, edges: isLandscape ? [.top, .leading, .trailing] : [])
                    )
                    .overlay(
                        isLandscape ? VStack {
                            Spacer()
                            Color(UIColor.systemBackground)
                                .frame(height: tabBarHeight)
                                .ignoresSafeArea(.container, edges: .bottom)
                        } : nil,
                        alignment: .bottom
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                let horizontalMovement = value.translation.width
                                let verticalMovement = value.translation.height
                                // Swipe left or right to reset match (only if match has games)
                                if abs(horizontalMovement) > abs(verticalMovement) && abs(horizontalMovement) > 50 {
                                    // Only reset if match counter is not 0:0
                                    if match.gamesWon > 0 || match.gamesLost > 0 {
                                        onResetMatch()
                                    }
                                }
                            }
                    )
                    
                    // Column 3: OPP Game Points
                    VStack(spacing: spacing) {
                        Text("OPP")
                            .font(.system(size: titleFontSize, weight: .black))
                            .foregroundColor(.primary)
                        Text("\(game.pointsLost)")
                            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(game.isComplete && game.winner == false ? .red : .primary)
                        // Serve/Receive indicator
                        Text(isPlayerServing ? "RECEIVE" : "SERVE")
                            .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                            .foregroundColor(isPlayerServing ? .secondary : .blue)
                            .onTapGesture {
                                // Flip serving order only if no points have been played yet
                                if isLandscape && game.pointCount == 0 {
                                    game.playerServesFirst.toggle()
                                    try? modelContext.save()
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, verticalPadding)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                let verticalMovement = value.translation.height
                                if abs(verticalMovement) > abs(value.translation.width) {
                                    if game.isComplete {
                                        // Game is complete - end game and start new one
                                        resetGame(game: game, match: match)
                                    } else {
                                        if verticalMovement < 0 {
                                            // Swipe up - increase opponent score
                                            increaseOpponentScore(game: game, match: match)
                                        } else {
                                            // Swipe down - decrease opponent score
                                            decreaseOpponentScore(game: game, match: match)
                                        }
                                    }
                                }
                            }
                    )
                }
            } else {
                VStack {
                    Spacer()
                    Text("No Active Match")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if isLandscape {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Score Adjustment Functions
    
    private func resetGame(game: Game, match: Match) {
        // If game is complete, end it and start a new game
        if game.isComplete {
            // Mark current game as complete
            game.endDate = Date()
            try? modelContext.save()
            
            // Start a new game
            onStartNewGame()
        } else {
            // If game is not complete, just delete all points to reset to 0:0
            if let points = game.points {
                for point in points {
                    modelContext.delete(point)
                }
                try? modelContext.save()
            }
        }
    }
    
    private func increasePlayerScore(game: Game, match: Match) {
        let point = Point(
            strokeTokens: [],
            outcome: .myWinner,
            match: match,
            game: game
        )
        modelContext.insert(point)
        try? modelContext.save()
    }
    
    private func decreasePlayerScore(game: Game, match: Match) {
        // Find and remove the most recent point with outcome .winner
        if let points = game.points {
            let winnerPoints = points.filter { $0.outcome == .myWinner }
            if let lastWinnerPoint = winnerPoints.sorted(by: { $0.timestamp > $1.timestamp }).first {
                modelContext.delete(lastWinnerPoint)
                try? modelContext.save()
            }
        }
    }
    
    private func increaseOpponentScore(game: Game, match: Match) {
        let point = Point(
            strokeTokens: [],
            outcome: .iMissed,
            match: match,
            game: game
        )
        modelContext.insert(point)
        try? modelContext.save()
    }
    
    private func decreaseOpponentScore(game: Game, match: Match) {
        // Find and remove the most recent point with outcome .iMissed
        if let points = game.points {
            let opponentPoints = points.filter { $0.outcome == .iMissed }
            if let lastOpponentPoint = opponentPoints.sorted(by: { $0.timestamp > $1.timestamp }).first {
                modelContext.delete(lastOpponentPoint)
                try? modelContext.save()
            }
        }
    }
}


