//
//  ProfileView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

enum GripType: String, CaseIterable {
    case penhold = "Penhold"
    case shakehand = "Shakehand"
    case other = "Other"
}

enum Handedness: String, CaseIterable {
    case left = "Left-handed"
    case right = "Right-handed"
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.startDate, order: .reverse) private var matches: [Match]
    
    @AppStorage("playerName") private var playerName: String = "YOU"
    @AppStorage("playerGrip") private var playerGrip: String = GripType.shakehand.rawValue
    @AppStorage("playerHandedness") private var playerHandedness: String = Handedness.right.rawValue
    @AppStorage("playerBlade") private var playerBlade: String = ""
    @AppStorage("playerForehandRubber") private var playerForehandRubber: String = ""
    @AppStorage("playerBackhandRubber") private var playerBackhandRubber: String = ""
    @AppStorage("playerEloRating") private var playerEloRating: String = ""
    @AppStorage("playerClubName") private var playerClubName: String = ""
    
    @AppStorage("opponentName") private var opponentName: String = ""
    @AppStorage("opponentGrip") private var opponentGrip: String = GripType.shakehand.rawValue
    @AppStorage("opponentHandedness") private var opponentHandedness: String = Handedness.right.rawValue
    @AppStorage("opponentBlade") private var opponentBlade: String = ""
    @AppStorage("opponentForehandRubber") private var opponentForehandRubber: String = ""
    @AppStorage("opponentBackhandRubber") private var opponentBackhandRubber: String = ""
    @AppStorage("opponentEloRating") private var opponentEloRating: String = ""
    @AppStorage("opponentClubName") private var opponentClubName: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Player Profile Section
                    DisclosureGroup("Player Profile") {
                        PlayerProfileSection(
                            playerName: $playerName,
                            playerGrip: $playerGrip,
                            playerHandedness: $playerHandedness,
                            playerBlade: $playerBlade,
                            playerForehandRubber: $playerForehandRubber,
                            playerBackhandRubber: $playerBackhandRubber,
                            playerEloRating: $playerEloRating,
                            playerClubName: $playerClubName
                        )
                        .padding(.top, 6)
                    }
                    .padding(.horizontal)
                    
                    // Opponent Profile Section
                    DisclosureGroup("Opponent Profile") {
                        OpponentProfileSection(
                            opponentName: $opponentName,
                            opponentGrip: $opponentGrip,
                            opponentHandedness: $opponentHandedness,
                            opponentBlade: $opponentBlade,
                            opponentForehandRubber: $opponentForehandRubber,
                            opponentBackhandRubber: $opponentBackhandRubber,
                            opponentEloRating: $opponentEloRating,
                            opponentClubName: $opponentClubName
                        )
                        .padding(.top, 6)
                    }
                    .padding(.horizontal)
                    
                    // Overall Statistics Section
                    StatisticsSection(matches: matches)
                    
                    // Recent Matches Section
                    RecentMatchesSection(matches: matches)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct PlayerProfileSection: View {
    @Binding var playerName: String
    @Binding var playerGrip: String
    @Binding var playerHandedness: String
    @Binding var playerBlade: String
    @Binding var playerForehandRubber: String
    @Binding var playerBackhandRubber: String
    @Binding var playerEloRating: String
    @Binding var playerClubName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 6) {
                // First row: Name and Handedness
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Player Name",
                        value: $playerName,
                        placeholder: "YOU"
                    )
                    
                    ProfileDropdownField(
                        label: "Handedness",
                        selection: $playerHandedness,
                        options: Handedness.allCases.map { $0.rawValue }
                    )
                }
                
                // Second row: Grip and Blade
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileDropdownField(
                        label: "Grip",
                        selection: $playerGrip,
                        options: GripType.allCases.map { $0.rawValue }
                    )
                    
                    ProfileField(
                        label: "Blade",
                        value: $playerBlade,
                        placeholder: "Enter blade name"
                    )
                }
                
                // Third row: Forehand Rubber and Backhand Rubber
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Forehand Rubber",
                        value: $playerForehandRubber,
                        placeholder: "Enter forehand rubber"
                    )
                    
                    ProfileField(
                        label: "Backhand Rubber",
                        value: $playerBackhandRubber,
                        placeholder: "Enter backhand rubber"
                    )
                }
                
                // Fourth row: Elo Rating and Club Name
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Elo Rating",
                        value: $playerEloRating,
                        placeholder: "Enter Elo rating"
                    )
                    
                    ProfileField(
                        label: "Club Name",
                        value: $playerClubName,
                        placeholder: "Enter club name"
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct OpponentProfileSection: View {
    @Binding var opponentName: String
    @Binding var opponentGrip: String
    @Binding var opponentHandedness: String
    @Binding var opponentBlade: String
    @Binding var opponentForehandRubber: String
    @Binding var opponentBackhandRubber: String
    @Binding var opponentEloRating: String
    @Binding var opponentClubName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 6) {
                // First row: Name and Handedness
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Opponent Name",
                        value: $opponentName,
                        placeholder: "Enter opponent name"
                    )
                    
                    ProfileDropdownField(
                        label: "Handedness",
                        selection: $opponentHandedness,
                        options: Handedness.allCases.map { $0.rawValue }
                    )
                }
                
                // Second row: Grip and Blade
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileDropdownField(
                        label: "Grip",
                        selection: $opponentGrip,
                        options: GripType.allCases.map { $0.rawValue }
                    )
                    
                    ProfileField(
                        label: "Blade",
                        value: $opponentBlade,
                        placeholder: "Enter blade name"
                    )
                }
                
                // Third row: Forehand Rubber and Backhand Rubber
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Forehand Rubber",
                        value: $opponentForehandRubber,
                        placeholder: "Enter forehand rubber"
                    )
                    
                    ProfileField(
                        label: "Backhand Rubber",
                        value: $opponentBackhandRubber,
                        placeholder: "Enter backhand rubber"
                    )
                }
                
                // Fourth row: Elo Rating and Club Name
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ProfileField(
                        label: "Elo Rating",
                        value: $opponentEloRating,
                        placeholder: "Enter Elo rating"
                    )
                    
                    ProfileField(
                        label: "Club Name",
                        value: $opponentClubName,
                        placeholder: "Enter club name"
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ProfileField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProfileDropdownField: View {
    let label: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Select \(label)" : selection)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatisticsSection: View {
    let matches: [Match]
    
    private var totalMatches: Int {
        matches.count
    }
    
    private var completedMatches: Int {
        matches.filter { $0.endDate != nil }.count
    }
    
    private var totalGamesWon: Int {
        matches.reduce(0) { $0 + $1.gamesWon }
    }
    
    private var totalGamesLost: Int {
        matches.reduce(0) { $0 + $1.gamesLost }
    }
    
    private var totalPointsWon: Int {
        matches.reduce(0) { $0 + $1.pointsWon }
    }
    
    private var totalPointsLost: Int {
        matches.reduce(0) { $0 + $1.pointsLost }
    }
    
    private var matchWinRate: Double {
        guard completedMatches > 0 else { return 0 }
        let wins = matches.filter { $0.winner == true }.count
        return Double(wins) / Double(completedMatches) * 100
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
                    subtitle: "\(completedMatches) completed",
                    color: .blue
                )
                
                StatCard(
                    title: "Match Win Rate",
                    value: String(format: "%.1f%%", matchWinRate),
                    subtitle: completedMatches > 0 ? "\(matches.filter { $0.winner == true }.count)W - \(matches.filter { $0.winner == false }.count)L" : "No matches",
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

struct RecentMatchesSection: View {
    let matches: [Match]
    
    private var recentMatches: [Match] {
        Array(matches.prefix(10))
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
                ForEach(recentMatches) { match in
                    MatchRow(match: match)
                }
            }
        }
    }
}

struct MatchRow: View {
    let match: Match
    
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
                    if let opponentName = match.opponentName, !opponentName.isEmpty {
                        Text(opponentName)
                            .font(.headline)
                    } else {
                        Text("Match")
                            .font(.headline)
                    }
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                    } else {
                        Text("Active")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text(matchDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    }
}




