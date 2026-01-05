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
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    @AppStorage("pointsToWinGame") private var pointsToWinGame: Int = 11
    @AppStorage("legendMode") private var isPostGameMode: Bool = true
    @AppStorage("playerHandedness") private var playerHandedness: String = "Right-handed"
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    private let topOffset: CGFloat = -40
    
    // MARK: - Translation Helpers
    
    private func gameRulesText(for language: Language) -> String {
        switch language {
        case .english: return "Game Rules"
        case .japanese: return "ゲームルール"
        case .chinese: return "比賽規則"
        }
    }
    
    private func pointsToWinText(for language: Language) -> String {
        switch language {
        case .english: return "Points to Win"
        case .japanese: return "勝利点数"
        case .chinese: return "獲勝分數"
        }
    }
    
    
    private func winBy2Text(for language: Language) -> String {
        switch language {
        case .english: return "Win by 2"
        case .japanese: return "2点差で勝利"
        case .chinese: return "領先2分獲勝"
        }
    }
    
    private func winBy2Description(for language: Language) -> String {
        switch language {
        case .english: return "Must lead by at least 2 points"
        case .japanese: return "最低2点のリードが必要"
        case .chinese: return "必須領先至少2分"
        }
    }
    
    private func deuceText(for language: Language) -> String {
        switch language {
        case .english: return "Deuce"
        case .japanese: return "ジュース"
        case .chinese: return "平分"
        }
    }
    
    private func deuceDescription(for language: Language) -> String {
        let threshold = pointsToWinGame - 1
        switch language {
        case .english: return "At \(threshold)-\(threshold), serve alternates every point"
        case .japanese: return "\(threshold)-\(threshold)の時、サーブは毎ポイント交代"
        case .chinese: return "\(threshold)-\(threshold)時，每分換發球"
        }
    }
    
    private func dragInstructionsText(for language: Language) -> String {
        let isRightHanded = playerHandedness == "Right-handed"
        switch language {
        case .english:
            if isRightHanded {
                return "In-game focuses on your outcome only. Since you are right-handed: Drag left for Backhand, drag right for Forehand"
            } else {
                return "In-game focuses on your outcome only. Since you are left-handed: Drag left for Forehand, drag right for Backhand"
            }
        case .japanese:
            if isRightHanded {
                return "ゲーム中は自分の結果を集中しましょう。右利きなので: 左にドラッグでバックハンド、右にドラッグでフォアハンド"
            } else {
                return "ゲーム中は自分の結果を集中しましょう。左利きなので: 左にドラッグでフォアハンド、右にドラッグでバックハンド"
            }
        case .chinese:
            if isRightHanded {
                return "比赛进行中，专注于你的結果。由於你是右撇子：向左拖動為反手，向右拖動為正手"
            } else {
                return "比赛进行中，专注于你的結果。由於你是左撇子：向左拖動為正手，向右拖動為反手"
            }
        }
    }
    
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
    
    // Outcomes to display based on mode
    // In in-game mode, exclude only myError (opponentError is shown)
    private var displayedOutcomes: [Outcome] {
        if isPostGameMode {
            return Outcome.allCases
        } else {
            return Outcome.allCases.filter { $0 != .myError }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Game Rules Section (moved to top)
                    DisclosureGroup(isExpanded: $isGameRulesExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Editable Points to Win
                            HStack {
                                Text(pointsToWinText(for: selectedLanguage))
                                    .font(.headline)
                                Spacer()
                                Stepper(value: $pointsToWinGame, in: 1...21) {
                                    Text("\(pointsToWinGame)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(minWidth: 30)
                                }
                            }
                            .padding(.vertical, 4)
                            .onChange(of: pointsToWinGame) { _, newValue in
                                // Sync with Rules static property
                                Rules.pointsToWinGame = newValue
                            }
                            
                            RuleRow(
                                title: winBy2Text(for: selectedLanguage),
                                description: winBy2Description(for: selectedLanguage)
                            )
                            RuleRow(
                                title: deuceText(for: selectedLanguage),
                                description: deuceDescription(for: selectedLanguage)
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("📋")
                                .font(.title2)
                            Text(gameRulesText(for: selectedLanguage))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Serve Section (shown only in post-game mode)
                    if isPostGameMode {
                        DisclosureGroup(isExpanded: $isServeExpanded) {
                            // Serve Types
                            ForEach(ServeType.allCases, id: \.self) { serveType in
                                HStack(spacing: 16) {
                                    Text(serveType.rawValue)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                        .frame(width: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(serveType.displayName(for: selectedLanguage))
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
                        
                        // Receive Section (shown only in post-game mode)
                        DisclosureGroup(isExpanded: $isReceiveExpanded) {
                            // Receive Types
                            ForEach(ReceiveType.allCases, id: \.self) { receiveType in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 16) {
                                        Text(receiveType.emoji)
                                            .font(.system(size: 32))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(receiveType.displayName(for: selectedLanguage)) / \(receiveType.spinType(for: selectedLanguage))")
                                                .font(.headline)
                                            Text(receiveType.fruitName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    Text(receiveType.whyItWorks(for: selectedLanguage))
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
                        
                        // Rally Section (shown only in post-game mode)
                        DisclosureGroup(isExpanded: $isRallyExpanded) {
                            // Rally Types
                            ForEach(RallyType.allCases, id: \.self) { rallyType in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 16) {
                                        Text(rallyType.emoji)
                                            .font(.system(size: 32))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(rallyType.displayName(for: selectedLanguage)) / \(rallyType.spinType(for: selectedLanguage))")
                                                .font(.headline)
                                            Text(rallyType.animalName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    Text(rallyType.whyItWorks(for: selectedLanguage))
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
                    }
                    
                    // Outcomes Section
                    DisclosureGroup(isExpanded: $isOutcomesExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Show drag instructions in in-game mode
                            if !isPostGameMode {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.draw")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                    Text(dragInstructionsText(for: selectedLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            ForEach(displayedOutcomes, id: \.self) { outcome in
                                HStack(spacing: 16) {
                                    Text(outcome.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(outcome.displayName(for: selectedLanguage))
                                            .font(.headline)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
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
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, 10)
                .offset(y: topOffset)
            }
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Sync pointsToWinGame from Rules on appear (in case it was changed elsewhere)
                pointsToWinGame = Rules.pointsToWinGame
            }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            Button(action: { isPostGameMode = false }) {
                                HStack {
                                    Text("In-Game")
                                    if !isPostGameMode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { isPostGameMode = true }) {
                                HStack {
                                    Text("Post-Game")
                                    if isPostGameMode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Text(isPostGameMode ? "Post-Game" : "In-Game")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Menu {
                            Picker("Language", selection: $selectedLanguageRaw) {
                                ForEach(Language.allCases, id: \.rawValue) { language in
                                    HStack {
                                        Text(language.flag)
                                        Text(language.displayName)
                                    }
                                    .tag(language.rawValue)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedLanguage.flag)
                                    .font(.title3)
                            }
                        }
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

