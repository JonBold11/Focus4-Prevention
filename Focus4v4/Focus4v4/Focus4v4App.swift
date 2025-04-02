//
//  Focus4v4App.swift
//  Focus4v4
//
//  Created by Jonathan Serrano on 4/2/25.
//

import SwiftUI

@main
struct Focus4v4App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
