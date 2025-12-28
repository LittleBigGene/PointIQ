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
    
    private var allPoints: [(id: String, timestamp: Date, isStored: Bool)] {
        var points: [(id: String, timestamp: Date, isStored: Bool)] = []
        var seenIDs = Set<String>()
        
        // Add stored points for current game only
        if let game = game {
            let currentGameStoredPoints = storedPoints.filter { $0.gameNumber == game.gameNumber }
            for pointData in currentGameStoredPoints where !seenIDs.contains(pointData.id) {
                points.append((id: pointData.id, timestamp: pointData.timestamp, isStored: true))
                seenIDs.insert(pointData.id)
            }
        }
        
        // Add SwiftData points (prefer over stored points if duplicate ID)
        if let game = game, let gamePoints = game.points {
            for point in gamePoints {
                let pointID = point.uniqueID
                if !seenIDs.contains(pointID) {
                    points.append((id: pointID, timestamp: point.timestamp, isStored: false))
                    seenIDs.insert(pointID)
                } else {
                    // Replace stored point with SwiftData point (more current)
                    points.removeAll { $0.id == pointID && $0.isStored }
                    points.append((id: pointID, timestamp: point.timestamp, isStored: false))
                }
            }
        }
        
        return points.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var validPoints: [(id: String, timestamp: Date, isStored: Bool)] {
        // Filter to only include points that actually exist (prevents empty rows)
        return allPoints.filter { pointInfo in
            if pointInfo.isStored {
                guard let game = game else { return false }
                return storedPoints.contains { $0.id == pointInfo.id && $0.gameNumber == game.gameNumber }
            } else {
                return game?.points?.contains(where: { $0.uniqueID == pointInfo.id }) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Game Point History")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 4)
                Spacer()
            }
            
            if !validPoints.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(validPoints, id: \.id) { pointInfo in
                            if pointInfo.isStored,
                               let pointData = storedPoints.first(where: { $0.id == pointInfo.id && $0.gameNumber == game?.gameNumber }) {
                                PointHistoryRow(pointData: pointData)
                            } else if !pointInfo.isStored,
                                      let point = game?.points?.first(where: { $0.uniqueID == pointInfo.id }) {
                                PointHistoryRow(point: point)
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

