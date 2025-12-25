//
//  LegendView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

struct LegendView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Stroke Tokens Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stroke Tokens")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(StrokeToken.allCases, id: \.self) { stroke in
                            HStack(spacing: 16) {
                                Text(stroke.emoji)
                                    .font(.system(size: 32))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stroke.displayName)
                                        .font(.headline)
                                    Text(stroke.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Outcomes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Outcomes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(Outcome.allCases, id: \.self) { outcome in
                            HStack(spacing: 16) {
                                Text(outcome.emoji)
                                    .font(.system(size: 32))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(outcome.displayName)
                                        .font(.headline)
                                    Text(outcome.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Game Rules Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Game Rules")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            RuleRow(
                                title: "Points to Win",
                                description: "\(TableTennisRules.pointsToWinGame) points"
                            )
                            RuleRow(
                                title: "Win by 2",
                                description: "Must lead by at least 2 points"
                            )
                            RuleRow(
                                title: "Deuce",
                                description: "At 10-10, service alternates every point"
                            )
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Legend")
        }
    }
}

struct RuleRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

