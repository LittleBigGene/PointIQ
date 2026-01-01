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
    @Binding var manualSwapOverride: Bool
    let onStartNewGame: () -> Void
    let onResetMatch: () -> Void
    let onResetMatchDirect: () -> Void
    
    @AppStorage("playerName") private var playerName: String = "YOU"
    @AppStorage("opponentName") private var opponentName: String = ""
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // MARK: - Translation Helpers
    
    private func noActiveMatchText(for language: Language) -> String {
        switch language {
        case .english: return "No Active Match"
        case .japanese: return "アクティブな試合なし"
        case .chinese: return "沒有進行中的比賽"
        }
    }
    
    private func serveText(for language: Language) -> String {
        switch language {
        case .english: return "SERVE"
        case .japanese: return "サーブ"
        case .chinese: return "發球"
        }
    }
    
    private func receiveText(for language: Language) -> String {
        switch language {
        case .english: return "RECEIVE"
        case .japanese: return "レシーブ"
        case .chinese: return "接球"
        }
    }
    
    private func matchText(for language: Language) -> String {
        switch language {
        case .english: return "MATCH"
        case .japanese: return "試合"
        case .chinese: return "比賽"
        }
    }
    
    private func bestOfText(for language: Language) -> String {
        switch language {
        case .english: return "Best of"
        case .japanese: return "先取"
        case .chinese: return "搶"
        }
    }
    
    private func gameWonText(for language: Language) -> String {
        switch language {
        case .english: return "GAME WON"
        case .japanese: return "ゲーム勝利"
        case .chinese: return "局勝"
        }
    }
    
    private func gameLostText(for language: Language) -> String {
        switch language {
        case .english: return "GAME LOST"
        case .japanese: return "ゲーム敗北"
        case .chinese: return "局敗"
        }
    }
    
    private func deuceText(for language: Language) -> String {
        switch language {
        case .english: return "DEUCE"
        case .japanese: return "ジュース"
        case .chinese: return "平分"
        }
    }
    
    private func gamePointText(for language: Language) -> String {
        switch language {
        case .english: return "GAME POINT"
        case .japanese: return "ゲームポイント"
        case .chinese: return "局點"
        }
    }
    
    // Scale factors for landscape mode
    private var titleFontSize: CGFloat { isLandscape ? 32 : 14 }
    private var scoreFontSize: CGFloat { isLandscape ? 180 : 56 }
    private var matchScoreFontSize: CGFloat { isLandscape ? 120 : 40 }
    private var matchLabelFontSize: CGFloat { isLandscape ? 24 : 12 }
    private var statusFontSize: CGFloat { isLandscape ? 20 : 10 }
    private var serveIndicatorFontSize: CGFloat { isLandscape ? 24 : 12 }
    private var verticalPadding: CGFloat { isLandscape ? 10 : 20 }
    private var spacing: CGFloat { isLandscape ? 16 : 6 }
    private let tabBarHeight: CGFloat = 83
    
    // Determine who is serving for the NEXT point
    private var isPlayerServing: Bool {
        game?.isPlayerServingNext ?? true // Default to player serving
    }
    
    // Determine if players should be swapped (combines automatic and manual override)
    private var shouldSwapPlayers: Bool {
        guard let game = game else { return false }
        return GameSideSwap.shouldSwapPlayers(gameNumber: game.gameNumber, manualSwapOverride: manualSwapOverride)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                Spacer()
            }
            
            if let match = match, let game = game {
                // Single row with 3 columns: Game Points | Match Games | Game Points
                // Positions swap based on game number (even = swapped)
                HStack(spacing: 0) {
                    if shouldSwapPlayers {
                        // Swapped: OPP on left, YOU on right
                        leftColumn(game: game, match: match, isPlayer: false)
                        matchColumn(game: game, match: match)
                        rightColumn(game: game, match: match, isPlayer: true)
                    } else {
                        // Normal: YOU on left, OPP on right
                        leftColumn(game: game, match: match, isPlayer: true)
                        matchColumn(game: game, match: match)
                        rightColumn(game: game, match: match, isPlayer: false)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text(noActiveMatchText(for: selectedLanguage))
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
    
    // MARK: - Column Views
    
    @ViewBuilder
    private func leftColumn(game: Game, match: Match, isPlayer: Bool) -> some View {
        let label = isPlayer ? (playerName.isEmpty ? "YOU" : playerName) : (opponentName.isEmpty ? "OPP" : opponentName)
        let score = isPlayer ? game.pointsWon : game.pointsLost
        // Serve indicator is based on position (left side), not player identity
        // Left side serves when: not swapped and player serves, OR swapped and opponent serves
        let isServing = shouldSwapPlayers ? !isPlayerServing : isPlayerServing
        
        VStack(spacing: spacing) {
            Text(label)
                .font(.system(size: titleFontSize, weight: .black))
                .foregroundColor(isPlayer ? .blue : .red)
                .onTapGesture {
                    // Toggle manual swap override
                    manualSwapOverride.toggle()
                }
            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                .foregroundColor(isPlayer ? .blue : .red)
            // Serve/Receive indicator
            HStack(spacing: 4) {
                Text(isServing ? "🫴" : "👁️")
                    .font(.system(size: serveIndicatorFontSize))
                Text(isServing ? serveText(for: selectedLanguage) : receiveText(for: selectedLanguage))
                    .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                // Toggle who serves first
                game.playerServesFirst.toggle()
                try? modelContext.save()
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, isLandscape ? 8 : 12)
        .padding(.bottom, isLandscape ? 4 : 6)
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
                                if isPlayer {
                                    increasePlayerScore(game: game, match: match)
                                } else {
                                    increaseOpponentScore(game: game, match: match)
                                }
                            } else {
                                // Swipe down - decrease score
                                if isPlayer {
                                    decreasePlayerScore(game: game, match: match)
                                } else {
                                    decreaseOpponentScore(game: game, match: match)
                                }
                            }
                        }
                    }
                }
        )
    }
    
    @ViewBuilder
    private func rightColumn(game: Game, match: Match, isPlayer: Bool) -> some View {
        let label = isPlayer ? (playerName.isEmpty ? "YOU" : playerName) : (opponentName.isEmpty ? "OPP" : opponentName)
        let score = isPlayer ? game.pointsWon : game.pointsLost
        // Serve indicator is based on position (right side), not player identity
        // Right side serves when: not swapped and opponent serves, OR swapped and player serves
        let isServing = shouldSwapPlayers ? isPlayerServing : !isPlayerServing
        
        VStack(spacing: spacing) {
            Text(label)
                .font(.system(size: titleFontSize, weight: .black))
                .foregroundColor(isPlayer ? .blue : .red)
                .onTapGesture {
                    // Toggle manual swap override
                    manualSwapOverride.toggle()
                }
            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                .foregroundColor(isPlayer ? .blue : .red)
            // Serve/Receive indicator
            HStack(spacing: 4) {
                Text(isServing ? "🫴" : "👁️")
                    .font(.system(size: serveIndicatorFontSize))
                Text(isServing ? serveText(for: selectedLanguage) : receiveText(for: selectedLanguage))
                    .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                // Toggle who serves first
                game.playerServesFirst.toggle()
                try? modelContext.save()
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, isLandscape ? 8 : 12)
        .padding(.bottom, isLandscape ? 4 : 6)
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
                                if isPlayer {
                                    increasePlayerScore(game: game, match: match)
                                } else {
                                    increaseOpponentScore(game: game, match: match)
                                }
                            } else {
                                // Swipe down - decrease score
                                if isPlayer {
                                    decreasePlayerScore(game: game, match: match)
                                } else {
                                    decreaseOpponentScore(game: game, match: match)
                                }
                            }
                        }
                    }
                }
        )
    }
    
    @ViewBuilder
    private func matchColumn(game: Game, match: Match) -> some View {
        // Swap match scores when players are swapped
        let leftScore = shouldSwapPlayers ? match.gamesLost : match.gamesWon
        let rightScore = shouldSwapPlayers ? match.gamesWon : match.gamesLost
        
        VStack(alignment: .center, spacing: spacing) {
            Text(matchText(for: selectedLanguage))
                .font(.system(size: titleFontSize, weight: .black))
                .foregroundColor(.secondary)
                .padding(.top, isLandscape ? 8 : 0)
            HStack(spacing: isLandscape ? 16 : 8) {
                Text("\(leftScore)")
                    .font(.system(size: matchScoreFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(shouldSwapPlayers ? .red : .blue)
                Text(":")
                    .font(.system(size: isLandscape ? 80 : 32, weight: .light))
                    .foregroundColor(.secondary)
                Text("\(rightScore)")
                    .font(.system(size: matchScoreFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(shouldSwapPlayers ? .blue : .red)
            }
            
            // Match format - show slider before game starts, show text only after
            if game.pointCount == 0 {
                // Before game starts: show label and slider
                VStack(spacing: isLandscape ? 8 : 4) {
                    Text(bestOfText(for: selectedLanguage))
                        .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, isLandscape ? 0 : 4)
                    Picker("Match Format", selection: Binding(
                        get: { match.bestOf },
                        set: { newValue in
                            match.bestOf = newValue
                            try? modelContext.save()
                        }
                    )) {
                        Text("3").tag(3)
                        Text("5").tag(5)
                        Text("7").tag(7)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: isLandscape ? 180 : 90)
                    .frame(height: isLandscape ? 32 : 20)
                }
                .padding(.top, isLandscape ? -16 : 0)
                .padding(.bottom, isLandscape ? 4 : 0)
                .frame(minHeight: isLandscape ? 50 : 30)
            } else {
                // After game starts: show "Best of X" text where slider was
                Text("\(bestOfText(for: selectedLanguage)) \(match.bestOf)")
                    .font(.system(size: serveIndicatorFontSize, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: isLandscape ? 180 : 90)
                    .frame(height: isLandscape ? 32 : 20)
                    .padding(.top, isLandscape ? -16 : 0)
                    .padding(.bottom, isLandscape ? 4 : 0)
            }
            
            // Status indicator
            if game.isComplete {
                Text(game.winner == true ? gameWonText(for: selectedLanguage) : gameLostText(for: selectedLanguage))
                    .font(.system(size: statusFontSize, weight: .bold))
                    .foregroundColor(game.winner == true ? .blue : .red)
            } else if game.isDeuce {
                Text(deuceText(for: selectedLanguage))
                    .font(.system(size: statusFontSize, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                let status = game.statusMessage
                if status == "Game Point" {
                    Text(gamePointText(for: selectedLanguage))
                        .font(.system(size: statusFontSize, weight: .bold))
                        .foregroundColor(.orange)
                } else {
                    Text(" ")
                        .font(.system(size: statusFontSize))
                }
            }
            
            if isLandscape {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, isLandscape ? 8 : 20)
        .padding(.bottom, isLandscape ? 20 : 6)
        .background(
            Color.secondary.opacity(0.1)
                .ignoresSafeArea(.container, edges: isLandscape ? [.top, .leading, .trailing, .bottom] : [])
        )
        .overlay(
            isLandscape ? VStack {
                Spacer()
                    .frame(minHeight: 0)
                Color(UIColor.systemBackground)
                    .frame(height: tabBarHeight)
                    .ignoresSafeArea(.container, edges: .bottom)
            } : nil,
            alignment: .bottom
        )
        .clipped()
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    let horizontalMovement = value.translation.width
                    let verticalMovement = value.translation.height
                    // Swipe left/right to reset match (shows confirmation)
                    if abs(horizontalMovement) > abs(verticalMovement) && abs(horizontalMovement) > 30 {
                        let hasGames = (match.games?.count ?? 0) > 0
                        let hasPoints = (match.points?.count ?? 0) > 0
                        if hasGames || hasPoints {
                            onResetMatch()
                        }
                    }
                }
        )
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


