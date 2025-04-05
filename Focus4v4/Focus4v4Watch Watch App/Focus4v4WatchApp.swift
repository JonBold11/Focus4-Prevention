//
//  Focus4v4WatchApp.swift
//  Focus4v4Watch Watch App
//
//  Created by Jonathan Serrano on 4/2/25.
//

import SwiftUI
import Focus4Shared
import FirebaseCore
import FirebaseAnalytics

@main
struct Focus4v4WatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    // Access to the shared persistence controller for Core Data
    let persistenceController = PersistenceController.shared
    
    // Access to the shared connectivity manager for Watch-iPhone communication
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Verify app group access on launch
        let appGroupAccess = SharedConfiguration.verifyAppGroupAccess()
        print("App Group access verified: \(appGroupAccess)")
        
        // Log watch app launch event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(connectivityManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                persistenceController.saveContext()
            } else if newPhase == .active {
                // Log app foreground event
                Analytics.logEvent("watch_app_foregrounded", parameters: nil)
            }
        }
    }
}
