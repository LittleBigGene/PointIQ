//
//  HistoryView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.startDate, order: .reverse) private var matches: [Match]
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @State private var showUpgradeView = false
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private let topOffset: CGFloat = -40
    private let freeMatchLimit = 5
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // Limit matches based on subscription tier
    private var displayMatches: [Match] {
        guard let limit = subscriptionService.currentTier.matchLimit else {
            // Unlimited
            return matches
        }
        return Array(matches.prefix(limit))
    }
    
    private var shouldShowUpgradeBanner: Bool {
        guard let limit = subscriptionService.currentTier.matchLimit else {
            // Unlimited tier - no banner needed
            return false
        }
        return matches.count > limit
    }
    
    private func upgradeText(for language: Language) -> String {
        switch language {
        case .english: return "Upgrade to Premium"
        case .japanese: return "プレミアムにアップグレード"
        case .chinese: return "升級至高級版"
        }
    }
    
    private func limitedHistoryText(for language: Language) -> String {
        let currentLimit = subscriptionService.currentTier.matchLimit ?? 0
        switch language {
        case .english:
            if subscriptionService.currentTier == .free {
                return "Showing last \(currentLimit) matches. Upgrade for more history."
            } else {
                return "Showing \(currentLimit) matches. Upgrade for unlimited history."
            }
        case .japanese:
            if subscriptionService.currentTier == .free {
                return "最後の\(currentLimit)試合を表示中。より多くの履歴のためアップグレードしてください。"
            } else {
                return "\(currentLimit)試合を表示中。無制限履歴のためアップグレードしてください。"
            }
        case .chinese:
            if subscriptionService.currentTier == .free {
                return "顯示最近\(currentLimit)場比賽。升級以獲得更多歷史記錄。"
            } else {
                return "顯示\(currentLimit)場比賽。升級以獲得無限歷史記錄。"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Upgrade Banner (if over current tier limit)
                    if shouldShowUpgradeBanner {
                        UpgradeBanner(
                            text: limitedHistoryText(for: selectedLanguage),
                            upgradeText: upgradeText(for: selectedLanguage),
                            onUpgrade: {
                                showUpgradeView = true
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    // Overall Statistics Section
                    StatisticsSection(matches: displayMatches)
                    
                    // Recent Matches Section
                    RecentMatchesSection(matches: displayMatches, modelContext: modelContext)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, 10)
                .offset(y: topOffset)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Premium badge or upgrade button
                if !subscriptionService.isPremium {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showUpgradeView = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                Text(upgradeText(for: selectedLanguage))
                                    .font(.caption)
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("Premium")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }
            .sheet(isPresented: $showUpgradeView) {
                PremiumUpgradeView()
            }
        }
        .task {
            await subscriptionService.checkPremiumStatus()
        }
    }
}

struct UpgradeBanner: View {
    let text: String
    let upgradeText: String
    let onUpgrade: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: onUpgrade) {
                Text(upgradeText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Statistics Section

struct StatisticsSection: View {
    let matches: [Match]
    
    // Only include completed matches (those with an endDate)
    private var completedMatches: [Match] {
        matches.filter { $0.endDate != nil }
    }
    
    private var totalMatches: Int {
        completedMatches.count
    }
    
    private var totalGamesWon: Int {
        completedMatches.reduce(0) { $0 + $1.gamesWon }
    }
    
    private var totalGamesLost: Int {
        completedMatches.reduce(0) { $0 + $1.gamesLost }
    }
    
    private var totalPointsWon: Int {
        completedMatches.reduce(0) { $0 + $1.pointsWon }
    }
    
    private var totalPointsLost: Int {
        completedMatches.reduce(0) { $0 + $1.pointsLost }
    }
    
    private var matchWinRate: Double {
        guard totalMatches > 0 else { return 0 }
        let wins = completedMatches.filter { $0.winner == true }.count
        return Double(wins) / Double(totalMatches) * 100
    }
    
    private var gameWinRate: Double {
        let totalGames = totalGamesWon + totalGamesLost
        guard totalGames > 0 else { return 0 }
        return Double(totalGamesWon) / Double(totalGames) * 100
    }
    
    private var pointWinRate: Double {
        let totalPoints = totalPointsWon + totalPointsLost
        guard totalPoints > 0 else { return 0 }
        return Double(totalPointsWon) / Double(totalPoints) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Matches",
                    value: "\(totalMatches)",
                    subtitle: "\(totalMatches) completed",
                    color: .blue
                )
                
                StatCard(
                    title: "Match Win Rate",
                    value: String(format: "%.1f%%", matchWinRate),
                    subtitle: totalMatches > 0 ? "\(completedMatches.filter { $0.winner == true }.count)W - \(completedMatches.filter { $0.winner == false }.count)L" : "No matches",
                    color: .green
                )
                
                StatCard(
                    title: "Games",
                    value: "\(totalGamesWon + totalGamesLost)",
                    subtitle: "\(totalGamesWon)W - \(totalGamesLost)L",
                    color: .orange
                )
                
                StatCard(
                    title: "Game Win Rate",
                    value: String(format: "%.1f%%", gameWinRate),
                    subtitle: "\(totalGamesWon + totalGamesLost) total",
                    color: .purple
                )
                
                StatCard(
                    title: "Points",
                    value: "\(totalPointsWon + totalPointsLost)",
                    subtitle: "\(totalPointsWon)W - \(totalPointsLost)L",
                    color: .red
                )
                
                StatCard(
                    title: "Point Win Rate",
                    value: String(format: "%.1f%%", pointWinRate),
                    subtitle: "\(totalPointsWon + totalPointsLost) total",
                    color: .teal
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Recent Matches Section

struct RecentMatchesSection: View {
    let matches: [Match]
    let modelContext: ModelContext
    
    private var recentMatches: [Match] {
        // Only include completed matches (those with an endDate)
        let completedMatches = matches.filter { $0.endDate != nil }
        return Array(completedMatches.prefix(10))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Matches")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if recentMatches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.table.tennis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No matches yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start playing to see your match history here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recentMatches.enumerated()), id: \.element.id) { index, match in
                        MatchRow(match: match, matchNumber: index, modelContext: modelContext)
                    }
                }
            }
        }
    }
}

struct MatchRow: View {
    let match: Match
    let matchNumber: Int
    let modelContext: ModelContext
    
    @State private var showDeleteConfirmation = false
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    private func deleteText(for language: Language) -> String {
        switch language {
        case .english: return "Delete"
        case .japanese: return "削除"
        case .chinese: return "刪除"
        }
    }
    
    private func cancelText(for language: Language) -> String {
        switch language {
        case .english: return "Cancel"
        case .japanese: return "キャンセル"
        case .chinese: return "取消"
        }
    }
    
    private func deleteMatchText(for language: Language) -> String {
        switch language {
        case .english: return "Delete Match"
        case .japanese: return "試合を削除"
        case .chinese: return "刪除比賽"
        }
    }
    
    private func deleteMatchMessageText(for language: Language) -> String {
        switch language {
        case .english: return "Are you sure you want to delete this match? This action cannot be undone."
        case .japanese: return "この試合を削除してもよろしいですか？この操作は元に戻せません。"
        case .chinese: return "確定要刪除此比賽嗎？此操作無法復原。"
        }
    }
    
    private var matchDuration: String {
        guard let endDate = match.endDate else {
            return "In progress"
        }
        let duration = endDate.timeIntervalSince(match.startDate)
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: match.startDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let matchNotes = match.notes, !matchNotes.isEmpty {
                        Text(matchNotes)
                            .font(.headline)
                    } else if let opponentName = match.opponentName, !opponentName.isEmpty {
                        Text("Match \(matchNumber): \(opponentName)")
                            .font(.headline)
                    } else {
                        Text("Match \(matchNumber)")
                            .font(.headline)
                    }
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if let winner = match.winner {
                            HStack(spacing: 4) {
                                Image(systemName: winner ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(winner ? .green : .red)
                                Text(winner ? "Won" : "Lost")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(winner ? .green : .red)
                            }
                        }
                        
                        Text(matchDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                            .padding(8)
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Games")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(match.gamesWon) - \(match.gamesLost)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(match.pointsWon) - \(match.pointsLost)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(match.pointCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .alert(deleteMatchText(for: selectedLanguage), isPresented: $showDeleteConfirmation) {
            Button(cancelText(for: selectedLanguage), role: .cancel) { }
            Button(deleteText(for: selectedLanguage), role: .destructive) {
                deleteMatch()
            }
        } message: {
            Text(deleteMatchMessageText(for: selectedLanguage))
        }
    }
    
    private func deleteMatch() {
        // Delete all games and points (cascade should handle this, but being explicit)
        if let games = match.games {
            for game in games {
                if let points = game.points {
                    for point in points {
                        modelContext.delete(point)
                    }
                }
                modelContext.delete(game)
            }
        }
        modelContext.delete(match)
        try? modelContext.save()
    }
}

