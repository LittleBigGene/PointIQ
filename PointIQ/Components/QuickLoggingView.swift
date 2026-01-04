//
//  QuickLoggingView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

// MARK: - Quick Logging View (Bottom Section)
struct QuickLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var currentMatch: Match?
    @Binding var currentGame: Game?
    @Binding var lastPoint: Point?
    @Binding var isVoiceInputActive: Bool
    let pointHistoryHeightRatio: Double
    @Binding var manualSwapOverride: Bool
    let onPointLogged: (Point) -> Void
    let onUndo: () -> Void
    
    @State private var selectedServe: ServeType?
    @State private var selectedReceive: ReceiveType?
    @State private var selectedRallies: [RallyType] = []
    @State private var selectedOutcome: Outcome?
    @State private var showingConfirmation = false
    @State private var confirmationEmoji = ""
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    @AppStorage("legendMode") private var isPostGameMode: Bool = true
    @AppStorage("playerHandedness") private var playerHandedness: String = "Right-handed"
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // MARK: - Translation Helpers
    
    private func serveText(for language: Language) -> String {
        switch language {
        case .english: return "Serve"
        case .japanese: return "サーブ"
        case .chinese: return "發球"
        }
    }
    
    private func receiveText(for language: Language) -> String {
        switch language {
        case .english: return "Receive"
        case .japanese: return "レシーブ"
        case .chinese: return "接球"
        }
    }
    
    private func forehandText(for language: Language) -> String {
        switch language {
        case .english: return "Forehand"
        case .japanese: return "フォアハンド"
        case .chinese: return "正手"
        }
    }
    
    private func backhandText(for language: Language) -> String {
        switch language {
        case .english: return "Backhand"
        case .japanese: return "バックハンド"
        case .chinese: return "反手"
        }
    }
    
    // MARK: - Computed Properties
    
    private var isInRallyMode: Bool {
        selectedServe != nil && selectedReceive != nil
    }
    
    private var isPlayerServing: Bool {
        currentGame?.isPlayerServingNext ?? true
    }
    
    private var shouldSwapPlayers: Bool {
        guard let game = currentGame else { return false }
        return GameSideSwap.shouldSwapPlayers(gameNumber: game.gameNumber, manualSwapOverride: manualSwapOverride)
    }
    
    private var shouldHideOutcomes: Bool {
        pointHistoryHeightRatio > 0.55
    }
    
    private var orderedOutcomes: [Outcome] {
        shouldSwapPlayers ? Outcome.allCases.reversed() : Outcome.allCases
    }
    
    private var inGameOrderedOutcomes: [Outcome] {
        Outcome.allCases.filter { $0 != .opponentError && $0 != .myError }
    }
    
    // MARK: - Point Submission
    
    private func submitAceServe(serve: ServeType) {
        let outcome: Outcome = isPlayerServing ? .myWinner : .iMissed
        let point = Point(
            strokeTokens: [serve.rawValue],
            outcome: outcome,
            serveType: serve.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitServeOnlyPoint(serve: ServeType, outcome: Outcome) {
        let point = Point(
            strokeTokens: [serve.rawValue],
            outcome: outcome,
            serveType: serve.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitGoodReceive(receive: ReceiveType) {
        let outcome: Outcome = isPlayerServing ? .iMissed : .myWinner
        let point = Point(
            strokeTokens: [receive.fruitName],
            outcome: outcome,
            serveType: nil,
            receiveType: receive.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitDirectOutcome(outcome: Outcome, strokeSide: StrokeSide? = nil) {
        var strokeTokens: [String] = []
        if let side = strokeSide {
            strokeTokens.append("\(outcome.displayName(for: selectedLanguage)) (\(side.displayName))")
        }
        
        let point = Point(
            strokeTokens: strokeTokens,
            outcome: outcome,
            serveType: nil
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitPoint(serve: ServeType, receive: ReceiveType, rallies: [RallyType], outcome: Outcome) {
        var strokeTokens: [String] = [serve.rawValue, receive.fruitName]
        strokeTokens.append(contentsOf: rallies.map { $0.animalName })
        
        let point = Point(
            strokeTokens: strokeTokens,
            outcome: outcome,
            serveType: serve.rawValue,
            receiveType: receive.rawValue,
            rallyTypes: rallies.map { $0.rawValue }
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    // MARK: - Point Counting
    
    /// Counts points by stroke side for a given outcome
    /// Only counts points that have stroke side information (logged with drag gestures)
    private func countPointsBySide(outcome: Outcome) -> (forehand: Int, backhand: Int) {
        guard let game = currentGame, let points = game.points else {
            return (0, 0)
        }
        
        var forehandCount = 0
        var backhandCount = 0
        
        for point in points where point.outcome == outcome {
            for token in point.strokeTokens {
                if token.contains("(Forehand)") {
                    forehandCount += 1
                    break
                } else if token.contains("(Backhand)") {
                    backhandCount += 1
                    break
                }
            }
        }
        
        return (forehandCount, backhandCount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            Divider()
            if isPostGameMode {
                mainContentView
                if !shouldHideOutcomes {
                    Divider()
                    outcomesRow
                }
            } else {
                // In-game mode: outcomes fill the screen
                inGameOutcomesView
            }
        }
        .onChange(of: selectedOutcome) { _, newValue in
            if let outcome = newValue {
                // Outcome selection directly ends the point
                if let serve = selectedServe, let receive = selectedReceive {
                    // If serve and receive are selected, include them
                    submitPoint(serve: serve, receive: receive, rallies: selectedRallies, outcome: outcome)
                } else if let serve = selectedServe {
                    // Serve-only point: serve selected then outcome selected (e.g., serve + "Error", serve + "Cho-le")
                    submitServeOnlyPoint(serve: serve, outcome: outcome)
                } else {
                    // Direct outcome selection without serve/receive
                    submitDirectOutcome(outcome: outcome)
                }
            }
        }
        .onChange(of: isPostGameMode) { _, newValue in
            // Reset selected strokes when switching to in-game mode
            if !newValue {
                resetInput()
            }
        }
        .id(currentGame?.pointCount ?? 0) // Force view update when points are added (for counter updates)
        .onChange(of: isVoiceInputActive) { _, isActive in
            if isActive {
                simulateVoiceInput()
            }
        }
        .overlay {
            if showingConfirmation {
                ConfirmationOverlay(emoji: confirmationEmoji)
            }
        }
    }
    
    private var hasSelection: Bool {
        selectedServe != nil || selectedReceive != nil || !selectedRallies.isEmpty
    }
    
    private var rightSideServes: Bool {
        shouldSwapPlayers ? isPlayerServing : !isPlayerServing
    }
    
    private var placeholderText: (left: String, right: String) {
        // Left side serves when: not swapped and player serves, OR swapped and opponent serves
        let leftIsServing = shouldSwapPlayers ? !isPlayerServing : isPlayerServing
        let serve = serveText(for: selectedLanguage)
        let receive = receiveText(for: selectedLanguage)
        return leftIsServing ? (serve, receive) : (receive, serve)
    }
    
    private var inGamePlaceholderText: (left: String, right: String) {
        // For in-game mode: show Forehand/Backhand based on player handedness
        let isRightHanded = playerHandedness == "Right-handed"
        let forehand = forehandText(for: selectedLanguage)
        let backhand = backhandText(for: selectedLanguage)
        
        // Right-handed: Left = Backhand, Right = Forehand
        // Left-handed: Left = Forehand, Right = Backhand
        return isRightHanded ? (backhand, forehand) : (forehand, backhand)
    }
    
    @ViewBuilder
    private var previewHeader: some View {
        // In in-game mode, show Forehand/Backhand labels with undo button
        if !isPostGameMode {
            HStack {
                Text(inGamePlaceholderText.left)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Undo button in center
                if lastPoint != nil {
                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                    }
                } else {
                    // Placeholder to maintain spacing
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                }
                
                Spacer()
                
                Text(inGamePlaceholderText.right)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.05))
        } else {
            // Calculate dynamic spacer width: start with 13 emojis, reduce by 1 for each selected stroke
            let emojiWidth: CGFloat = 18
            let emojiSpacing: CGFloat = 6
            
            let strokeCount = (selectedServe != nil ? 1 : 0) + 
                             (selectedReceive != nil ? 1 : 0) + 
                             selectedRallies.count
            let emojiCount = max(0, 13 - strokeCount) // Minimum 0
            let dynamicSpacerWidth = (emojiWidth * CGFloat(emojiCount)) + (emojiSpacing * CGFloat(max(0, emojiCount - 1)))
            
            HStack(spacing: 12) {
                // Reset button on left when reversed
                if hasSelection && rightSideServes {
                    Button(action: resetInput) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                
                if hasSelection {
                    if rightSideServes {
                        // In reverse mode, add spacer to push content to the right (reduces as strokes are added)
                        Spacer()
                            .frame(width: dynamicSpacerWidth)
                    }
                    
                    StrokeSequenceView(
                        serve: selectedServe,
                        receive: selectedReceive,
                        rallies: selectedRallies,
                        onRallyTap: { index in
                            if index < selectedRallies.count {
                                selectedRallies.removeSubrange(index..<selectedRallies.count)
                            }
                        },
                        reverseOrder: rightSideServes
                    )
                    .frame(maxWidth: .infinity, alignment: rightSideServes ? .trailing : .leading)
                } else {
                    HStack {
                        Text(placeholderText.left)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(placeholderText.right)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Reset button on right when not reversed
                if hasSelection && !rightSideServes {
                    Button(action: resetInput) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)            
            .background(Color.secondary.opacity(0.05))
            .contentShape(Rectangle())
            .onTapGesture {
                // Flip serving order only if game has no points and no current selection
                if let game = currentGame, game.pointCount == 0, !hasSelection {
                    game.playerServesFirst.toggle()
                    try? modelContext.save()
                }
            }
        }
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
    
    // MARK: - Rally Mode
    
    private var nextRallyHitterSide: HorizontalAlignment {
        // After serve+receive, rallies alternate: server, non-server, server, etc.
        let isServerHitting = selectedRallies.count % 2 == 0
        let leftIsServing = shouldSwapPlayers ? !isPlayerServing : isPlayerServing
        
        if isServerHitting {
            return leftIsServing ? .leading : .trailing
        } else {
            return leftIsServing ? .trailing : .leading
        }
    }
    
    private var rallyModeContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                let totalCount = (selectedServe != nil ? 1 : 0) + (selectedReceive != nil ? 1 : 0) + selectedRallies.count
                ZStack {
                    // Rally count centered when exceeding max
                    if totalCount > 10 {
                        Text("\(selectedRallies.count) rallies")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Animated ball that moves based on who hits next
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 20, height: 20)
                            .frame(maxWidth: .infinity, alignment: nextRallyHitterSide == .leading ? .leading : .trailing)
                            .animation(.easeInOut(duration: 0.3), value: selectedRallies.count)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)                
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(RallyType.allCases, id: \.self) { rallyType in
                        RallyTypeButton(
                            rallyType: rallyType,
                            isSelected: false
                        ) {
                            addRally(rallyType)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var serveReceiveContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left side serves when: not swapped and player serves, OR swapped and opponent serves
            let leftIsServing = shouldSwapPlayers ? !isPlayerServing : isPlayerServing
            if leftIsServing {
                // Left side is serving: left = serve, right = receive
                serveSection
                Divider()
                    .frame(width: 1)
                receiveSection
            } else {
                // Right side is serving: left = receive, right = serve
                receiveSection
                Divider()
                    .frame(width: 1)
                serveSection
            }
        }
        .padding(.top, -12)
    }
    
    // MARK: - Post-Game Content Views
    
    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }
    
    private var serveSection: some View {
        VStack(alignment: .center, spacing: 0) {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(ServeType.allCases, id: \.self) { serveType in
                    ServeTypeButton(
                        serveType: serveType,
                        isSelected: selectedServe == serveType,
                        onTap: {
                            if selectedServe == nil {
                                selectedServe = serveType
                            }
                        },
                        onDoubleTap: {
                            submitAceServe(serve: serveType)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .background(Color.secondary.opacity(0.03))
    }
    
    private var receiveSection: some View {
        VStack(alignment: .center, spacing: 0) {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(ReceiveType.allCases, id: \.self) { receiveType in
                    ReceiveTypeButton(
                        receiveType: receiveType,
                        isSelected: selectedReceive == receiveType,
                        onTap: {
                            // Can only select receive if serve is already selected
                            if selectedServe != nil && selectedReceive == nil {
                                selectedReceive = receiveType
                            }
                        },
                        onDoubleTap: {
                            // Double tap only works if serve is selected
                            if selectedServe != nil {
                                submitGoodReceive(receive: receiveType)
                            }
                        }
                    )
                    .disabled(selectedServe == nil)
                    .opacity(selectedServe == nil ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .background(Color.secondary.opacity(0.03))
    }
    
    // MARK: - Post-Game Outcomes View
    
    private var outcomesRow: some View {
        LazyVGrid(columns: outcomeGridColumns, spacing: 8) {
            ForEach(orderedOutcomes, id: \.self) { outcome in
                PostGameOutcomeButton(
                    outcome: outcome,
                    isSelected: selectedOutcome == outcome
                ) {
                    selectedOutcome = outcome
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 40)
        .background(Color.secondary.opacity(0.05))
    }
    
    private var outcomeGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(minimum: 120), spacing: 8), // Wider middle column
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    // MARK: - In-Game Outcomes View
    
    private var inGameOutcomesView: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(inGameOrderedOutcomes, id: \.self) { outcome in
                    inGameOutcomeButtonView(for: outcome)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color.secondary.opacity(0.05))
    }
    
    @ViewBuilder
    private func inGameOutcomeButtonView(for outcome: Outcome) -> some View {
        if outcome == .myWinner || outcome == .iMissed {
            // Add counters for Cho-le and Missed
            let counts = countPointsBySide(outcome: outcome)
            HStack(spacing: 8) {
                strokeSideCounter(count: counts.backhand)
                
                inGameOutcomeButton(for: outcome)
                    .frame(maxWidth: 200)
                
                strokeSideCounter(count: counts.forehand)
            }
        } else {
            inGameOutcomeButton(for: outcome)
                .frame(maxWidth: 200)
        }
    }
    
    private func inGameOutcomeButton(for outcome: Outcome) -> some View {
        InGameOutcomeButton(
            outcome: outcome,
            isSelected: selectedOutcome == outcome,
            onTap: {
                selectedOutcome = outcome
            },
            onDrag: { strokeSide in
                submitDirectOutcome(outcome: outcome, strokeSide: strokeSide)
            }
        )
    }
    
    private func strokeSideCounter(count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(minWidth: 24)
    }
    
    // MARK: - Helper Methods
    
    private func addRally(_ rally: RallyType) {
        selectedRallies.append(rally)
    }
    
    private func simulateVoiceInput() {
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
    
    private func showConfirmation(emoji: String) {
        confirmationEmoji = emoji
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

