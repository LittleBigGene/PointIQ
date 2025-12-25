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
                    .frame(height: geometry.size.height * 0.45)
                    .background(Color.secondary.opacity(0.05))
                    
                    Divider()
                    
                    // Bottom Section: Quick Logging Buttons
                    QuickLoggingView(
                        currentMatch: $currentMatch,
                        currentGame: $currentGame,
                        lastPoint: $lastPoint,
                        isVoiceInputActive: $isVoiceInputActive,
                        onPointLogged: { point in
                            logPoint(point)
                        },
                        onUndo: {
                            undoLastPoint()
                        }
                    )
                    .frame(height: geometry.size.height * 0.35)
                }
            }
            .navigationTitle("PointIQ")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Voice input toggle
                        Button(action: {
                            isVoiceInputActive.toggle()
                        }) {
                            Image(systemName: isVoiceInputActive ? "mic.fill" : "mic")
                                .foregroundColor(isVoiceInputActive ? .red : .primary)
                        }
                        
                        // Menu
                        Menu {
                            if currentMatch == nil {
                                Button("New Match") {
                                    startNewMatch()
                                }
                            } else {
                                Button("End Match") {
                                    endCurrentMatch()
                                }
                                Button("New Game") {
                                    startNewGame()
                                }
                            }
                            Button("Match History") {
                                // TODO: Show match history
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 12) {
                        // Voice input toggle
                        Button(action: {
                            isVoiceInputActive.toggle()
                        }) {
                            Image(systemName: isVoiceInputActive ? "mic.fill" : "mic")
                                .foregroundColor(isVoiceInputActive ? .red : .primary)
                        }
                        
                        // Menu
                        Menu {
                            if currentMatch == nil {
                                Button("New Match") {
                                    startNewMatch()
                                }
                            } else {
                                Button("End Match") {
                                    endCurrentMatch()
                                }
                                Button("New Game") {
                                    startNewGame()
                                }
                            }
                            Button("Match History") {
                                // TODO: Show match history
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                #endif
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

// MARK: - Scoreboard View (Top Section)
struct ScoreboardView: View {
    let match: Match?
    let game: Game?
    let modelContext: ModelContext
    let onStartNewGame: () -> Void
    let onResetMatch: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if let match = match, let game = game {
                // Single row with 3 columns: Game Points (YOU) | Match Games | Game Points (OPP)
                HStack(spacing: 0) {
                    // Column 1: YOU Game Points
                    VStack(spacing: 8) {
                        Text("YOU")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(game.pointsWon)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(game.isComplete && game.winner == true ? .green : .primary)                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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
                    VStack(spacing: 8) {
                        Text("MATCH")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            Text("\(match.gamesWon)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(match.isComplete && match.winner == true ? .green : .primary)
                            Text(":")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.secondary)
                            Text("\(match.gamesLost)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(match.isComplete && match.winner == false ? .red : .primary)
                        }
                        // Status indicator
                        if game.isComplete {
                            Text(game.winner == true ? "GAME WON" : "GAME LOST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(game.winner == true ? .green : .red)
                        } else if game.isDeuce {
                            Text("DEUCE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                        } else {
                            let status = game.statusMessage
                            if status == "Game Point" {
                                Text("GAME POINT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            } else {
                                Text(" ")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.secondary.opacity(0.1))
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
                    VStack(spacing: 8) {
                        Text("OPP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(game.pointsLost)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(game.isComplete && game.winner == false ? .red : .primary)
                        if let opponent = match.opponentName {
                            Text(opponent.uppercased())
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text(" ")
                                .font(.system(size: 10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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
            outcome: .winner,
            match: match,
            game: game
        )
        modelContext.insert(point)
        try? modelContext.save()
    }
    
    private func decreasePlayerScore(game: Game, match: Match) {
        // Find and remove the most recent point with outcome .winner
        if let points = game.points {
            let winnerPoints = points.filter { $0.outcome == .winner }
            if let lastWinnerPoint = winnerPoints.sorted(by: { $0.timestamp > $1.timestamp }).first {
                modelContext.delete(lastWinnerPoint)
                try? modelContext.save()
            }
        }
    }
    
    private func increaseOpponentScore(game: Game, match: Match) {
        let point = Point(
            strokeTokens: [],
            outcome: .opponentWinner,
            match: match,
            game: game
        )
        modelContext.insert(point)
        try? modelContext.save()
    }
    
    private func decreaseOpponentScore(game: Game, match: Match) {
        // Find and remove the most recent point with outcome .opponentWinner
        if let points = game.points {
            let opponentPoints = points.filter { $0.outcome == .opponentWinner }
            if let lastOpponentPoint = opponentPoints.sorted(by: { $0.timestamp > $1.timestamp }).first {
                modelContext.delete(lastOpponentPoint)
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Point History View (Middle Section)
struct PointHistoryView: View {
    let match: Match?
    let game: Game?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Point History")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 4)
                Spacer()
            }
            
            if let game = game, let points = game.points, !points.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(points.sorted(by: { $0.timestamp > $1.timestamp })), id: \.uniqueID) { point in
                            PointHistoryRow(point: point)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Spacer()
                    Text("No points logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Point History Row
struct PointHistoryRow: View {
    let point: Point
    
    var body: some View {
        HStack(spacing: 12) {
            // Outcome emoji
            Text(point.outcome.emoji)
                .font(.system(size: 24))
                .frame(width: 40)
            
            // Strokes
            if !point.strokeTokens.isEmpty {
                HStack(spacing: 4) {
                    ForEach(point.strokeTokens, id: \.self) { stroke in
                        Text(stroke.emoji)
                            .font(.system(size: 18))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("—")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Outcome name
            Text(point.outcome.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)
            
            // Time
            Text(point.timestamp, style: .time)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            point.outcome == .winner ? Color.green.opacity(0.08) :
            point.outcome == .opponentWinner ? Color.red.opacity(0.08) :
            Color.clear
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// MARK: - Quick Logging View (Bottom Section)
struct QuickLoggingView: View {
    @Binding var currentMatch: Match?
    @Binding var currentGame: Game?
    @Binding var lastPoint: Point?
    @Binding var isVoiceInputActive: Bool
    let onPointLogged: (Point) -> Void
    let onUndo: () -> Void
    
    @State private var currentStrokes: [StrokeToken] = []
    @State private var selectedOutcome: Outcome?
    @State private var showingConfirmation = false
    @State private var confirmationEmoji = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Current strokes indicator
                if !currentStrokes.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(currentStrokes, id: \.self) { stroke in
                            Text(stroke.emoji)
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Stroke buttons row
                HStack(spacing: 8) {
                    ForEach(StrokeToken.allCases, id: \.self) { stroke in
                        Button(action: {
                            addStroke(stroke)
                        }) {
                            VStack(spacing: 2) {
                                Text(stroke.emoji)
                                    .font(.system(size: 24))
                                Text(stroke.displayName)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Outcome buttons (2x2 grid)
                if !currentStrokes.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Outcome.allCases, id: \.self) { outcome in
                            OutcomeButton(
                                outcome: outcome,
                                isSelected: selectedOutcome == outcome
                            ) {
                                selectedOutcome = outcome
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Undo button
                if lastPoint != nil {
                    Button(action: {
                        onUndo()
                        resetInput()
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .onChange(of: selectedOutcome) { _, newValue in
            if let outcome = newValue, !currentStrokes.isEmpty {
                submitPoint(strokes: currentStrokes, outcome: outcome)
            }
        }
        .onChange(of: isVoiceInputActive) { _, isActive in
            if isActive {
                // TODO: Start voice recognition
                simulateVoiceInput()
            }
        }
        .overlay {
            if showingConfirmation {
                ConfirmationOverlay(emoji: confirmationEmoji)
            }
        }
    }
    
    private func addStroke(_ stroke: StrokeToken) {
        currentStrokes.append(stroke)
    }
    
    private func simulateVoiceInput() {
        if currentStrokes.isEmpty {
            currentStrokes.append(.fruit)
        } else if currentStrokes.count == 1 {
            currentStrokes.append(.protein)
        } else {
            resetInput()
            currentStrokes.append(.vegetable)
        }
    }
    
    private func submitPoint(strokes: [StrokeToken], outcome: Outcome) {
        let point = Point(
            strokeTokens: strokes,
            outcome: outcome
        )
        onPointLogged(point)
        
        confirmationEmoji = outcome.emoji
        showingConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInput()
            showingConfirmation = false
        }
    }
    
    private func resetInput() {
        currentStrokes = []
        selectedOutcome = nil
    }
}

// MARK: - Outcome Button
struct OutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(outcome.emoji)
                    .font(.system(size: 28))
                Text(outcome.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confirmation Overlay
struct ConfirmationOverlay: View {
    let emoji: String
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 80))
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview(traits: .portrait) {
    ContentView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}

