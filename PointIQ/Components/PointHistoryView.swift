//
//  PointHistoryView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

// MARK: - Point History View (Middle Section)
struct PointHistoryView: View {
    let match: Match?
    let game: Game?
    
    @State private var storedPoints: [PointData] = []
    
    // MARK: - Point Collection
    
    /// Collects all points from SwiftData (preferred) or stored points (fallback)
    private var allPoints: [PointInfo] {
        var points: [PointInfo] = []
        var seenIDs = Set<String>()
        
        // Prioritize SwiftData points (source of truth)
        if let swiftDataPoints = collectSwiftDataPoints() {
            for pointInfo in swiftDataPoints {
                if !seenIDs.contains(pointInfo.id) {
                    points.append(pointInfo)
                    seenIDs.insert(pointInfo.id)
                }
            }
        }
        
        // Only use stored points if SwiftData has no points (edge case handling)
        if points.isEmpty {
            for pointData in storedPoints {
                if !seenIDs.contains(pointData.id) {
                    points.append(PointInfo(
                        id: pointData.id,
                        timestamp: pointData.timestamp,
                        isStored: true,
                        gameNumber: pointData.gameNumber ?? 1
                    ))
                    seenIDs.insert(pointData.id)
                }
            }
        }
        
        return points.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Collects points from SwiftData
    private func collectSwiftDataPoints() -> [PointInfo]? {
        guard let match = match, let games = match.games else { return nil }
        
        var points: [PointInfo] = []
        for game in games.sorted(by: { $0.gameNumber < $1.gameNumber }) {
            guard let gamePoints = game.points else { continue }
            for point in gamePoints {
                points.append(PointInfo(
                    id: point.uniqueID,
                    timestamp: point.timestamp,
                    isStored: false,
                    gameNumber: game.gameNumber
                ))
            }
        }
        return points.isEmpty ? nil : points
    }
    
    /// Validates that points still exist in their source
    private var validPoints: [PointInfo] {
        allPoints.filter { pointInfo in
            if pointInfo.isStored {
                return storedPoints.contains { $0.id == pointInfo.id }
            } else {
                return match?.games?.contains { game in
                    game.gameNumber == pointInfo.gameNumber &&
                    game.points?.contains(where: { $0.uniqueID == pointInfo.id }) ?? false
                } ?? false
            }
        }
    }
    
    /// Groups points by game number
    private var pointsByGame: [Int: [PointInfo]] {
        Dictionary(grouping: validPoints) { $0.gameNumber }
    }
    
    /// Game numbers sorted by most recent first
    private var sortedGameNumbers: [Int] {
        pointsByGame.keys.sorted(by: >)
    }
    
    // MARK: - Score Calculation
    
    private func calculateScore(for gameNumber: Int) -> (player: Int, opponent: Int) {
        // Prefer SwiftData calculation
        if let game = match?.games?.first(where: { $0.gameNumber == gameNumber }) {
            return (game.pointsWon, game.pointsLost)
        }
        
        // Fallback to stored points calculation
        let gameStoredPoints = storedPoints.filter { $0.gameNumber == gameNumber }
        var playerScore = 0
        var opponentScore = 0
        
        for pointData in gameStoredPoints {
            guard let outcome = pointData.outcomeValue else { continue }
            switch outcome {
            case .myWinner, .opponentError:
                playerScore += 1
            case .iMissed, .myError, .unlucky:
                opponentScore += 1
            }
        }
        
        return (playerScore, opponentScore)
    }
    
    // MARK: - Point Lookup
    
    private func findPoint(for pointInfo: PointInfo, in gameNumber: Int) -> (point: Point?, pointData: PointData?) {
        if pointInfo.isStored {
            let pointData = storedPoints.first { $0.id == pointInfo.id && $0.gameNumber == gameNumber }
            return (nil, pointData)
        } else {
            let point = match?.games?.first { $0.gameNumber == gameNumber }?
                .points?.first { $0.uniqueID == pointInfo.id }
            return (point, nil)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !validPoints.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedGameNumbers, id: \.self) { gameNumber in
                            if let gamePoints = pointsByGame[gameNumber] {
                                // Game divider with score
                                let score = calculateScore(for: gameNumber)
                                let isFirstGame = sortedGameNumbers.first == gameNumber
                                GameDivider(
                                    gameNumber: gameNumber,
                                    playerScore: score.player,
                                    opponentScore: score.opponent,
                                    showTopDivider: !isFirstGame
                                )
                                
                                // Points for this game
                                ForEach(gamePoints, id: \.id) { pointInfo in
                                    let (point, pointData) = findPoint(for: pointInfo, in: gameNumber)
                                    if let point = point {
                                        PointHistoryRow(point: point)
                                    } else if let pointData = pointData {
                                        PointHistoryRow(pointData: pointData)
                                    }
                                }
                            }
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
        .onAppear {
            loadStoredPoints()
        }
        .onChange(of: match?.id) { _, newMatchID in
            if newMatchID == nil {
                storedPoints = []
            }
            loadStoredPoints()
        }
        .onChange(of: game?.pointCount) { _, _ in
            loadStoredPoints()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadStoredPoints() {
        storedPoints = PointHistoryStorage.shared.loadAllPoints()
    }
}

// MARK: - Supporting Types

/// Represents a point in the history view
private struct PointInfo: Identifiable {
    let id: String
    let timestamp: Date
    let isStored: Bool
    let gameNumber: Int
}

// MARK: - Game Divider
struct GameDivider: View {
    let gameNumber: Int
    let playerScore: Int
    let opponentScore: Int
    let showTopDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if showTopDivider {
                Divider()
                    .padding(.top, 8)
            }
            
            HStack {
                Text("Game \(gameNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(playerScore) - \(opponentScore)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
                .padding(.bottom, 4)
        }
        .background(Color.secondary.opacity(0.05))
    }
}

// MARK: - Point History Row
struct PointHistoryRow: View {
    let point: Point?
    let pointData: PointData?
    
    init(point: Point) {
        self.point = point
        self.pointData = nil
    }
    
    init(pointData: PointData) {
        self.point = nil
        self.pointData = pointData
    }
    
    private var outcome: Outcome? {
        point?.outcome ?? pointData?.outcomeValue
    }
    
    var body: some View {
        if point != nil || pointData != nil {
            HStack(spacing: 12) {
                // Stroke sequence with horizontal scrolling (ScrollView is inside StrokeSequenceView)
                if let point = point {
                    StrokeSequenceView(point: point)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                } else if let pointData = pointData {
                    StrokeSequenceView(pointData: pointData)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                
                // Outcome emoji and displayName together on the right
                if let outcome = outcome {
                    HStack(spacing: 8) {
                        Text(outcome.emoji)
                            .font(.system(size: 24))
                        Text(outcome.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                outcome == .myWinner ? Color.green.opacity(0.08) :
                outcome == .iMissed ? Color.red.opacity(0.08) :
                Color.clear
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.secondary.opacity(0.1)),
                alignment: .bottom
            )
        } else {
            EmptyView()
        }
    }
}

