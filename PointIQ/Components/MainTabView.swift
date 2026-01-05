//
//  MainTabView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // MARK: - Translation Helpers
    
    private func playTabText(for language: Language) -> String {
        switch language {
        case .english: return "Play"
        case .japanese: return "プレイ"
        case .chinese: return "比賽"
        }
    }
    
    private func profileTabText(for language: Language) -> String {
        switch language {
        case .english: return "Profile"
        case .japanese: return "プロフィール"
        case .chinese: return "個人資料"
        }
    }
    
    private func historyTabText(for language: Language) -> String {
        switch language {
        case .english: return "History"
        case .japanese: return "履歴"
        case .chinese: return "歷史"
        }
    }
    
    private func legendTabText(for language: Language) -> String {
        switch language {
        case .english: return "Legend"
        case .japanese: return "凡例"
        case .chinese: return "圖例"
        }
    }
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(playTabText(for: selectedLanguage), systemImage: "figure.table.tennis")
                }
            ProfileView()
                .tabItem {
                    Label(profileTabText(for: selectedLanguage), systemImage: "person.circle")
                }
            LegendView()
                .tabItem {
                    Label(legendTabText(for: selectedLanguage), systemImage: "info.circle")
                }
            HistoryView()
                .tabItem {
                    Label(historyTabText(for: selectedLanguage), systemImage: "clock")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}

