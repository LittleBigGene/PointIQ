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

