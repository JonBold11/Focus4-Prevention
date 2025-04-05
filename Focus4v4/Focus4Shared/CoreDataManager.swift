import CoreData
import SwiftUI

/// A class that provides helper methods for working with Core Data
public class CoreDataManager {
    // MARK: - Properties
    
    /// The shared singleton instance
    public static let shared = CoreDataManager()
    
    /// The Core Data container - accessible through PersistenceController
    private var container: NSPersistentCloudKitContainer {
        return PersistenceController.shared.container
    }
    
    /// The main view context
    public var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Entity Creation Methods
    
    /// Creates a new UserProfile with the given parameters
    /// - Parameters:
    ///   - context: The managed object context to use, defaults to the view context
    ///   - firebaseUID: The Firebase user ID from authentication
    ///   - displayName: The user's display name
    ///   - phoneNumber: The user's phone number
    ///   - recoveryEmail: Optional recovery email
    /// - Returns: The newly created UserProfile
    public func createUserProfile(
        in context: NSManagedObjectContext? = nil,
        firebaseUID: String,
        displayName: String,
        phoneNumber: String,
        recoveryEmail: String? = nil
    ) -> UserProfile {
        let ctx = context ?? viewContext
        let profile = UserProfile(context: ctx)
        
        profile.id = UUID()
        profile.firebaseUID = firebaseUID
        profile.displayName = displayName
        profile.phoneNumber = phoneNumber
        profile.recoveryEmail = recoveryEmail
        profile.createdAt = Date()
        profile.updatedAt = Date()
        profile.lastActiveDate = Date()
        profile.accountStatus = "active"
        
        // Create default settings for the user
        let settings = UserSettings(context: ctx)
        settings.id = UUID()
        settings.createdAt = Date()
        settings.updatedAt = Date()
        settings.theme = "system"
        settings.defaultSessionDuration = 1500 // 25 minutes in seconds
        settings.enableFriction = true
        settings.frictionLevel = 2
        settings.enableHapticFeedback = true
        settings.enableNotifications = true
        settings.showCompletedTasks = false
        settings.syncAcrossDevices = true
        
        // Connect the settings to the user
        settings.user = profile
        profile.settings = settings
        
        saveContext(ctx)
        
        return profile
    }
    
    /// Creates a new Task with the given parameters
    /// - Parameters:
    ///   - context: The managed object context to use, defaults to the view context
    ///   - title: The task title
    ///   - details: Optional task details
    ///   - user: The user who owns the task
    ///   - category: Optional task category
    ///   - dueDate: Optional due date
    ///   - priority: Optional task priority (0-3)
    ///   - isImportant: Whether the task is marked as important
    ///   - estimatedDuration: Estimated duration in seconds, defaults to 25 minutes
    /// - Returns: The newly created Task
    public func createTask(
        in context: NSManagedObjectContext? = nil,
        title: String,
        details: String? = nil,
        user: UserProfile,
        category: String? = nil,
        dueDate: Date? = nil,
        priority: Int16 = 0,
        isImportant: Bool = false,
        estimatedDuration: Int32 = 1500
    ) -> Task {
        let ctx = context ?? viewContext
        let task = Task(context: ctx)
        
        task.id = UUID()
        task.title = title
        task.details = details
        task.user = user
        task.category = category
        task.dueDate = dueDate
        task.priority = priority
        task.isImportant = isImportant
        task.estimatedDuration = estimatedDuration
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isCompleted = false
        
        // Get the highest existing order and add 1
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try ctx.fetch(fetchRequest)
            let highestOrder = result.first?.order ?? 0
            task.order = highestOrder + 1
        } catch {
            task.order = 0
            print("Error getting highest task order: \(error)")
        }
        
        saveContext(ctx)
        
