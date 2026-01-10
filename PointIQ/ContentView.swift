//
//  ContentView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.startDate, order: .reverse) private var matches: [Match]
    @AppStorage("currentMatchID") private var currentMatchIDString: String = ""
    @State private var currentMatch: Match?
    @State private var currentGame: Game?
    @State private var lastPoint: Point?
    @State private var isVoiceInputActive = false
    @State private var showResetMatchConfirmation = false
    @State private var manualSwapOverride: Bool = false
    @State private var isUploadingMatch = false
    @State private var uploadError: String?
    @State private var showUploadError = false
    @State private var restoredMatchID: UUID? // Track which match we've restored points for
    @AppStorage("pointHistoryHeightRatio") private var pointHistoryHeightRatio: Double = 0.55
    @State private var showAddToHistoryDialog = false
    @State private var opponentNameInput: String = ""
    @State private var matchNotesInput: String = ""
    @State private var pendingResetAfterHistory = false
    @State private var matchToResetAfterHistory: Match? = nil
    
    // Profile data for uploading
    @AppStorage("playerName") private var name: String = "YOU"
    @AppStorage("playerGrip") private var playerGrip: String = "Shakehand"
    @AppStorage("playerHandedness") private var playerHandedness: String = "Right-handed"
    @AppStorage("playerBlade") private var playerBlade: String = ""
    @AppStorage("playerForehandRubber") private var playerForehandRubber: String = ""
    @AppStorage("playerBackhandRubber") private var playerBackhandRubber: String = ""
    @AppStorage("playerEloRating") private var playerEloRating: Int = 1000 // Default for unrated players
    @AppStorage("playerHomeClub") private var playerHomeClub: String = ""
    
    @AppStorage("opponentName") private var opponentName: String = ""
    @AppStorage("opponentGrip") private var opponentGrip: String = "Shakehand"
    @AppStorage("opponentHandedness") private var opponentHandedness: String = "Right-handed"
    @AppStorage("opponentBlade") private var opponentBlade: String = ""
    @AppStorage("opponentForehandRubber") private var opponentForehandRubber: String = ""
    @AppStorage("opponentBackhandRubber") private var opponentBackhandRubber: String = ""
    @AppStorage("opponentEloRating") private var opponentEloRating: Int = 1000 // Default for unrated players
    @AppStorage("opponentHomeClub") private var opponentHomeClub: String = ""
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // MARK: - Translation Helpers
    
    private func resetMatchText(for language: Language) -> String {
        switch language {
        case .english: return "Reset Match"
        case .japanese: return "試合リセット"
        case .chinese: return "重置比賽"
        }
    }
    
    private func cancelText(for language: Language) -> String {
        switch language {
        case .english: return "Cancel"
        case .japanese: return "キャンセル"
        case .chinese: return "取消"
        }
    }
    
    private func addToHistoryText(for language: Language) -> String {
        switch language {
        case .english: return "Add to History"
        case .japanese: return "履歴に追加"
        case .chinese: return "加入歷史"
        }
    }
    
    private func resetText(for language: Language) -> String {
        switch language {
        case .english: return "Reset"
        case .japanese: return "リセット"
        case .chinese: return "重置"
        }
    }
    
    private func resetMatchMessageText(for language: Language) -> String {
        switch language {
        case .english: return "Are you sure you want to reset the match? This will delete the current match locally and start a new one."
        case .japanese: return "試合をリセットしてもよろしいですか？現在の試合がローカルで削除され、新しい試合が開始されます。"
        case .chinese: return "確定要重置比賽嗎？這將刪除當前比賽並開始新的比賽。"
        }
    }
    
    private func uploadErrorText(for language: Language) -> String {
        switch language {
        case .english: return "Upload Error"
        case .japanese: return "アップロードエラー"
        case .chinese: return "上傳錯誤"
        }
    }
    
    private func okText(for language: Language) -> String {
        switch language {
        case .english: return "OK"
        case .japanese: return "OK"
        case .chinese: return "確定"
        }
    }
    
    private func failedToUploadText(for language: Language, error: String) -> String {
        switch language {
        case .english: return "Failed to upload match: \(error)"
        case .japanese: return "試合のアップロードに失敗: \(error)"
        case .chinese: return "上傳比賽失敗: \(error)"
        }
    }
    
    private func savingProfilesText(for language: Language) -> String {
        switch language {
        case .english: return "Saving profiles and uploading match..."
        case .japanese: return "プロフィールを保存して試合をアップロード中..."
        case .chinese: return "正在保存個人資料並上傳比賽..."
        }
    }
    
    private func enterOpponentNameText(for language: Language) -> String {
        switch language {
        case .english: return "Enter Opponent Name"
        case .japanese: return "相手の名前を入力"
        case .chinese: return "輸入對手名稱"
        }
    }
    
    private func opponentNamePlaceholderText(for language: Language) -> String {
        switch language {
        case .english: return "Opponent name"
        case .japanese: return "相手の名前"
        case .chinese: return "對手名稱"
        }
    }
    
    private func saveText(for language: Language) -> String {
        switch language {
        case .english: return "Save"
        case .japanese: return "保存"
        case .chinese: return "保存"
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                VStack(spacing: 0) {
                    // Top Section: Official Scoreboard
                    ScoreboardView(
                        match: currentMatch,
                        game: currentGame,
                        modelContext: modelContext,
                        isLandscape: isLandscape,
                        manualSwapOverride: $manualSwapOverride,
                        onStartNewGame: {
                            startNewGame()
                        },
                        onResetMatch: {
                            showResetMatchConfirmation = true
                        },
                        onResetMatchDirect: {
                            resetMatch()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, isLandscape ? 20 : 0) // Move scoreboard down in landscape
#if os(iOS) || os(tvOS) || os(visionOS)
                    .background(Color(UIColor.systemBackground))
#elseif os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
#else
                    .background(Color.background)
#endif
                    
                    if !isLandscape {
                        Divider()
                        
                        // Middle Section: Point History
                        PointHistoryView(
                            match: currentMatch,
                            game: currentGame
                        )
                        .frame(height: geometry.size.height * pointHistoryHeightRatio)
                        .background(Color.secondary.opacity(0.05))
                        
                        // Resizable divider
                        ResizableDivider(
                            heightRatio: $pointHistoryHeightRatio,
                            totalHeight: geometry.size.height,
                            topSectionHeight: geometry.size.height * 0.20
                        )
                        
                        // Bottom Section: Quick Logging Buttons
                        QuickLoggingView(
                            currentMatch: $currentMatch,
                            currentGame: $currentGame,
                            lastPoint: $lastPoint,
                            isVoiceInputActive: $isVoiceInputActive,
                            pointHistoryHeightRatio: pointHistoryHeightRatio,
                            manualSwapOverride: $manualSwapOverride,
                            onPointLogged: { point in
                                logPoint(point)
                            },
                            onUndo: {
                                undoLastPoint()
                            }
                        )
                        .frame(height: geometry.size.height * (1.0 - 0.20 - pointHistoryHeightRatio))
                    }
                }
            }
        }
        .onAppear {
            // Restore current match from stored ID
            restoreCurrentMatch()
        }
        .onChange(of: currentMatch?.id) { _, newID in
            // Save current match ID when it changes
            if let id = newID {
                currentMatchIDString = id.uuidString
            } else {
                currentMatchIDString = ""
            }
        }
        .alert(resetMatchText(for: selectedLanguage), isPresented: $showResetMatchConfirmation) {
            Button(cancelText(for: selectedLanguage), role: .cancel) { }
            Button(addToHistoryText(for: selectedLanguage)) {
                // Store match reference before showing dialog
                matchToResetAfterHistory = currentMatch
                // Pre-fill with existing opponent name if available
                opponentNameInput = opponentName
                matchNotesInput = currentMatch?.notes ?? ""
                pendingResetAfterHistory = true
                showAddToHistoryDialog = true
            }
            Button(resetText(for: selectedLanguage), role: .destructive) {
                resetMatch()
            }
        } message: {
            Text(resetMatchMessageText(for: selectedLanguage))
        }
        .alert(uploadErrorText(for: selectedLanguage), isPresented: $showUploadError) {
            Button(okText(for: selectedLanguage), role: .cancel) {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text(failedToUploadText(for: selectedLanguage, error: error))
            }
        }
        .sheet(isPresented: $showAddToHistoryDialog) {
            AddToHistorySheet(
                opponentName: $opponentNameInput,
                matchNotes: $matchNotesInput,
                selectedLanguage: selectedLanguage,
                onCancel: {
                    opponentNameInput = ""
                    matchNotesInput = ""
                    pendingResetAfterHistory = false
                    matchToResetAfterHistory = nil
                    showAddToHistoryDialog = false
                },
                onSave: {
                    // Match notes are required, so we only save if it's not empty
                    guard !matchNotesInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return
                    }
                    // Save the match reference before ending it
                    let matchToReset = matchToResetAfterHistory ?? currentMatch
                    let opponentNameForUpload = opponentNameInput.isEmpty ? opponentName : opponentNameInput
                    
                    // End the match first (sets endDate and saves)
                    endCurrentMatch(
                        opponentName: opponentNameInput.isEmpty ? nil : opponentNameInput,
                        matchNotes: matchNotesInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    // Ensure match is saved before uploading
                    if let match = matchToReset {
                        do {
                            try modelContext.save()
                            print("✅ Match saved to SwiftData before upload")
                        } catch {
                            print("❌ Error saving match to SwiftData: \(error)")
                        }
                        
                        // Upload to Supabase if configured (background upload)
                        // Upload AFTER endCurrentMatch so match has endDate set
                        if SupabaseConfig.isConfigured {
                            print("📤 Starting Supabase upload for match: \(match.id)")
                            uploadMatchToSupabase(match: match, opponentName: opponentNameForUpload)
                        } else {
                            print("⚠️ Supabase upload skipped - not configured")
                        }
                    } else {
                        print("⚠️ No match to upload")
                    }
                    
                    opponentNameInput = ""
                    matchNotesInput = ""
                    showAddToHistoryDialog = false
                    // If this was triggered from reset, clear current match state and start new match
                    // Don't delete the match - it should remain in history
                    if pendingResetAfterHistory {
                        pendingResetAfterHistory = false
                        matchToResetAfterHistory = nil
                        // Clear current match state and start a new match
                        currentGame = nil
                        currentMatch = nil
                        lastPoint = nil
                        restoredMatchID = nil
                        // Clear local point history storage
                        PointHistoryStorage.shared.clearAllPoints()
                        // Clear opponent information (player profile persists)
                        clearOpponentInformation()
                        // Start a new match
                        startNewMatch()
                    }
                }
            )
        }
        .overlay {
            if isUploadingMatch {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(savingProfilesText(for: selectedLanguage))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(24)
#if os(iOS) || os(tvOS) || os(visionOS)
                    .background(Color(UIColor.systemBackground))
#elseif os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
#else
                    .background(Color.background)
#endif
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    private func restoreCurrentMatch() {
        // Try to restore the current match from stored ID
        if !currentMatchIDString.isEmpty,
           let matchID = UUID(uuidString: currentMatchIDString),
           let match = matches.first(where: { $0.id == matchID }),
           match.isActive {
            currentMatch = match
            currentGame = match.currentGame
            
            // Restore points from local storage to SwiftData only once per match
            if restoredMatchID != match.id {
                restorePointsFromStorage()
                restoredMatchID = match.id
            }
        } else {
            // No valid stored match, start a new one
            if currentMatch == nil {
                startNewMatch()
            } else {
                currentGame = currentMatch?.currentGame
            }
        }
    }
    
    private func restorePointsFromStorage() {
        guard let match = currentMatch else { return }
        
        let storedPoints = PointHistoryStorage.shared.loadAllPoints()
        guard !storedPoints.isEmpty else { return }
        
        // Collect all existing point IDs from all games
        var existingPointIDs = Set<String>()
        if let games = match.games {
            for game in games {
                if let points = game.points {
                    existingPointIDs.formUnion(points.map { $0.uniqueID })
                }
            }
        }
        
        // Group points by gameNumber to ensure games exist
        var gamesByNumber: [Int: Game] = [:]
        if let existingGames = match.games {
            for game in existingGames {
                gamesByNumber[game.gameNumber] = game
            }
        }
        
        for pointData in storedPoints {
            // Skip if point already exists in SwiftData
            if existingPointIDs.contains(pointData.id) {
                continue
            }
            
            // Find or create the game for this point
            let game: Game
            let gameNumber = pointData.gameNumber ?? 1
            
            if let existingGame = gamesByNumber[gameNumber] {
                game = existingGame
            } else {
                // Create game if it doesn't exist
                // Determine who serves first: alternate after each game
                let previousGame = gamesByNumber[gameNumber - 1]
                let playerServesFirst = GameSideSwap.determinePlayerServesFirst(gameNumber: gameNumber, previousGame: previousGame)
                
                let newGame = Game(match: match, gameNumber: gameNumber, playerServesFirst: playerServesFirst)
                modelContext.insert(newGame)
                gamesByNumber[gameNumber] = newGame
                game = newGame
                
                // Update currentGame if this is the highest game number
                if gameNumber >= (currentGame?.gameNumber ?? 0) {
                    currentGame = game
                }
            }
            
            // Convert PointData back to Point
            guard let outcome = Outcome(rawValue: pointData.outcome) else { continue }
            // strokeTokens are already strings (SS, Banana, Dragon, etc.)
            
            let point = Point(
                timestamp: pointData.timestamp,
                strokeTokens: pointData.strokeTokens,
                outcome: outcome,
                match: match,
                game: game,
                serveType: pointData.serveType,
                receiveType: pointData.receiveType,
                rallyTypes: pointData.rallyTypes
            )
            
            modelContext.insert(point)
        }
        
        do {
            try modelContext.save()
            
            // Ensure currentGame is set correctly after restoration
            if let match = currentMatch {
                // Find the game with the highest number that has points, or use the active game
                if let games = match.games {
                    // First, try to find a game with points
                    let gamesWithPoints = games.filter { game in
                        // Force relationship to load by accessing it
                        let pointCount = game.points?.count ?? 0
                        return pointCount > 0
                    }
                    
                    if let latestGame = gamesWithPoints.sorted(by: { $0.gameNumber > $1.gameNumber }).first {
                        currentGame = latestGame
                    } else if let activeGame = match.currentGame {
                        currentGame = activeGame
                    } else if let firstGame = games.first {
                        currentGame = firstGame
                    }
                }
            }
        } catch {
            print("Error restoring points from storage: \(error)")
        }
    }
    
    private func startNewMatch() {
        let newMatch = Match()
        modelContext.insert(newMatch)
        currentMatch = newMatch
        restoredMatchID = nil // Reset for new match
        startNewGame()
        try? modelContext.save()
        
        // Restore points from local storage if they exist
        restorePointsFromStorage()
        restoredMatchID = newMatch.id
    }
    
    private func startNewGame() {
        guard let match = currentMatch else { return }
        let gameNumber = (match.games?.count ?? 0) + 1
        
        // Determine who serves first: alternate after each game
        let previousGame = match.games?.sorted(by: { $0.gameNumber > $1.gameNumber }).first
        let playerServesFirst = GameSideSwap.determinePlayerServesFirst(previousGame: previousGame)
        
        let newGame = Game(match: match, gameNumber: gameNumber, playerServesFirst: playerServesFirst)
        modelContext.insert(newGame)
        currentGame = newGame
        try? modelContext.save()
    }
    
    private func endCurrentMatch(opponentName: String? = nil, matchNotes: String? = nil) {
        if let match = currentMatch {
            // Set opponent name if provided
            if let name = opponentName, !name.isEmpty {
                match.opponentName = name
            }
            // Set match notes (notes) if provided
            if let name = matchNotes, !name.isEmpty {
                match.notes = name
            }
            // End current game if active
            if let game = currentGame {
                game.endDate = Date()
            }
            // End the match
            match.endDate = Date()
            
            // Save the match before clearing currentMatch reference
            do {
                try modelContext.save()
            } catch {
                print("Error saving match to history: \(error)")
            }
        }
        currentGame = nil
        currentMatch = nil
    }
    
    private func logPoint(_ point: Point) {
        guard let match = currentMatch, let game = currentGame else { return }
        
        // Set relationships before inserting
        point.match = match
        point.game = game
        modelContext.insert(point)
        lastPoint = point
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving point: \(error)")
        }
        
        // Save point to local storage
        PointHistoryStorage.shared.savePoint(point, gameNumber: game.gameNumber)
        
        // Check if game is complete
        if game.isComplete {
            endCurrentGame()
        }
    }
    
    private func endCurrentGame() {
        guard let game = currentGame else { return }
        game.endDate = Date()
        currentGame = nil
        
        // Automatically start a new game
        if currentMatch != nil {
            startNewGame()
        }
        
        try? modelContext.save()
    }
    
    private func undoLastPoint() {
        guard let point = lastPoint else { return }
        let pointID = point.uniqueID
        modelContext.delete(point)
        lastPoint = nil
        try? modelContext.save()
        
        // Remove point from local storage by ID
        PointHistoryStorage.shared.removePoint(byID: pointID)
    }
    
    private func uploadMatchToSupabase(match: Match, opponentName: String) {
        // Check if Supabase is configured
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase not configured, skipping upload")
            return
        }
        
        // Force load relationships before uploading
        let gamesCount = match.games?.count ?? 0
        let pointsCount = match.points?.count ?? 0
        
        print("📤 Uploading match to Supabase:")
        print("   Match ID: \(match.id)")
        print("   Match Notes: \(match.notes ?? "nil")")
        print("   Opponent Name: \(opponentName)")
        print("   Games: \(gamesCount)")
        print("   Points: \(pointsCount)")
        print("   End Date: \(match.endDate?.description ?? "nil")")
        
        // Ensure match has endDate set (required for completed matches)
        guard match.endDate != nil else {
            print("❌ Match does not have endDate set, cannot upload")
            return
        }
        
        Task {
            do {
                print("📤 Step 1: Saving player profile...")
                // 1. Save player profile
                try await SupabaseService.shared.savePlayerProfile(
                    name: name,
                    grip: playerGrip,
                    handedness: playerHandedness,
                    blade: playerBlade,
                    forehandRubber: playerForehandRubber,
                    backhandRubber: playerBackhandRubber,
                    eloRating: playerEloRating >= 1000 ? playerEloRating : nil,
                    homeClub: playerHomeClub
                )
                print("✅ Player profile saved")
                
                // 2. Save opponent profile if opponent data exists
                var opponentProfileId: String? = nil
                if !opponentName.isEmpty {
                    print("📤 Step 2: Saving opponent profile...")
                    opponentProfileId = try await SupabaseService.shared.saveOpponentProfile(
                        name: opponentName,
                        grip: opponentGrip,
                        handedness: opponentHandedness,
                        blade: opponentBlade,
                        forehandRubber: opponentForehandRubber,
                        backhandRubber: opponentBackhandRubber,
                        eloRating: opponentEloRating >= 1000 ? opponentEloRating : nil,
                        homeClub: opponentHomeClub
                    )
                    print("✅ Opponent profile saved: \(opponentProfileId ?? "nil")")
                } else {
                    print("⏭️ Skipping opponent profile (no name)")
                }
                
                // 3. Upload the match (with opponent profile reference if available)
                print("📤 Step 3: Uploading match...")
                try await SupabaseService.shared.uploadMatch(match, opponentProfileId: opponentProfileId)
                
                print("✅ Match successfully uploaded to Supabase: \(match.id)")
            } catch {
                print("❌ Error uploading match to Supabase:")
                print("   Error: \(error)")
                print("   Localized: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                    print("   UserInfo: \(nsError.userInfo)")
                }
                // Don't show error to user for background uploads
            }
        }
    }
    
    private func shareAndResetMatch() {
        guard let match = currentMatch else { return }
        
        // Check if Supabase is configured
        guard SupabaseConfig.isConfigured else {
            uploadError = "Supabase is not configured. Please configure it in Settings."
            showUploadError = true
            return
        }
        
        isUploadingMatch = true
        
        Task {
            do {
                // 1. Save player profile
                try await SupabaseService.shared.savePlayerProfile(
                    name: name,
                    grip: playerGrip,
                    handedness: playerHandedness,
                    blade: playerBlade,
                    forehandRubber: playerForehandRubber,
                    backhandRubber: playerBackhandRubber,
                    eloRating: playerEloRating >= 1000 ? playerEloRating : nil,
                    homeClub: playerHomeClub
                )
                
                // 2. Save opponent profile if opponent data exists
                var opponentProfileId: String? = nil
                if !opponentName.isEmpty {
                    opponentProfileId = try await SupabaseService.shared.saveOpponentProfile(
                        name: opponentName,
                        grip: opponentGrip,
                        handedness: opponentHandedness,
                        blade: opponentBlade,
                        forehandRubber: opponentForehandRubber,
                        backhandRubber: opponentBackhandRubber,
                        eloRating: opponentEloRating >= 1000 ? opponentEloRating : nil,
                        homeClub: opponentHomeClub
                    )
                }
                
                // 3. Upload the match (with opponent profile reference if available)
                try await SupabaseService.shared.uploadMatch(match, opponentProfileId: opponentProfileId)
                
                // Upload successful, now reset
                await MainActor.run {
                    isUploadingMatch = false
                    resetMatch()
                }
            } catch {
                await MainActor.run {
                    isUploadingMatch = false
                    uploadError = error.localizedDescription
                    showUploadError = true
                }
            }
        }
    }
    
    private func resetMatch(match: Match? = nil) {
        // Use provided match or current match
        let matchToDelete = match ?? currentMatch
        
        // Delete the match and all its associated data
        if let match = matchToDelete {
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
            currentGame = nil
            currentMatch = nil
            lastPoint = nil
            restoredMatchID = nil // Reset flag when match is reset
            try? modelContext.save()
            
            // Clear local point history storage
            PointHistoryStorage.shared.clearAllPoints()
            
            // Clear opponent information (player profile persists)
            clearOpponentInformation()
            
            // Start a new match
            startNewMatch()
        }
    }
    
    private func clearOpponentInformation() {
        // Clear all opponent AppStorage values
        UserDefaults.standard.removeObject(forKey: "opponentName")
        UserDefaults.standard.removeObject(forKey: "opponentGrip")
        UserDefaults.standard.removeObject(forKey: "opponentHandedness")
        UserDefaults.standard.removeObject(forKey: "opponentBlade")
        UserDefaults.standard.removeObject(forKey: "opponentForehandRubber")
        UserDefaults.standard.removeObject(forKey: "opponentBackhandRubber")
        opponentEloRating = 1000 // Reset to default for unrated players
        UserDefaults.standard.removeObject(forKey: "opponentHomeClub")
    }
}

