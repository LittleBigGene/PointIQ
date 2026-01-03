//
//  ProfileView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData
import MultipeerConnectivity

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
    @StateObject private var sharingService = ProfileSharingService.shared
    
    @AppStorage("playerName") private var playerName: String = "YOU"
    @AppStorage("playerGrip") private var playerGrip: String = GripType.shakehand.rawValue
    @AppStorage("playerHandedness") private var playerHandedness: String = Handedness.right.rawValue
    @AppStorage("playerBlade") private var playerBlade: String = ""
    @AppStorage("playerForehandRubber") private var playerForehandRubber: String = ""
    @AppStorage("playerBackhandRubber") private var playerBackhandRubber: String = ""
    @AppStorage("playerEloRating") private var playerEloRating: Int = 1000 // Default for unrated players
    @AppStorage("playerClubName") private var playerClubName: String = ""
    
    @AppStorage("opponentName") private var opponentName: String = ""
    @AppStorage("opponentGrip") private var opponentGrip: String = GripType.shakehand.rawValue
    @AppStorage("opponentHandedness") private var opponentHandedness: String = Handedness.right.rawValue
    @AppStorage("opponentBlade") private var opponentBlade: String = ""
    @AppStorage("opponentForehandRubber") private var opponentForehandRubber: String = ""
    @AppStorage("opponentBackhandRubber") private var opponentBackhandRubber: String = ""
    @AppStorage("opponentEloRating") private var opponentEloRating: Int = 1000 // Default for unrated players
    @AppStorage("opponentClubName") private var opponentClubName: String = ""
    
    @AppStorage("playerProfileExpanded") private var playerProfileExpanded: Bool = true
    @AppStorage("opponentProfileExpanded") private var opponentProfileExpanded: Bool = true
    
    @State private var showShareConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Sharing Section
                    ProfileSharingSection(
                        sharingService: sharingService,
                        playerName: playerName,
                        onShareToPeer: { peerID in
                            shareProfile(to: peerID)
                        },
                        onAcceptReceived: {
                            acceptReceivedProfile()
                        }
                    )
                    .padding(.horizontal)
                    
                    // Player Profile Section
                    DisclosureGroup("Player Profile", isExpanded: $playerProfileExpanded) {
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
                    DisclosureGroup("Opponent Profile", isExpanded: $opponentProfileExpanded) {
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
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .onChange(of: sharingService.receivedProfile) { _, profile in
            if profile != nil {
                showShareConfirmation = true
            }
        }
        .alert("Connection Request", isPresented: Binding(
            get: { sharingService.pendingInvitation != nil },
            set: { if !$0 { sharingService.rejectInvitation() } }
        )) {
            Button("Accept", role: .none) {
                sharingService.acceptInvitation()
            }
            Button("Decline", role: .cancel) {
                sharingService.rejectInvitation()
            }
        } message: {
            if let invitation = sharingService.pendingInvitation {
                Text("\(invitation.peerID.displayName) wants to share their profile with you.")
            }
        }
        .alert("Profile Received", isPresented: $showShareConfirmation) {
            Button("Accept", role: .none) {
                acceptReceivedProfile()
            }
            Button("Decline", role: .cancel) {
                sharingService.receivedProfile = nil
                sharingService.receivedProfileFromPeer = nil
            }
        } message: {
            if let profile = sharingService.receivedProfile,
               let peerName = sharingService.receivedProfileFromPeer?.displayName {
                Text("Received profile from \(peerName):\n\n\(profile.name)\n\nUse this as opponent profile?")
            }
        }
        .onDisappear {
            sharingService.disconnect()
        }
    }
    
    private func shareProfile(to peerID: MCPeerID) {
        // Convert Int to String for sharing (backward compatibility)
        let eloRatingString = playerEloRating >= 1000 ? "\(playerEloRating)" : ""
        let profile = PlayerProfile(
            name: playerName,
            grip: playerGrip,
            handedness: playerHandedness,
            blade: playerBlade,
            forehandRubber: playerForehandRubber,
            backhandRubber: playerBackhandRubber,
            eloRating: eloRatingString,
            clubName: playerClubName
        )
        sharingService.sendProfile(profile, to: peerID)
    }
    
    private func acceptReceivedProfile() {
        guard let profile = sharingService.receivedProfile else { return }
        
        opponentName = profile.name
        opponentGrip = profile.grip
        opponentHandedness = profile.handedness
        opponentBlade = profile.blade
        opponentForehandRubber = profile.forehandRubber
        opponentBackhandRubber = profile.backhandRubber
        // Convert String to Int for storage (parse 4-digit number, default to 1000 if invalid)
        if !profile.eloRating.isEmpty,
           let eloInt = Int(profile.eloRating), eloInt >= 1000 && eloInt <= 9999 {
            opponentEloRating = eloInt
        } else {
            opponentEloRating = 1000 // Default for unrated players
        }
        opponentClubName = profile.clubName
        
        sharingService.receivedProfile = nil
        sharingService.receivedProfileFromPeer = nil
    }
}

