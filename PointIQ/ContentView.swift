//
//  ContentView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.startDate, order: .reverse) private var matches: [Match]
    @AppStorage("currentMatchID") private var currentMatchIDString: String = ""
    @State private var currentMatch: Match?
    @State private var currentGame: Game?
    @State private var lastPoint: Point?
    @State private var isVoiceInputActive = false
    @State private var showResetMatchConfirmation = false
    @AppStorage("pointHistoryHeightRatio") private var pointHistoryHeightRatio: Double = 0.55
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top Section: Official Scoreboard
                    ScoreboardView(
                        match: currentMatch,
                        game: currentGame,
                        modelContext: modelContext,
                        onStartNewGame: {
                            startNewGame()
                        },
                        onResetMatch: {
                            showResetMatchConfirmation = true
                        }
                    )
                    .frame(height: geometry.size.height * 0.20)
#if os(iOS) || os(tvOS) || os(visionOS)
                    .background(Color(UIColor.systemBackground))
#elseif os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
#else
                    .background(Color.background)
#endif
                    
                    Divider()
                    
                    // Middle Section: Point History
                    PointHistoryView(
                        match: currentMatch,
                        game: currentGame
                    )
                    .frame(height: geometry.size.height * pointHistoryHeightRatio)
                    .background(Color.secondary.opacity(0.05))
                    
                    // Resizable divider
                    ResizableDivider(
                        heightRatio: $pointHistoryHeightRatio,
                        totalHeight: geometry.size.height,
                        topSectionHeight: geometry.size.height * 0.20
                    )
                    
                    // Bottom Section: Quick Logging Buttons
                    QuickLoggingView(
                        currentMatch: $currentMatch,
                        currentGame: $currentGame,
                        lastPoint: $lastPoint,
                        isVoiceInputActive: $isVoiceInputActive,
                        pointHistoryHeightRatio: pointHistoryHeightRatio,
                        onPointLogged: { point in
                            logPoint(point)
                        },
                        onUndo: {
                            undoLastPoint()
                        }
                    )
                    .frame(height: geometry.size.height * (1.0 - 0.20 - pointHistoryHeightRatio))
                }
            }
        }
        .onAppear {
            // Restore current match from stored ID
            restoreCurrentMatch()
        }
        .onChange(of: currentMatch?.id) { _, newID in
            // Save current match ID when it changes
            if let id = newID {
                currentMatchIDString = id.uuidString
            } else {
                currentMatchIDString = ""
            }
        }
        .alert("Reset Match", isPresented: $showResetMatchConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetMatch()
            }
        } message: {
            Text("Are you sure you want to reset the match? This will delete all games and points in the current match and start a new one.")
        }
    }
    
    private func restoreCurrentMatch() {
        // Try to restore the current match from stored ID
        if !currentMatchIDString.isEmpty,
           let matchID = UUID(uuidString: currentMatchIDString),
           let match = matches.first(where: { $0.id == matchID }),
           match.isActive {
            currentMatch = match
            currentGame = match.currentGame
        } else {
            // No valid stored match, start a new one
            if currentMatch == nil {
                startNewMatch()
            } else {
                currentGame = currentMatch?.currentGame
            }
        }
    }
    
    private func startNewMatch() {
        let newMatch = Match()
        modelContext.insert(newMatch)
        currentMatch = newMatch
        startNewGame()
        try? modelContext.save()
    }
    
    private func startNewGame() {
        guard let match = currentMatch else { return }
        let gameNumber = (match.games?.count ?? 0) + 1
        let newGame = Game(match: match, gameNumber: gameNumber)
        modelContext.insert(newGame)
        currentGame = newGame
        try? modelContext.save()
    }
    
    private func endCurrentMatch() {
        currentGame?.endDate = Date()
        currentMatch?.endDate = Date()
        currentGame = nil
        currentMatch = nil
        try? modelContext.save()
    }
    
    private func logPoint(_ point: Point) {
        guard let match = currentMatch, let game = currentGame else { return }
        point.match = match
        point.game = game
        modelContext.insert(point)
        lastPoint = point
        try? modelContext.save()
        
        // Check if game is complete
        if game.isComplete {
            endCurrentGame()
        }
    }
    
    private func endCurrentGame() {
        guard let game = currentGame else { return }
        game.endDate = Date()
        currentGame = nil
        
        // Automatically start a new game
        if currentMatch != nil {
            startNewGame()
        }
        
        try? modelContext.save()
    }
    
    private func undoLastPoint() {
        guard let point = lastPoint else { return }
        modelContext.delete(point)
        lastPoint = nil
        try? modelContext.save()
    }
    
    private func resetMatch() {
        // Delete the current match and all its associated data
        if let match = currentMatch {
            // Delete all games and points (cascade should handle this, but being explicit)
            if let games = match.games {
                for game in games {
                    if let points = game.points {
                        for point in points {
                            modelContext.delete(point)
                        }
                    }
                    modelContext.delete(game)
                }
            }
            modelContext.delete(match)
            currentGame = nil
            currentMatch = nil
            lastPoint = nil
            try? modelContext.save()
            
            // Start a new match
            startNewMatch()
        }
    }
}

#Preview(traits: .portrait) {
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}
