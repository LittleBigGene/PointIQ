//
//  LegendView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

struct LegendView: View {
    @State private var isServeExpanded = true
    @State private var isBackhandExpanded = true
    @State private var isForehandExpanded = true
    @State private var isOutcomesExpanded = true
    @State private var isGameRulesExpanded = true
    
    private var allExpanded: Bool {
        isServeExpanded && isBackhandExpanded && isForehandExpanded && isOutcomesExpanded && isGameRulesExpanded
    }
    
    private func toggleAllPanels() {
        let shouldExpand = !allExpanded
        isServeExpanded = shouldExpand
        isBackhandExpanded = shouldExpand
        isForehandExpanded = shouldExpand
        isOutcomesExpanded = shouldExpand
        isGameRulesExpanded = shouldExpand
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Serve Section
                    DisclosureGroup(isExpanded: $isServeExpanded) {
                        // General Serve token
                        HStack(spacing: 16) {
                            Text(StrokeToken.vegetable.emoji)
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StrokeToken.vegetable.displayName)
                                    .font(.headline)
                                Text(StrokeToken.vegetable.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Serve Types
                        ForEach(ServiceType.allCases, id: \.self) { serviceType in
                            HStack(spacing: 16) {
                                Text(serviceType.emoji)
                                    .font(.system(size: 32))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(serviceType.displayName)
                                        .font(.headline)
                                    Text(serviceType.vegetableName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } label: {
                        Text("Serve")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Backhand Section
                    DisclosureGroup(isExpanded: $isBackhandExpanded) {
                        HStack(spacing: 16) {
                            Text(StrokeToken.fruit.emoji)
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StrokeToken.fruit.displayName)
                                    .font(.headline)
                                Text(StrokeToken.fruit.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Backhand")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Forehand Section
                    DisclosureGroup(isExpanded: $isForehandExpanded) {
                        HStack(spacing: 16) {
                            Text(StrokeToken.protein.emoji)
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(StrokeToken.protein.displayName)
                                    .font(.headline)
                                Text(StrokeToken.protein.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Forehand")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Outcomes Section
                    DisclosureGroup(isExpanded: $isOutcomesExpanded) {
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
                    } label: {
                        Text("Outcomes")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Game Rules Section
                    DisclosureGroup(isExpanded: $isGameRulesExpanded) {
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
                                description: "At 10-10, serve alternates every point"
                            )
                        }
                    } label: {
                        Text("Game Rules")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        toggleAllPanels()
                    }) {
                        Text("Legend")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
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

