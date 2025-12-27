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
        
        // Add stored points
        points.append(contentsOf: storedPoints.map { (id: $0.id, timestamp: $0.timestamp, isStored: true) })
        
        // Add current game points
        if let game = game, let gamePoints = game.points {
            points.append(contentsOf: gamePoints.map { (id: $0.uniqueID, timestamp: $0.timestamp, isStored: false) })
        }
        
        // Sort by timestamp (newest first)
        return points.sorted { $0.timestamp > $1.timestamp }
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
            
            if !allPoints.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(allPoints, id: \.id) { pointInfo in
                            if pointInfo.isStored {
                                if let pointData = storedPoints.first(where: { $0.id == pointInfo.id }) {
                                    PointHistoryRow(pointData: pointData)
                                }
                            } else {
                                if let point = game?.points?.first(where: { $0.uniqueID == pointInfo.id }) {
                                    PointHistoryRow(point: point)
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
    }
}

