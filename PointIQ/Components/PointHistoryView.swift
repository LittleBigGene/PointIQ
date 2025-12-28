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
    
    private var allPoints: [(id: String, timestamp: Date, isStored: Bool, gameNumber: Int)] {
        var points: [(id: String, timestamp: Date, isStored: Bool, gameNumber: Int)] = []
        var seenIDs = Set<String>()
        
        // Add stored points from all games in the match
        if let match = match {
            let matchStoredPoints = storedPoints
            for pointData in matchStoredPoints where !seenIDs.contains(pointData.id) {
                points.append((id: pointData.id, timestamp: pointData.timestamp, isStored: true, gameNumber: pointData.gameNumber ?? 1))
                seenIDs.insert(pointData.id)
            }
        }
        
        // Add SwiftData points from all games (prefer over stored points if duplicate ID)
        if let match = match, let games = match.games {
            for game in games.sorted(by: { $0.gameNumber < $1.gameNumber }) {
                if let gamePoints = game.points {
                    for point in gamePoints {
                        let pointID = point.uniqueID
                        if !seenIDs.contains(pointID) {
                            points.append((id: pointID, timestamp: point.timestamp, isStored: false, gameNumber: game.gameNumber))
                            seenIDs.insert(pointID)
                        } else {
                            // Replace stored point with SwiftData point (more current)
                            points.removeAll { $0.id == pointID && $0.isStored }
                            points.append((id: pointID, timestamp: point.timestamp, isStored: false, gameNumber: game.gameNumber))
                        }
                    }
                }
            }
        }
        
        return points.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var validPoints: [(id: String, timestamp: Date, isStored: Bool, gameNumber: Int)] {
        // Filter to only include points that actually exist (prevents empty rows)
        return allPoints.filter { pointInfo in
            if pointInfo.isStored {
                return storedPoints.contains { $0.id == pointInfo.id }
            } else {
                if let match = match, let games = match.games {
                    return games.contains { game in
                        game.gameNumber == pointInfo.gameNumber &&
                        game.points?.contains(where: { $0.uniqueID == pointInfo.id }) ?? false
                    }
                }
                return false
            }
        }
    }
    
    private var pointsByGame: [Int: [(id: String, timestamp: Date, isStored: Bool, gameNumber: Int)]] {
        Dictionary(grouping: validPoints) { $0.gameNumber }
    }
    
    private var sortedGameNumbers: [Int] {
        pointsByGame.keys.sorted(by: >) // Most recent game first
    }
    
    private func calculateScore(for gameNumber: Int) -> (player: Int, opponent: Int) {
        var playerScore = 0
        var opponentScore = 0
        
        // Calculate from SwiftData points if available
        if let match = match,
           let game = match.games?.first(where: { $0.gameNumber == gameNumber }) {
            playerScore = game.pointsWon
            opponentScore = game.pointsLost
        } else {
            // Calculate from stored points
            let gameStoredPoints = storedPoints.filter { $0.gameNumber == gameNumber }
            for pointData in gameStoredPoints {
                if let outcome = pointData.outcomeValue {
                    switch outcome {
                    case .myWinner, .opponentError:
                        playerScore += 1
                    case .iMissed, .myError, .unlucky:
                        opponentScore += 1
                    }
                }
            }
        }
        
        return (playerScore, opponentScore)
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
                                    if pointInfo.isStored,
                                       let pointData = storedPoints.first(where: { $0.id == pointInfo.id && $0.gameNumber == gameNumber }) {
                                        PointHistoryRow(pointData: pointData)
                                    } else if !pointInfo.isStored,
                                              let match = match,
                                              let game = match.games?.first(where: { $0.gameNumber == gameNumber }),
                                              let point = game.points?.first(where: { $0.uniqueID == pointInfo.id }) {
                                        PointHistoryRow(point: point)
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
            // Clear and reload when match changes (e.g., match reset)
            if newMatchID == nil {
                storedPoints = []
            }
            loadStoredPoints()
        }
        .onChange(of: game?.pointCount) { _, _ in
            loadStoredPoints()
        }
    }
    
    private func loadStoredPoints() {
        storedPoints = PointHistoryStorage.shared.loadAllPoints()
    }
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
            .padding(.vertical, showTopDivider ? 8 : 8)
            
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
                if let point = point {
                    StrokeSequenceView(point: point)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let pointData = pointData {
                    StrokeSequenceView(pointData: pointData)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

