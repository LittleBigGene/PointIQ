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
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            ContentView()
                .tabItem {
                    Label("Match", systemImage: "sportscourt")
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

