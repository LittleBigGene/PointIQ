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
    @State private var manualSwapOverride: Bool = false
    @State private var isUploadingMatch = false
    @State private var uploadError: String?
    @State private var showUploadError = false
    @AppStorage("pointHistoryHeightRatio") private var pointHistoryHeightRatio: Double = 0.55
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                VStack(spacing: 0) {
                    // Top Section: Official Scoreboard
                    ScoreboardView(
                        match: currentMatch,
                        game: currentGame,
                        modelContext: modelContext,
                        isLandscape: isLandscape,
                        manualSwapOverride: $manualSwapOverride,
                        onStartNewGame: {
                            startNewGame()
                        },
                        onResetMatch: {
                            showResetMatchConfirmation = true
                        },
                        onResetMatchDirect: {
                            resetMatch()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, isLandscape ? 20 : 0) // Move scoreboard down in landscape
#if os(iOS) || os(tvOS) || os(visionOS)
                    .background(Color(UIColor.systemBackground))
#elseif os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
#else
                    .background(Color.background)
#endif
                    
                    if !isLandscape {
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
                            manualSwapOverride: $manualSwapOverride,
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
            Button("Add to History", role: .none) {
                shareAndResetMatch()
            }
            Button("Reset", role: .destructive) {
                resetMatch()
            }
        } message: {
            Text("Choose an option:\n\n• Add to History: Upload match to cloud, then reset\n• Reset: Delete match locally and start new")
        }
        .alert("Upload Error", isPresented: $showUploadError) {
            Button("OK", role: .cancel) {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text("Failed to upload match: \(error)")
            }
        }
        .overlay {
            if isUploadingMatch {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Uploading match to cloud...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(24)
#if os(iOS) || os(tvOS) || os(visionOS)
                    .background(Color(UIColor.systemBackground))
#elseif os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
#else
                    .background(Color.background)
#endif
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
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
            // Restore points from local storage to SwiftData
            restorePointsFromStorage()
        } else {
            // No valid stored match, start a new one
            if currentMatch == nil {
                startNewMatch()
            } else {
                currentGame = currentMatch?.currentGame
            }
        }
    }
    
    private func restorePointsFromStorage() {
        guard let match = currentMatch else { return }
        
        let storedPoints = PointHistoryStorage.shared.loadAllPoints()
        guard !storedPoints.isEmpty else { return }
        
        // Collect all existing point IDs from all games
        var existingPointIDs = Set<String>()
        if let games = match.games {
            for game in games {
                if let points = game.points {
                    existingPointIDs.formUnion(points.map { $0.uniqueID })
                }
            }
        }
        
        // Group points by gameNumber to ensure games exist
        var gamesByNumber: [Int: Game] = [:]
        if let existingGames = match.games {
            for game in existingGames {
                gamesByNumber[game.gameNumber] = game
            }
        }
        
        for pointData in storedPoints {
            // Skip if point already exists in SwiftData
            if existingPointIDs.contains(pointData.id) {
                continue
            }
            
            // Find or create the game for this point
            let game: Game
            let gameNumber = pointData.gameNumber ?? 1
            
            if let existingGame = gamesByNumber[gameNumber] {
                game = existingGame
            } else {
                // Create game if it doesn't exist
                // Determine who serves first: alternate after each game
                let previousGame = gamesByNumber[gameNumber - 1]
                let playerServesFirst = GameSideSwap.determinePlayerServesFirst(gameNumber: gameNumber, previousGame: previousGame)
                
                let newGame = Game(match: match, gameNumber: gameNumber, playerServesFirst: playerServesFirst)
                modelContext.insert(newGame)
                gamesByNumber[gameNumber] = newGame
                game = newGame
                
                // Update currentGame if this is the highest game number
                if gameNumber >= (currentGame?.gameNumber ?? 0) {
                    currentGame = game
                }
            }
            
            // Convert PointData back to Point
            guard let outcome = Outcome(rawValue: pointData.outcome) else { continue }
            let strokeTokens = pointData.strokeTokens.compactMap { StrokeToken(rawValue: $0) }
            
            let point = Point(
                timestamp: pointData.timestamp,
                strokeTokens: strokeTokens,
                outcome: outcome,
                match: match,
                game: game,
                serveType: pointData.serveType,
                receiveType: pointData.receiveType,
                rallyTypes: pointData.rallyTypes
            )
            
            modelContext.insert(point)
        }
        
        do {
            try modelContext.save()
            
            // Ensure currentGame is set correctly after restoration
            if let match = currentMatch {
                // Find the game with the highest number that has points, or use the active game
                if let games = match.games {
                    // First, try to find a game with points
                    let gamesWithPoints = games.filter { game in
                        // Force relationship to load by accessing it
                        let pointCount = game.points?.count ?? 0
                        return pointCount > 0
                    }
                    
                    if let latestGame = gamesWithPoints.sorted(by: { $0.gameNumber > $1.gameNumber }).first {
                        currentGame = latestGame
                    } else if let activeGame = match.currentGame {
                        currentGame = activeGame
                    } else if let firstGame = games.first {
                        currentGame = firstGame
                    }
                }
            }
        } catch {
            print("Error restoring points from storage: \(error)")
        }
    }
    
    private func startNewMatch() {
        let newMatch = Match()
        modelContext.insert(newMatch)
        currentMatch = newMatch
        startNewGame()
        try? modelContext.save()
        
        // Restore points from local storage if they exist
        restorePointsFromStorage()
    }
    
    private func startNewGame() {
        guard let match = currentMatch else { return }
        let gameNumber = (match.games?.count ?? 0) + 1
        
        // Determine who serves first: alternate after each game
        let previousGame = match.games?.sorted(by: { $0.gameNumber > $1.gameNumber }).first
        let playerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: previousGame)
        
        let newGame = Game(match: match, gameNumber: gameNumber, playerServesFirst: playerServesFirst)
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
        
        // Set relationships before inserting
        point.match = match
        point.game = game
        modelContext.insert(point)
        lastPoint = point
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving point: \(error)")
        }
        
        // Save point to local storage
        PointHistoryStorage.shared.savePoint(point, gameNumber: game.gameNumber)
        
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
        let pointID = point.uniqueID
        modelContext.delete(point)
        lastPoint = nil
        try? modelContext.save()
        
        // Remove point from local storage by ID
        PointHistoryStorage.shared.removePoint(byID: pointID)
    }
    
    private func shareAndResetMatch() {
        guard let match = currentMatch else { return }
        
        // Check if Supabase is configured
        guard SupabaseConfig.isConfigured else {
            uploadError = "Supabase is not configured. Please configure it in Settings."
            showUploadError = true
            return
        }
        
        isUploadingMatch = true
        
        Task {
            do {
                // Upload the match to Supabase
                try await SupabaseService.shared.uploadMatch(match)
                
                // Upload successful, now reset
                await MainActor.run {
                    isUploadingMatch = false
                    resetMatch()
                }
            } catch {
                await MainActor.run {
                    isUploadingMatch = false
                    uploadError = error.localizedDescription
                    showUploadError = true
                }
            }
        }
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
            
            // Clear local point history storage
            PointHistoryStorage.shared.clearAllPoints()
            
            // Clear opponent information (player profile persists)
            clearOpponentInformation()
            
            // Start a new match
            startNewMatch()
        }
    }
    
    private func clearOpponentInformation() {
        // Clear all opponent AppStorage values
        UserDefaults.standard.removeObject(forKey: "opponentName")
        UserDefaults.standard.removeObject(forKey: "opponentGrip")
        UserDefaults.standard.removeObject(forKey: "opponentHandedness")
        UserDefaults.standard.removeObject(forKey: "opponentBlade")
        UserDefaults.standard.removeObject(forKey: "opponentForehandRubber")
        UserDefaults.standard.removeObject(forKey: "opponentBackhandRubber")
        UserDefaults.standard.removeObject(forKey: "opponentEloRating")
        UserDefaults.standard.removeObject(forKey: "opponentClubName")
    }
}

#Preview(traits: .portrait) {
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}
