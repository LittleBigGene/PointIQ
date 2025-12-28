//
//  PointIQApp.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI
import SwiftData

@main
struct PointIQApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Match.self,
            Game.self,
            Point.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Check if this is a loadIssue error (schema mismatch)
            let errorDescription = String(describing: error)
            let isLoadIssue = errorDescription.contains("loadIssueModelContainer") || 
                             errorDescription.contains("loadIssue")
            
            if isLoadIssue {
                print("Schema mismatch detected. Resetting SwiftData store...")
                print("Error: \(error)")
                
                // Delete the default SwiftData store files
                let fileManager = FileManager.default
                if let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let defaultStoreURL = documentsURL.appendingPathComponent("default.store")
                    let defaultStoreShmURL = documentsURL.appendingPathComponent("default.store-shm")
                    let defaultStoreWalURL = documentsURL.appendingPathComponent("default.store-wal")
                    
                    // Try to delete all possible store files
                    for storeFileURL in [defaultStoreURL, defaultStoreShmURL, defaultStoreWalURL] {
                        if fileManager.fileExists(atPath: storeFileURL.path) {
                            do {
                                try fileManager.removeItem(at: storeFileURL)
                                print("Deleted store file: \(storeFileURL.lastPathComponent)")
                            } catch {
                                print("Failed to delete \(storeFileURL.lastPathComponent): \(error)")
                            }
                        }
                    }
                }
                
                // Try to create a new container
                do {
                    return try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch {
                    print("Error creating ModelContainer after reset: \(error)")
                    fatalError("Could not create ModelContainer after reset: \(error)")
                }
            } else {
                // For other errors, provide detailed info
                print("Error creating ModelContainer: \(error)")
                print("Error details: \(error.localizedDescription)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
