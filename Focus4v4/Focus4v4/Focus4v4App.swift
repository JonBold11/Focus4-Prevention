//
//  Focus4v4App.swift
//  Focus4v4
//
//  Created by Jonathan Serrano on 4/2/25.
//

import SwiftUI
import Focus4Shared
import FirebaseCore
import FirebaseAnalytics

@main
struct Focus4v4App: App {
    @Environment(\.scenePhase) private var scenePhase
    let persistenceController = PersistenceController.shared
    
    // Shared connectivity manager for Watch-iPhone communication
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Verify app group access on launch
        let appGroupAccess = SharedConfiguration.verifyAppGroupAccess()
        print("App Group access verified: \(appGroupAccess)")
        
        // Log app launch event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    var body: some Scene {
        WindowGroup {
            // Use the AuthenticationView instead of ContentView directly
            // It will show ContentView when authenticated
            AuthenticationView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(connectivityManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                persistenceController.saveContext()
            } else if newPhase == .active {
                // Log app foreground event
                Analytics.logEvent("app_foregrounded", parameters: nil)
            }
        }
    }
}
