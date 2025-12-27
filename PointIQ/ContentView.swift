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
    @AppStorage("pointHistoryHeightRatio") private var pointHistoryHeightRatio: Double = 0.45
    
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

// MARK: - ContentView ends here, components extracted to separate files
// See: ScoreboardView.swift, PointHistoryView.swift, QuickLoggingView.swift, 
//      ButtonComponents.swift, ResizableDivider.swift, ConfirmationOverlay.swift

// MARK: - Scoreboard View (Top Section) - MOVED TO ScoreboardView.swift
/*
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
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.primary)
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
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.primary)
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
            
            // Serve type and strokes
            HStack(spacing: 8) {
                // Serve type shortName
                if let serveTypeString = point.serveType,
                   let serveType = ServeType(rawValue: serveTypeString) {
                    Text(serveType.shortName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
                
                // Strokes (excluding vegetable/serve since we show serve type)
                let displayTokens = point.strokeTokens.filter { $0 != .vegetable }
                if !displayTokens.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(displayTokens, id: \.self) { stroke in
                            Text(stroke.emoji)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
            point.outcome == .myWinner ? Color.green.opacity(0.08) :
            point.outcome == .iMissed ? Color.red.opacity(0.08) :
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
    
    @State private var selectedServe: ServeType?
    @State private var selectedReceive: ReceiveType?
    @State private var selectedRallies: [RallyType] = []
    @State private var selectedOutcome: Outcome?
    @State private var showingConfirmation = false
    @State private var confirmationEmoji = ""
    
    private var isInRallyMode: Bool {
        selectedServe != nil && selectedReceive != nil
    }
    
    // Determine who is serving based on point count (serve switches every 2 points)
    private var isPlayerServing: Bool {
        guard let game = currentGame else { return true } // Default to player serving
        let pointCount = game.pointCount
        // Points 1-2: player serves, Points 3-4: opponent serves, etc.
        return (pointCount % 4) < 2
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if isInRallyMode {
                rallyModeHeader
            } else if selectedServe != nil || selectedReceive != nil {
                serveReceiveHeader
            } else {
                emptyHeader
            }
        }
    }
    
    private var rallyModeHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                if let serve = selectedServe {
                    HStack(spacing: 8) {
                        Text(serve.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                
                Text("→")
                    .foregroundColor(.secondary.opacity(0.5))
                
                if let receive = selectedReceive {
                    HStack(spacing: 8) {
                        Text(receive.displayName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(receive.emoji)
                            .font(.system(size: 24))
                    }
                }
            }
            
            if !selectedRallies.isEmpty {
                HStack(spacing: 12) {
                    Text("Rally:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    ForEach(selectedRallies, id: \.self) { rally in
                        HStack(spacing: 4) {
                            Text(rally.emoji)
                                .font(.system(size: 20))
                            Text(rally.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    Spacer()
                    Button(action: {
                        if !selectedRallies.isEmpty {
                            selectedRallies.removeLast()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: {
                resetInput()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.05))
    }
    
    private var serveReceiveHeader: some View {
        HStack(spacing: 20) {
            if let serve = selectedServe {
                HStack(spacing: 8) {
                    Text(serve.displayName)
                        .font(.system(size: 12, weight: .semibold))
                    Button(action: {
                        selectedServe = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("—")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 12))
            }
            
            Spacer()
            
            if let receive = selectedReceive {
                HStack(spacing: 8) {
                    Button(action: {
                        selectedReceive = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    Text(receive.displayName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(receive.emoji)
                        .font(.system(size: 24))
                }
            } else {
                Text("—")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.05))
    }
    
    private var emptyHeader: some View {
        EmptyView()
    }
    
    private var mainContentView: some View {
        ScrollView {
            if isInRallyMode {
                rallyModeContent
            } else {
                serveReceiveContent
            }
        }
    }
    
    private var rallyModeContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rally")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                
                Text("Select rally strokes (optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(RallyType.allCases, id: \.self) { rallyType in
                        RallyTypeButton(
                            rallyType: rallyType,
                            isSelected: selectedRallies.contains(rallyType)
                        ) {
                            toggleRally(rallyType)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var serveReceiveContent: some View {
        HStack(alignment: .top, spacing: 0) {
            if isPlayerServing {
                // Player is serving: left = serve, right = receive
                serveSection
                Divider()
                    .frame(width: 1)
                receiveSection
            } else {
                // Opponent is serving: left = receive, right = serve
                receiveSection
                Divider()
                    .frame(width: 1)
                serveSection
            }
        }
    }
    
    private var serveSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Serve")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(ServeType.allCases, id: \.self) { serveType in
                    ServeTypeButton(
                        serveType: serveType,
                        isSelected: selectedServe == serveType,
                        onTap: {
                            selectedServe = serveType
                        },
                        onDoubleTap: {
                            submitAceServe(serve: serveType)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.03))
    }
    
    private var receiveSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Receive")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(ReceiveType.allCases, id: \.self) { receiveType in
                    ReceiveTypeButton(
                        receiveType: receiveType,
                        isSelected: selectedReceive == receiveType,
                        onTap: {
                            selectedReceive = receiveType
                        },
                        onDoubleTap: {
                            submitGoodReceive(receive: receiveType)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.03))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            mainContentView
            Divider()
            outcomesRow
        }
        .onChange(of: selectedOutcome) { _, newValue in
            if let outcome = newValue {
                // Outcome selection directly ends the point
                if let serve = selectedServe, let receive = selectedReceive {
                    // If serve and receive are selected, include them
                    submitPoint(serve: serve, receive: receive, rallies: selectedRallies, outcome: outcome)
                } else {
                    // Direct outcome selection without serve/receive
                    submitDirectOutcome(outcome: outcome)
                }
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
    
    private var outcomesRow: some View {
        HStack(spacing: 8) {
            ForEach(Outcome.allCases, id: \.self) { outcome in
                OutcomeButton(
                    outcome: outcome,
                    isSelected: selectedOutcome == outcome
                ) {
                    selectedOutcome = outcome
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 40) // Extra padding to account for tab bar
        .background(Color.secondary.opacity(0.05))
    }
    
    private func toggleRally(_ rally: RallyType) {
        if let index = selectedRallies.firstIndex(of: rally) {
            selectedRallies.remove(at: index)
        } else {
            selectedRallies.append(rally)
        }
    }
    
    private func simulateVoiceInput() {
        // Simulate selecting a serve and receive
        if selectedServe == nil {
            selectedServe = ServeType.allCases.randomElement()
        } else if selectedReceive == nil {
            selectedReceive = ReceiveType.allCases.randomElement()
        } else if selectedRallies.isEmpty {
            selectedRallies.append(RallyType.allCases.randomElement()!)
        } else {
            resetInput()
        }
    }
    
    private func submitAceServe(serve: ServeType) {
        // Ace serve: only serve token, no receive, point won immediately
        // If player is serving: point goes to player (.myWinner)
        // If opponent is serving: point goes to opponent (.iMissed)
        let outcome: Outcome = isPlayerServing ? .myWinner : .iMissed
        let point = Point(
            strokeTokens: [.vegetable], // Only serve
            outcome: outcome,
            serveType: serve.rawValue
        )
        onPointLogged(point)
        
        confirmationEmoji = outcome.emoji
        showingConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInput()
            showingConfirmation = false
        }
    }
    
    private func submitGoodReceive(receive: ReceiveType) {
        // Good receive: receive token only, point won immediately by whoever is receiving
        // If player is receiving (opponent is serving): point goes to player (.myWinner)
        // If opponent is receiving (player is serving): point goes to opponent (.iMissed)
        let outcome: Outcome = isPlayerServing ? .iMissed : .myWinner
        let point = Point(
            strokeTokens: [.fruit], // Only receive
            outcome: outcome,
            serveType: nil
        )
        onPointLogged(point)
        
        confirmationEmoji = outcome.emoji
        showingConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInput()
            showingConfirmation = false
        }
    }
    
    private func submitDirectOutcome(outcome: Outcome) {
        // Direct outcome selection - point ends immediately
        // Store original outcome for analytics, Game.swift handles scoring correctly
        let point = Point(
            strokeTokens: [], // No strokes for direct outcome
            outcome: outcome,
            serveType: nil
        )
        onPointLogged(point)
        
        confirmationEmoji = outcome.emoji
        showingConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInput()
            showingConfirmation = false
        }
    }
    
    private func submitPoint(serve: ServeType, receive: ReceiveType, rallies: [RallyType], outcome: Outcome) {
        // Map serve to vegetable token, receive to fruit token, and rallies to animal tokens
        var strokeTokens: [StrokeToken] = [.vegetable, .fruit] // Serve then receive
        strokeTokens.append(contentsOf: Array(repeating: .animal, count: rallies.count)) // Add rally tokens
        
        // Store original outcome - Game.swift handles scoring correctly
        let point = Point(
            strokeTokens: strokeTokens,
            outcome: outcome,
            serveType: serve.rawValue
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
        selectedServe = nil
        selectedReceive = nil
        selectedRallies = []
        selectedOutcome = nil
    }
}

// MARK: - Serve Type Button
struct ServeTypeButton: View {
    let serveType: ServeType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 6) {
            Text(serveType.shortName)
                .font(.system(size: 20, weight: .bold))
            Text(serveType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(12)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    // Double tap - ace serve
                    tapTask?.cancel()
                    onDoubleTap()
                }
        )
        .onTapGesture {
            // Single tap - select serve (with delay to detect double tap)
            tapTask?.cancel()
            let task = DispatchWorkItem {
                onTap()
            }
            tapTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
}

// MARK: - Receive Type Button
struct ReceiveTypeButton: View {
    let receiveType: ReceiveType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 6) {
            Text(receiveType.emoji)
                .font(.system(size: 20))
            Text(receiveType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(12)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    // Double tap - good receive scoring point
                    tapTask?.cancel()
                    onDoubleTap()
                }
        )
        .onTapGesture {
            // Single tap - select receive (with delay to detect double tap)
            tapTask?.cancel()
            let task = DispatchWorkItem {
                onTap()
            }
            tapTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
}

// MARK: - Rally Type Button
struct RallyTypeButton: View {
    let rallyType: RallyType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(rallyType.emoji)
                    .font(.system(size: 20))
                Text(rallyType.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(12)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
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

// MARK: - Outcome Button
struct OutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(outcome.emoji)
                    .font(.system(size: 20))
                Text(outcome.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(12)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
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

// MARK: - Resizable Divider
struct ResizableDivider: View {
    @Binding var heightRatio: Double
    let totalHeight: CGFloat
    let topSectionHeight: CGFloat
    
    @State private var isDragging = false
    @State private var initialRatio: Double = 0.45
    
    private let minRatio: Double = 0.15
    private let maxRatio: Double = 0.70
    
    var body: some View {
        ZStack {
            Divider()
            
            // Drag handle
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDragging ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 60, height: 8)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .background(Color.secondary.opacity(isDragging ? 0.15 : 0.05))
        .contentShape(Rectangle())
        .frame(height: 24)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        initialRatio = heightRatio
                    }
                    
                    // Calculate new ratio based on drag distance
                    let dragDelta = value.translation.height
                    let deltaRatio = dragDelta / totalHeight
                    let newRatio = initialRatio - deltaRatio
                    
                    // Clamp the ratio between min and max
                    let clampedRatio = max(minRatio, min(maxRatio, newRatio))
                    heightRatio = clampedRatio
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
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
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}

