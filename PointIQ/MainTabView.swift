//
//  MainTabView.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Match", systemImage: "figure.table.tennis")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            LegendView()
                .tabItem {
                    Label("Legend", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Match.self, Game.self, Point.self], inMemory: true)
}

