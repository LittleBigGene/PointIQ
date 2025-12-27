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

