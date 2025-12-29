//
//  LegendView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

struct LegendView: View {
    @AppStorage("legendServeExpanded") private var isServeExpanded: Bool = true
    @AppStorage("legendReceiveExpanded") private var isReceiveExpanded: Bool = true
    @AppStorage("legendRallyExpanded") private var isRallyExpanded: Bool = true
    @AppStorage("legendOutcomesExpanded") private var isOutcomesExpanded: Bool = true
    @AppStorage("legendGameRulesExpanded") private var isGameRulesExpanded: Bool = true
    
    private let topOffset: CGFloat = -40
    
    private var allExpanded: Bool {
        isServeExpanded && isReceiveExpanded && isRallyExpanded && isOutcomesExpanded && isGameRulesExpanded
    }
    
    private func toggleAllPanels() {
        let shouldExpand = !allExpanded
        isServeExpanded = shouldExpand
        isReceiveExpanded = shouldExpand
        isRallyExpanded = shouldExpand
        isOutcomesExpanded = shouldExpand
        isGameRulesExpanded = shouldExpand
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Serve Section
                    DisclosureGroup(isExpanded: $isServeExpanded) {
                        // Serve Types
                        ForEach(ServeType.allCases, id: \.self) { serveType in
                            HStack(spacing: 16) {
                                Text(serveType.rawValue)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(serveType.displayName)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("🫴")
                                .font(.title2)
                            Text("Serve")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Receive Section
                    DisclosureGroup(isExpanded: $isReceiveExpanded) {
                        // Receive Types
                        ForEach(ReceiveType.allCases, id: \.self) { receiveType in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 16) {
                                    Text(receiveType.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(receiveType.displayName) / \(receiveType.spinType)")
                                            .font(.headline)
                                        Text(receiveType.fruitName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                Text(receiveType.whyItWorks)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 48)
                            }
                            .padding(.vertical, 8)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("👁️")
                                .font(.title2)
                            Text("Receive")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Rally Section
                    DisclosureGroup(isExpanded: $isRallyExpanded) {
                        // Rally Types
                        ForEach(RallyType.allCases, id: \.self) { rallyType in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 16) {
                                    Text(rallyType.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(rallyType.displayName) / \(rallyType.spinType)")
                                            .font(.headline)
                                        Text(rallyType.animalName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                Text(rallyType.whyItWorks)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 48)
                            }
                            .padding(.vertical, 8)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(StrokeToken.animal.emoji)
                                .font(.title2)
                            Text("Rally")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
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
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("🏓")
                                .font(.title2)
                            Text("Outcomes")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Game Rules Section
                    DisclosureGroup(isExpanded: $isGameRulesExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            RuleRow(
                                title: "Points to Win",
                                description: "\(Rules.pointsToWinGame) points"
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
                        HStack(spacing: 8) {
                            Text("📋")
                                .font(.title2)
                            Text("Game Rules")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, 10)
                .offset(y: topOffset)
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        toggleAllPanels()
                    }) {
                        Text("Stroke Legend")
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

