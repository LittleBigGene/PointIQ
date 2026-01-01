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
    
    private var isInRallyMode: Bool {
        selectedServe != nil && selectedReceive != nil
    }
    
    // Determine who is serving for the NEXT point
    private var isPlayerServing: Bool {
        currentGame?.isPlayerServingNext ?? true // Default to player serving
    }
    
    // Determine if players should be swapped (combines automatic and manual override)
    private var shouldSwapPlayers: Bool {
        guard let game = currentGame else { return false }
        return GameSideSwap.shouldSwapPlayers(gameNumber: game.gameNumber, manualSwapOverride: manualSwapOverride)
    }
    
    // Hide outcomes when point history is tall (above 0.55)
    private var shouldHideOutcomes: Bool {
        pointHistoryHeightRatio > 0.55
    }
    
    // Outcomes in correct order based on side swap (reversed when swapped to keep colors consistent)
    private var orderedOutcomes: [Outcome] {
        shouldSwapPlayers ? Outcome.allCases.reversed() : Outcome.allCases
    }
    
    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            Divider()
            mainContentView
            if !shouldHideOutcomes {
                Divider()
                outcomesRow
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
    
    private var hasSelection: Bool {
        selectedServe != nil || selectedReceive != nil || !selectedRallies.isEmpty
    }
    
    // MARK: - Preview Header Logic
    
    /// Determines if the right side is serving (opponent when not swapped, player when swapped)
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
    
    private var previewHeader: some View {
        // Calculate dynamic spacer width: start with 13 emojis, reduce by 1 for each selected stroke
        let emojiWidth: CGFloat = 18
        let emojiSpacing: CGFloat = 6
        
        let strokeCount = (selectedServe != nil ? 1 : 0) + 
                         (selectedReceive != nil ? 1 : 0) + 
                         selectedRallies.count
        let emojiCount = max(0, 13 - strokeCount) // Minimum 0
        let dynamicSpacerWidth = (emojiWidth * CGFloat(emojiCount)) + (emojiSpacing * CGFloat(max(0, emojiCount - 1)))
        
        return HStack(spacing: 12) {
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
    
    private var mainContentView: some View {
        ScrollView {
            if isInRallyMode {
                rallyModeContent
            } else {
                serveReceiveContent
            }
        }
    }
    
    /// Determines which side (left/right) the next rally hitter is on
    private var nextRallyHitterSide: HorizontalAlignment {
        // After serve+receive, rallies start with the server:
        // Rally 1: server hits (person who served)
        // Rally 2: non-server hits (person who received)
        // Rally 3: server hits
        // etc.
        // So: even count (0, 2, 4...) = server hits next, odd count (1, 3, 5...) = non-server hits next
        
        let isServerHitting = selectedRallies.count % 2 == 0
        let leftIsServing = shouldSwapPlayers ? !isPlayerServing : isPlayerServing
        
        if isServerHitting {
            // Server hits next - same side as server
            return leftIsServing ? .leading : .trailing
        } else {
            // Non-server hits next - opposite side of server
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
    
    private var outcomesRow: some View {
        HStack(spacing: 8) {
            ForEach(orderedOutcomes, id: \.self) { outcome in
                OutcomeButton(
                    outcome: outcome,
                    isSelected: selectedOutcome == outcome
                ) {
                    selectedOutcome = outcome
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 40) // Extra padding to account for tab bar
        .background(Color.secondary.opacity(0.05))
    }
    
    private func addRally(_ rally: RallyType) {
        // Always append the rally type to allow continuous rally selection
        selectedRallies.append(rally)
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
    
    private func showConfirmation(emoji: String) {
        confirmationEmoji = emoji
        showingConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInput()
            showingConfirmation = false
        }
    }
    
    private func submitAceServe(serve: ServeType) {
        // Double-tap serve: whoever is serving gets the point (ace serve)
        let outcome: Outcome = isPlayerServing ? .myWinner : .iMissed
        let point = Point(
            strokeTokens: [.vegetable], // Only serve
            outcome: outcome,
            serveType: serve.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitServeOnlyPoint(serve: ServeType, outcome: Outcome) {
        // Serve-only point: serve selected then outcome selected (records serve in history)
        let point = Point(
            strokeTokens: [.vegetable], // Only serve
            outcome: outcome,
            serveType: serve.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitGoodReceive(receive: ReceiveType) {
        // Good receive: receive token only, point won immediately by whoever is receiving
        // If player is receiving (opponent is serving): point goes to player (.myWinner)
        // If opponent is receiving (player is serving): point goes to opponent (.iMissed)
        let outcome: Outcome = isPlayerServing ? .iMissed : .myWinner
        let point = Point(
            strokeTokens: [.fruit], // Only receive
            outcome: outcome,
            serveType: nil,
            receiveType: receive.rawValue
        )
        onPointLogged(point)
        showConfirmation(emoji: outcome.emoji)
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
        showConfirmation(emoji: outcome.emoji)
    }
    
    private func submitPoint(serve: ServeType, receive: ReceiveType, rallies: [RallyType], outcome: Outcome) {
        // Map serve to vegetable token, receive to fruit token, and rallies to animal tokens
        var strokeTokens: [StrokeToken] = [.vegetable, .fruit] // Serve then receive
        strokeTokens.append(contentsOf: Array(repeating: .animal, count: rallies.count)) // Add rally tokens
        
        // Store original outcome - Game.swift handles scoring correctly
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
    
    private func resetInput() {
        selectedServe = nil
        selectedReceive = nil
        selectedRallies = []
        selectedOutcome = nil
    }
}