        return task
    }
    
    /// Creates a new FocusSession with the given parameters
    /// - Parameters:
    ///   - context: The managed object context to use, defaults to the view context
    ///   - user: The user who owns the session
    ///   - task: Optional task associated with the session
    ///   - title: Optional session title
    ///   - targetDuration: Target duration in seconds, defaults to 25 minutes
    /// - Returns: The newly created FocusSession
    public func createFocusSession(
        in context: NSManagedObjectContext? = nil,
        user: UserProfile,
        task: Task? = nil,
        title: String? = nil,
        targetDuration: Int32 = 1500
    ) -> FocusSession {
        let ctx = context ?? viewContext
        let session = FocusSession(context: ctx)
        
        session.id = UUID()
        session.user = user
        session.task = task
        session.title = title ?? task?.title ?? "Focus Session"
        session.targetDuration = targetDuration
        session.timeRemaining = targetDuration
        session.createdAt = Date()
        session.isActive = true
        session.isPaused = false
        session.isCompleted = false
        
        // Create statistics for the session
        let statistics = SessionStatistics(context: ctx)
        statistics.id = UUID()
        statistics.createdAt = Date()
        statistics.session = session
        statistics.totalFocusTime = 0
        statistics.totalPauseTime = 0
        statistics.pauseCount = 0
        statistics.frictionCount = 0
        statistics.distractionCount = 0
        
        session.statistics = statistics
        
        saveContext(ctx)
        
        return session
    }
    
    /// Creates a new FrictionEvent with the given parameters
    /// - Parameters:
    ///   - context: The managed object context to use, defaults to the view context
    ///   - session: The FocusSession associated with the friction event
    ///   - frictionLevel: The friction level (1-4)
    ///   - taskType: The type of friction task
    /// - Returns: The newly created FrictionEvent
    public func createFrictionEvent(
        in context: NSManagedObjectContext? = nil,
        session: FocusSession,
        frictionLevel: Int16,
        taskType: String
    ) -> FrictionEvent {
        let ctx = context ?? viewContext
        let frictionEvent = FrictionEvent(context: ctx)
        
        frictionEvent.id = UUID()
        frictionEvent.session = session
        frictionEvent.frictionLevel = frictionLevel
        frictionEvent.taskType = taskType
        frictionEvent.createdAt = Date()
        frictionEvent.isCompleted = false
        
        // Update statistics
        if let statistics = session.statistics {
            statistics.frictionCount += 1
        }
        
        saveContext(ctx)
        
        return frictionEvent
    }
    
    // MARK: - Fetch Methods
    
    /// Fetches a UserProfile by Firebase UID
    /// - Parameters:
    ///   - firebaseUID: The Firebase UID to search for
    ///   - context: The managed object context to use, defaults to the view context
    /// - Returns: The found UserProfile or nil if not found
    public func fetchUserProfile(
        withFirebaseUID firebaseUID: String,
        in context: NSManagedObjectContext? = nil
    ) -> UserProfile? {
        let ctx = context ?? viewContext
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try ctx.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    /// Fetches all tasks for a user
    /// - Parameters:
    ///   - user: The user whose tasks to fetch
    ///   - includeCompleted: Whether to include completed tasks
    ///   - context: The managed object context to use, defaults to the view context
    /// - Returns: An array of Task objects
    public func fetchTasks(
        for user: UserProfile,
        includeCompleted: Bool = false,
        in context: NSManagedObjectContext? = nil
    ) -> [Task] {
        let ctx = context ?? viewContext
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        if includeCompleted {
            fetchRequest.predicate = NSPredicate(format: "user == %@", user)
        } else {
            fetchRequest.predicate = NSPredicate(format: "user == %@ AND isCompleted == NO", user)
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "order", ascending: true)
        ]
        
        do {
            return try ctx.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    /// Fetches sessions for a user
    /// - Parameters:
    ///   - user: The user whose sessions to fetch
    ///   - limit: Maximum number of sessions to fetch
    ///   - context: The managed object context to use, defaults to the view context
    /// - Returns: An array of FocusSession objects
    public func fetchSessions(
        for user: UserProfile,
        limit: Int = 0,
        in context: NSManagedObjectContext? = nil
    ) -> [FocusSession] {
        let ctx = context ?? viewContext
        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        if limit > 0 {
            fetchRequest.fetchLimit = limit
        }
        
        do {
            return try ctx.fetch(fetchRequest)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    /// Fetches the active session for a user
    /// - Parameters:
    ///   - user: The user whose active session to fetch
    ///   - context: The managed object context to use, defaults to the view context
    /// - Returns: The active FocusSession or nil if not found
    public func fetchActiveSession(
        for user: UserProfile,
        in context: NSManagedObjectContext? = nil
    ) -> FocusSession? {
        let ctx = context ?? viewContext
        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@ AND isActive == YES", user)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try ctx.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching active session: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    /// Updates the user settings
    /// - Parameters:
    ///   - settings: The UserSettings object to update
    ///   - theme: The theme name
    ///   - defaultSessionDuration: The default session duration in seconds
    ///   - enableFriction: Whether friction is enabled
    ///   - frictionLevel: The friction level (1-4)
    ///   - enableHapticFeedback: Whether haptic feedback is enabled
    ///   - enableNotifications: Whether notifications are enabled
    ///   - showCompletedTasks: Whether to show completed tasks
    ///   - syncAcrossDevices: Whether to sync across devices
    ///   - context: The managed object context to use, defaults to the view context
    public func updateUserSettings(
        settings: UserSettings,
        theme: String? = nil,
        defaultSessionDuration: Int32? = nil,
        enableFriction: Bool? = nil,
        frictionLevel: Int16? = nil,
        enableHapticFeedback: Bool? = nil,
        enableNotifications: Bool? = nil,
        showCompletedTasks: Bool? = nil,
        syncAcrossDevices: Bool? = nil,
        in context: NSManagedObjectContext? = nil
    ) {
        let ctx = context ?? viewContext
        
        if let theme = theme {
            settings.theme = theme
        }
        
        if let defaultSessionDuration = defaultSessionDuration {
            settings.defaultSessionDuration = defaultSessionDuration
        }
        
        if let enableFriction = enableFriction {
            settings.enableFriction = enableFriction
        }
        
        if let frictionLevel = frictionLevel {
            settings.frictionLevel = min(max(frictionLevel, 1), 4)
        }
        
        if let enableHapticFeedback = enableHapticFeedback {
            settings.enableHapticFeedback = enableHapticFeedback
        }
        
        if let enableNotifications = enableNotifications {
            settings.enableNotifications = enableNotifications
        }
        
        if let showCompletedTasks = showCompletedTasks {
            settings.showCompletedTasks = showCompletedTasks
        }
        
        if let syncAcrossDevices = syncAcrossDevices {
            settings.syncAcrossDevices = syncAcrossDevices
        }
        
        settings.updatedAt = Date()
        
        saveContext(ctx)
    }
    
    /// Marks a task as completed
    /// - Parameters:
    ///   - task: The Task to mark as completed
    ///   - context: The managed object context to use, defaults to the view context
    public func completeTask(
        task: Task,
        in context: NSManagedObjectContext? = nil
    ) {
        let ctx = context ?? viewContext
        
        task.isCompleted = true
        task.completedDate = Date()
        task.updatedAt = Date()
        
        saveContext(ctx)
    }
    
    /// Updates a FocusSession with the current state
    /// - Parameters:
    ///   - session: The FocusSession to update
    ///   - isActive: Whether the session is active
    ///   - isPaused: Whether the session is paused
    ///   - isCompleted: Whether the session is completed
    ///   - timeRemaining: The time remaining in seconds
    ///   - pausedTime: The time spent paused in seconds
    ///   - context: The managed object context to use, defaults to the view context
    public func updateSession(
        session: FocusSession,
        isActive: Bool? = nil,
        isPaused: Bool? = nil,
        isCompleted: Bool? = nil,
        timeRemaining: Int32? = nil,
        pausedTime: Int32? = nil,
        in context: NSManagedObjectContext? = nil
    ) {
        let ctx = context ?? viewContext
        
        if let isActive = isActive {
            session.isActive = isActive
        }
        
        if let isPaused = isPaused {
            session.isPaused = isPaused
        }
        
        if let isCompleted = isCompleted {
            session.isCompleted = isCompleted
            
            if isCompleted {
                session.completionDate = Date()
                session.duration = session.targetDuration - (session.timeRemaining ?? 0)
                session.isActive = false
                session.isPaused = false
            }
        }
        
        if let timeRemaining = timeRemaining {
            session.timeRemaining = timeRemaining
        }
        
        if let pausedTime = pausedTime {
            session.pausedTime = pausedTime
        }
        
        saveContext(ctx)
    }
    
    /// Completes a friction event with user response
    /// - Parameters:
    ///   - frictionEvent: The FrictionEvent to complete
    ///   - userResponse: The user's response to the friction task
    ///   - responseTime: The time it took for the user to respond in seconds
    ///   - context: The managed object context to use, defaults to the view context
    public func completeFrictionEvent(
        frictionEvent: FrictionEvent,
        userResponse: String?,
        responseTime: Double,
        in context: NSManagedObjectContext? = nil
    ) {
        let ctx = context ?? viewContext
        
        frictionEvent.isCompleted = true
        frictionEvent.userResponse = userResponse
        frictionEvent.responseTime = responseTime
        frictionEvent.completionDate = Date()
        
        saveContext(ctx)
    }
    
    // MARK: - Helper Methods
    
    /// Saves the managed object context if it has changes
    /// - Parameter context: The context to save, defaults to the view context
    public func saveContext(_ context: NSManagedObjectContext? = nil) {
        let ctx = context ?? viewContext
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Creates a background context for performing operations off the main thread
    /// - Returns: A new background context
    public func createBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// Deletes an object from the managed object context
    /// - Parameters:
    ///   - object: The object to delete
    ///   - context: The managed object context to use, defaults to the view context
    public func delete(_ object: NSManagedObject, in context: NSManagedObjectContext? = nil) {
        let ctx = context ?? viewContext
        ctx.delete(object)
        saveContext(ctx)
    }
}

// MARK: - NSFetchRequest Extensions

extension NSFetchRequest where ResultType == FocusSession {
    static func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }
}

extension NSFetchRequest where ResultType == FrictionEvent {
    static func fetchRequest() -> NSFetchRequest<FrictionEvent> {
        return NSFetchRequest<FrictionEvent>(entityName: "FrictionEvent")
    }
}

extension NSFetchRequest where ResultType == SessionStatistics {
    static func fetchRequest() -> NSFetchRequest<SessionStatistics> {
        return NSFetchRequest<SessionStatistics>(entityName: "SessionStatistics")
    }
}

extension NSFetchRequest where ResultType == Task {
    static func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }
}

extension NSFetchRequest where ResultType == UserProfile {
    static func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }
}

extension NSFetchRequest where ResultType == UserSettings {
    static func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }
} 