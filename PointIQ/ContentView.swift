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
    @State private var lastPoint: Point?
    @State private var showingVoiceInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Active match header
                if let match = currentMatch {
                    MatchHeaderView(match: match)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                }
                
                // Main point logging area
                PointLoggingView(
                    currentMatch: $currentMatch,
                    lastPoint: $lastPoint,
                    onPointLogged: { point in
                        logPoint(point)
                    },
                    onUndo: {
                        undoLastPoint()
                    }
                )
                
                // Recent points list
                if let match = currentMatch, let points = match.points, !points.isEmpty {
                    Divider()
                    RecentPointsView(points: Array(points.suffix(10)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("PointIQ")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if currentMatch == nil {
                            Button("New Match") {
                                startNewMatch()
                            }
                        } else {
                            Button("End Match") {
                                endCurrentMatch()
                            }
                        }
                        Button("Match History") {
                            // TODO: Show match history
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Menu {
                        if currentMatch == nil {
                            Button("New Match") {
                                startNewMatch()
                            }
                        } else {
                            Button("End Match") {
                                endCurrentMatch()
                            }
                        }
                        Button("Match History") {
                            // TODO: Show match history
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
        }
        .onAppear {
            // Start a new match if none exists
            if currentMatch == nil {
                startNewMatch()
            }
        }
    }
    
    private func startNewMatch() {
        let newMatch = Match()
        modelContext.insert(newMatch)
        currentMatch = newMatch
        try? modelContext.save()
    }
    
    private func endCurrentMatch() {
        currentMatch?.endDate = Date()
        currentMatch = nil
        try? modelContext.save()
    }
    
    private func logPoint(_ point: Point) {
        guard let match = currentMatch else { return }
        point.match = match
        modelContext.insert(point)
        lastPoint = point
        try? modelContext.save()
    }
    
    private func undoLastPoint() {
        guard let point = lastPoint else { return }
        modelContext.delete(point)
        lastPoint = nil
        try? modelContext.save()
    }
}

// MARK: - Match Header View
struct MatchHeaderView: View {
    let match: Match
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Match")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let opponent = match.opponentName {
                    Text(opponent)
                        .font(.headline)
                } else {
                    Text("No opponent")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(match.pointCount)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - Point Logging View
struct PointLoggingView: View {
    @Binding var currentMatch: Match?
    @Binding var lastPoint: Point?
    let onPointLogged: (Point) -> Void
    let onUndo: () -> Void
    
    @State private var currentStrokes: [StrokeToken] = []
    @State private var selectedOutcome: Outcome?
    @State private var showingConfirmation = false
    @State private var confirmationEmoji = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                // Current strokes display
                if !currentStrokes.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(currentStrokes, id: \.self) { stroke in
                            Text(stroke.emoji)
                                .font(.system(size: 40))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Outcome selection
                if !currentStrokes.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
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
                
                // Voice input button (placeholder)
                VoiceInputButton {
                    // TODO: Implement voice recognition
                    // For now, simulate with manual input
                    simulateVoiceInput()
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Undo button
                if lastPoint != nil {
                    Button(action: {
                        onUndo()
                        resetInput()
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo Last Point")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .onChange(of: selectedOutcome) { _, newValue in
            if let outcome = newValue, !currentStrokes.isEmpty {
                submitPoint(strokes: currentStrokes, outcome: outcome)
            }
        }
        .overlay {
            if showingConfirmation {
                ConfirmationOverlay(emoji: confirmationEmoji)
            }
        }
    }
    
    private func simulateVoiceInput() {
        // Simulate voice input - in real implementation, this will come from voice recognition
        // For MVP: cycle through stroke types
        if currentStrokes.isEmpty {
            currentStrokes.append(.fruit) // Start with backhand
        } else if currentStrokes.count == 1 {
            currentStrokes.append(.protein) // Add forehand
        } else {
            // Reset and start new point
            resetInput()
            currentStrokes.append(.vegetable) // Serve
        }
    }
    
    private func submitPoint(strokes: [StrokeToken], outcome: Outcome) {
        let point = Point(
            strokeTokens: strokes,
            outcome: outcome
        )
        onPointLogged(point)
        
        // Show confirmation
        confirmationEmoji = outcome.emoji
        showingConfirmation = true
        
        // Reset after brief delay
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
            VStack(spacing: 8) {
                Text(outcome.emoji)
                    .font(.system(size: 32))
                Text(outcome.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Voice Input Button
struct VoiceInputButton: View {
    let action: () -> Void
    @State private var isRecording = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.title2)
                Text(isRecording ? "Recording..." : "Voice Input")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isRecording = true
                }
                .onEnded { _ in
                    isRecording = false
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

// MARK: - Recent Points View
struct RecentPointsView: View {
    let points: [Point]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Points")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(points.reversed(), id: \.id) { point in
                        PointCard(point: point)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Point Card
struct PointCard: View {
    let point: Point
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(point.strokeTokens, id: \.self) { stroke in
                    Text(stroke.emoji)
                        .font(.caption)
                }
            }
            Text(point.outcome.emoji)
                .font(.title3)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Point.self], inMemory: true)
        .previewDevice("iPhone 14")
        .previewDisplayName("iPhone 14")
        .previewInterfaceOrientation(.portrait)
}