// MARK: - Add to History Sheet

struct AddToHistorySheet: View {
    @Binding var opponentName: String
    @Binding var matchNotes: String
    let selectedLanguage: Language
    let onCancel: () -> Void
    let onSave: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case opponentName
        case matchNotes
    }
    
    private func enterOpponentNameText(for language: Language) -> String {
        switch language {
        case .english: return "Enter Opponent Name"
        case .japanese: return "相手の名前を入力"
        case .chinese: return "輸入對手名稱"
        }
    }
    
    private func opponentNamePlaceholderText(for language: Language) -> String {
        switch language {
        case .english: return "Opponent name"
        case .japanese: return "相手の名前"
        case .chinese: return "對手名稱"
        }
    }
    
    private func matchNotesPlaceholderText(for language: Language) -> String {
        switch language {
        case .english: return "Match Notes"
        case .japanese: return "試合メモ"
        case .chinese: return "比賽筆記"
        }
    }
    
    private func matchNotesRequiredText(for language: Language) -> String {
        switch language {
        case .english: return "Match notes are required"
        case .japanese: return "試合メモは必須です"
        case .chinese: return "比賽筆記為必填"
        }
    }
    
    private var ismatchNotesValid: Bool {
        !matchNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addToHistoryText(for language: Language) -> String {
        switch language {
        case .english: return "Add to History"
        case .japanese: return "履歴に追加"
        case .chinese: return "加入歷史"
        }
    }
    
    private func cancelText(for language: Language) -> String {
        switch language {
        case .english: return "Cancel"
        case .japanese: return "キャンセル"
        case .chinese: return "取消"
        }
    }
    
    private func saveText(for language: Language) -> String {
        switch language {
        case .english: return "Save"
        case .japanese: return "保存"
        case .chinese: return "保存"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(opponentNamePlaceholderText(for: selectedLanguage), text: $opponentName)
                        .focused($focusedField, equals: .opponentName)
                    
                    TextField(matchNotesPlaceholderText(for: selectedLanguage), text: $matchNotes)
                        .focused($focusedField, equals: .matchNotes)
                } header: {
                    Text(addToHistoryText(for: selectedLanguage))
                } footer: {
                    if !ismatchNotesValid && !matchNotes.isEmpty {
                        Text(matchNotesRequiredText(for: selectedLanguage))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(enterOpponentNameText(for: selectedLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelText(for: selectedLanguage)) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveText(for: selectedLanguage)) {
                        onSave()
                    }
                    .disabled(!ismatchNotesValid)
                }
            }
            .onAppear {
                focusedField = .opponentName
            }
        }
    }
}

#Preview(traits: .portrait) {
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}