// MARK: - Profile Sharing Section

struct ProfileSharingSection: View {
    @ObservedObject var sharingService: ProfileSharingService
    let playerName: String
    let onShareToPeer: (MCPeerID) -> Void
    let onAcceptReceived: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Start/Stop Sharing Button
            Button(action: {
                if sharingService.isAdvertising {
                    sharingService.stopAdvertising()
                    sharingService.stopBrowsing()
                } else {
                    sharingService.startAdvertising()
                    sharingService.startBrowsing()
                }
            }) {
                HStack {
                    Image(systemName: sharingService.isAdvertising ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    Text(sharingService.isAdvertising ? "Stop Sharing" : "Share My Name & Setup")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(sharingService.isAdvertising ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(sharingService.isAdvertising ? .red : .blue)
                .cornerRadius(10)
            }
            
            // Discovered Peers List (AirDrop-style)
            if sharingService.isBrowsing && !sharingService.discoveredPeers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby Devices")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(sharingService.discoveredPeers, id: \.displayName) { peer in
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(sharingService.connectedPeers.contains(peer) ? "Connected" : "Tap to send profile")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if sharingService.connectedPeers.contains(peer) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button(action: {
                                    onShareToPeer(peer)
                                }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                                .disabled(!sharingService.isDeviceNearby)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Proximity Status
            if sharingService.isAdvertising || sharingService.isBrowsing {
                HStack {
                    Image(systemName: sharingService.isDeviceNearby ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(sharingService.isDeviceNearby ? .green : .orange)
                    Text(sharingService.proximityStatus)
                        .font(.caption)
                        .foregroundColor(sharingService.isDeviceNearby ? .green : .orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            
            if let error = sharingService.sharingError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
}

struct PlayerProfileSection: View {
    @Binding var playerName: String
    @Binding var playerGrip: String
    @Binding var playerHandedness: String
    @Binding var playerBlade: String
    @Binding var playerForehandRubber: String
    @Binding var playerBackhandRubber: String
    @Binding var playerEloRating: Int
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
                    ProfileEloRatingField(
                        label: "Elo Rating",
                        value: $playerEloRating
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
    @Binding var opponentEloRating: Int
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
                    ProfileEloRatingField(
                        label: "Elo Rating",
                        value: $opponentEloRating
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

struct ProfileEloRatingField: View {
    let label: String
    @Binding var value: Int // 1000-9999 (default 1000 for unrated players)
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("1000-9999", text: $textValue)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .focused($isFocused)
                .onChange(of: textValue) { _, newValue in
                    // Only allow digits, max 4 characters
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count <= 4 {
                        textValue = filtered
                        // Update binding if valid 4-digit number
                        if let intValue = Int(filtered), intValue >= 1000 && intValue <= 9999 {
                            value = intValue
                        } else if filtered.isEmpty {
                            value = 1000 // Default to 1000 if empty
                        }
                    } else {
                        textValue = String(filtered.prefix(4))
                    }
                }
                .onChange(of: value) { _, newValue in
                    // Sync text when value changes externally
                    if newValue >= 1000 && newValue <= 9999 {
                        textValue = "\(newValue)"
                    } else {
                        value = 1000 // Ensure value is always valid
                        textValue = "1000"
                    }
                }
                .onAppear {
                    // Initialize text from value, default to 1000 if invalid
                    if value >= 1000 && value <= 9999 {
                        textValue = "\(value)"
                    } else {
                        value = 1000
                        textValue = "1000"
                    }
                }
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





