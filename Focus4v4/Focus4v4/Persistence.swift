//
//  Persistence.swift
//  Focus4v4
//
//  Created by Jonathan Serrano on 4/2/25.
//

import CoreData
import Focus4Shared

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer
    
    // Public access to viewContext for easier use throughout the app
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Focus4v4")
        
        // Configure the container for App Group and CloudKit
        configureContainer(inMemory: inMemory)
        
        // Configure automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private func configureContainer(inMemory: Bool) {
        // For in-memory store during previews or testing
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            loadPersistentStores()
            return
        }
        
        // Get the shared container URL from the app group
        guard let sharedContainerURL = SharedConfiguration.sharedContainerURL else {
            fatalError("Failed to access shared container URL for app group: \(SharedConfiguration.appGroupIdentifier)")
        }
        
        // Create a URL for the Core Data store within the shared container
        let storeURL = sharedContainerURL.appendingPathComponent("Focus4v4.sqlite")
        
        // Configure the CloudKit container for sync
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        // Update the store URL to use the shared container
        description.url = storeURL
        
        // Configure CloudKit integration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.jonathanserrano.Focus4v4"
        )
        
        // Additional configuration for better sync performance
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Load the persistent stores
        loadPersistentStores()
    }
    
    private func loadPersistentStores() {
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Persistent store failed to load: \(error), \(error.userInfo)")
            }
            print("Successfully loaded persistent store: \(storeDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Saves changes if there are any to save
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
                // In a real app, you would present an error to the user
            }
        }
    }
    
    /// Creates a background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
