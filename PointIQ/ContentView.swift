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
    @State private var currentMatch: Match?
    @State private var currentGame: Game?
    @State private var lastPoint: Point?
    @State private var isVoiceInputActive = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top Section: Official Scoreboard
                    ScoreboardView(
                        match: currentMatch,
                        game: currentGame
                    )
                    .frame(height: geometry.size.height * 0.35)
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
                    .frame(height: geometry.size.height * 0.30)
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
            // Start a new match if none exists
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
        
        // Check if match is complete
        if match.isComplete {
            endCurrentMatch()
        }
    }
    
    private func endCurrentGame() {
        guard let game = currentGame else { return }
        game.endDate = Date()
        currentGame = nil
        
        // Automatically start a new game if match is not complete
        if let match = currentMatch, !match.isComplete {
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
}

// MARK: - Scoreboard View (Top Section)
struct ScoreboardView: View {
    let match: Match?
    let game: Game?
    
    var body: some View {
        VStack(spacing: 0) {
            if let match = match, let game = game {
                // Match Score Header
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("MATCH")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        HStack(spacing: 20) {
                            // Player Games
                            VStack(spacing: 2) {
                                Text("YOU")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(match.gamesWon)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(match.isComplete && match.winner == true ? .green : .primary)
                            }
                            
                            Text(":")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.secondary)
                            
                            // Opponent Games
                            VStack(spacing: 2) {
                                Text("OPP")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(match.gamesLost)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(match.isComplete && match.winner == false ? .red : .primary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1))
                
                Divider()
                
                // Current Game Score
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("GAME \(game.gameNumber)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 30) {
                            // Player Points
                            VStack(spacing: 2) {
                                Text("YOU")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(game.pointsWon)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(game.isComplete && game.winner == true ? .green : .primary)
                            }
                            
                            Text(":")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.secondary)
                            
                            // Opponent Points
                            VStack(spacing: 2) {
                                Text("OPP")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(game.pointsLost)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(game.isComplete && game.winner == false ? .red : .primary)
                            }
                        }
                        
                        // Status indicator
                        if game.isComplete {
                            Text(game.winner == true ? "GAME WON" : "GAME LOST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(game.winner == true ? .green : .red)
                                .padding(.top, 4)
                        } else if game.isDeuce {
                            Text("DEUCE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        } else {
                            let status = game.statusMessage
                            if status == "Game Point" {
                                Text("GAME POINT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                
                // Opponent name if set
                if let opponent = match.opponentName {
                    Text(opponent.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
}

// MARK: - Point History View (Middle Section)
struct PointHistoryView: View {
    let match: Match?
    let game: Game?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Point History")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Spacer()
            }
            
            if let game = game, let points = game.points, !points.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(points.reversed()), id: \.id) { point in
                            PointHistoryCard(point: point)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                HStack {
                    Spacer()
                    Text("No points logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Point History Card
struct PointHistoryCard: View {
    let point: Point
    
    var body: some View {
        VStack(spacing: 6) {
            // Strokes
            HStack(spacing: 4) {
                ForEach(point.strokeTokens, id: \.self) { stroke in
                    Text(stroke.emoji)
                        .font(.system(size: 16))
                }
            }
            
            // Outcome
            Text(point.outcome.emoji)
                .font(.system(size: 24))
            
            // Time
            Text(point.timestamp, style: .time)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(width: 70)
        .background(
            point.outcome == .winner ? Color.green.opacity(0.15) :
            point.outcome == .opponentWinner ? Color.red.opacity(0.15) :
            Color.secondary.opacity(0.1)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    point.outcome == .winner ? Color.green.opacity(0.3) :
                    point.outcome == .opponentWinner ? Color.red.opacity(0.3) :
                    Color.clear,
                    lineWidth: 1
                )
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
