import Foundation
import CoreData
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#endif

public class DataSynchronizationService {
    // MARK: - Properties
    
    /// The shared instance for the app
    public static let shared = DataSynchronizationService()
    
    /// The Core Data manager
    private let coreDataManager = CoreDataManager.shared
    
    /// Firebase Firestore reference (if available)
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    
    /// Background sync queue
    private let syncQueue = DispatchQueue(label: "com.jonathanserrano.Focus4v4.dataSyncQueue", qos: .utility)
    
    /// Sync status publisher
    private let syncStatusSubject = PassthroughSubject<SyncStatus, Never>()
    public var syncStatus: AnyPublisher<SyncStatus, Never> {
        return syncStatusSubject.eraseToAnyPublisher()
    }
    
    /// Current sync operation
    private var currentSync: AnyCancellable?
    
    /// Last sync time
    private var lastSyncTime: Date? {
        get {
            return UserDefaults.standard.object(forKey: "lastSyncTime") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastSyncTime")
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Performs a full synchronization of data
    public func performFullSync() {
        guard isUserAuthenticated() else {
            syncStatusSubject.send(.failed(error: NSError(domain: "DataSyncError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        syncStatusSubject.send(.syncing)
        
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.syncUserProfile()
            self.syncTasks()
            self.syncSessions()
            
            self.lastSyncTime = Date()
            
            DispatchQueue.main.async {
                self.syncStatusSubject.send(.completed)
            }
        }
    }
    
    /// Synchronizes a specific user profile
    public func syncUserProfile(forUID uid: String? = nil) {
        #if canImport(FirebaseFirestore)
        guard let currentUID = uid ?? Auth.auth().currentUser?.uid else {
            return
        }
        
        // First, check if we have a local user profile
        let profile = coreDataManager.fetchUserProfile(withFirebaseUID: currentUID)
        
        if let profile = profile {
            // Update Firestore with Core Data
            updateUserProfileInFirestore(profile)
        } else {
            // Create local profile from Firestore
            fetchUserProfileFromFirestore(uid: currentUID)
        }
        #endif
    }
    
    /// Synchronizes tasks for the current user
    public func syncTasks() {
        #if canImport(FirebaseFirestore)
        guard let currentUID = Auth.auth().currentUser?.uid,
              let profile = coreDataManager.fetchUserProfile(withFirebaseUID: currentUID) else {
            return
        }
        
        // Get local tasks
        let localTasks = coreDataManager.fetchTasks(for: profile, includeCompleted: true)
        
        // Get remote tasks
        fetchTasksFromFirestore(userID: currentUID) { remoteTasks in
            self.syncQueue.async {
                self.mergeTasksWithFirestore(localTasks: localTasks, remoteTasks: remoteTasks, userProfile: profile)
            }
        }
        #endif
    }
    
    /// Synchronizes sessions for the current user
    public func syncSessions() {
        #if canImport(FirebaseFirestore)
        guard let currentUID = Auth.auth().currentUser?.uid,
              let profile = coreDataManager.fetchUserProfile(withFirebaseUID: currentUID) else {
            return
        }
        
        // Get local sessions
        let localSessions = coreDataManager.fetchSessions(for: profile)
        
        // Get remote sessions
        fetchSessionsFromFirestore(userID: currentUID) { remoteSessions in
            self.syncQueue.async {
                self.mergeSessionsWithFirestore(localSessions: localSessions, remoteSessions: remoteSessions, userProfile: profile)
            }
        }
        #endif
    }
    
    // MARK: - Private Helper Methods
    
    private func setupNotificationObservers() {
        // Listen for data changes in Core Data
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCoreDataChanges(_:)),
            name: NSManagedObjectContext.didSaveObjectsNotification,
            object: nil
        )
        
        // Listen for authentication state changes
        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if user != nil {
                // User signed in, perform sync if needed
                self?.performFullSync()
            }
        }
        #endif
    }
    
    @objc private func handleCoreDataChanges(_ notification: Notification) {
        // Only sync if we have recent changes and not currently syncing
        guard let userInfo = notification.userInfo,
              let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
              let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
              !insertedObjects.isEmpty || !updatedObjects.isEmpty else {
            return
        }
        
        // Schedule a sync after changes
        scheduleSync()
    }
    
    private func scheduleSync() {
        // Cancel any existing sync
        currentSync?.cancel()
        
        // Schedule a new sync after a delay to batch changes
        currentSync = Just(())
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performFullSync()
            }
    }
    
    private func isUserAuthenticated() -> Bool {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser != nil
        #else
        return false
        #endif
    }
    
    #if canImport(FirebaseFirestore)
    private func updateUserProfileInFirestore(_ profile: UserProfile) {
        guard let uid = profile.firebaseUID else { return }
        
        let userData: [String: Any] = [
            "displayName": profile.displayName ?? "",
            "phoneNumber": profile.phoneNumber ?? "",
            "recoveryEmail": profile.recoveryEmail ?? "",
            "profileImagePath": profile.profileImagePath ?? "",
            "lastActiveDate": profile.lastActiveDate ?? Date(),
            "updatedAt": Date()
        ]
        
        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error updating user profile in Firestore: \(error)")
            }
        }
        
        // Also sync settings
        if let settings = profile.settings {
            let settingsData: [String: Any] = [
                "theme": settings.theme ?? "system",
                "defaultSessionDuration": settings.defaultSessionDuration,
                "enableFriction": settings.enableFriction,
                "frictionLevel": settings.frictionLevel,
                "enableHapticFeedback": settings.enableHapticFeedback,
                "enableNotifications": settings.enableNotifications,
                "showCompletedTasks": settings.showCompletedTasks,
                "syncAcrossDevices": settings.syncAcrossDevices,
                "updatedAt": Date()
            ]
            
            db.collection("users").document(uid).collection("settings").document("userSettings")
                .setData(settingsData, merge: true) { error in
                    if let error = error {
                        print("Error updating user settings in Firestore: \(error)")
                    }
                }
        }
    }
    
    private func fetchUserProfileFromFirestore(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists, let data = document.data() else {
                // If no document exists, create it
                self?.createUserProfileInFirestore(uid: uid)
                return
            }
            
            // Create local user profile
            let context = self.coreDataManager.createBackgroundContext()
            
            context.perform {
                let displayName = data["displayName"] as? String ?? ""
                let phoneNumber = data["phoneNumber"] as? String ?? ""
                let recoveryEmail = data["recoveryEmail"] as? String
                
                let profile = self.coreDataManager.createUserProfile(
                    in: context,
                    firebaseUID: uid,
                    displayName: displayName,
                    phoneNumber: phoneNumber,
                    recoveryEmail: recoveryEmail
                )
                
                profile.profileImagePath = data["profileImagePath"] as? String
                profile.lastActiveDate = (data["lastActiveDate"] as? Timestamp)?.dateValue() ?? Date()
                
                // Get settings
                self.db.collection("users").document(uid).collection("settings").document("userSettings")
                    .getDocument { (settingsDoc, error) in
                        if let settingsDoc = settingsDoc, settingsDoc.exists, let settingsData = settingsDoc.data() {
                            context.perform {
                                if let settings = profile.settings {
                                    settings.theme = settingsData["theme"] as? String ?? "system"
                                    if let duration = settingsData["defaultSessionDuration"] as? Int {
                                        settings.defaultSessionDuration = Int32(duration)
                                    }
                                    settings.enableFriction = settingsData["enableFriction"] as? Bool ?? true
                                    if let level = settingsData["frictionLevel"] as? Int {
                                        settings.frictionLevel = Int16(level)
                                    }
                                    settings.enableHapticFeedback = settingsData["enableHapticFeedback"] as? Bool ?? true
                                    settings.enableNotifications = settingsData["enableNotifications"] as? Bool ?? true
                                    settings.showCompletedTasks = settingsData["showCompletedTasks"] as? Bool ?? false
                                    settings.syncAcrossDevices = settingsData["syncAcrossDevices"] as? Bool ?? true
                                    
                                    self.coreDataManager.saveContext(context)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    private func createUserProfileInFirestore(uid: String) {
        // Get user info from Authentication
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "displayName": user.displayName ?? "",
            "phoneNumber": user.phoneNumber ?? "",
            "recoveryEmail": user.email ?? "",
            "createdAt": Date(),
            "updatedAt": Date(),
            "lastActiveDate": Date(),
            "accountStatus": "active"
        ]
        
        // Create in Firestore
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error creating user profile in Firestore: \(error)")
                return
            }
            
            // Create settings
            let settingsData: [String: Any] = [
                "theme": "system",
                "defaultSessionDuration": 1500,
                "enableFriction": true,
                "frictionLevel": 2,
                "enableHapticFeedback": true,
                "enableNotifications": true,
                "showCompletedTasks": false,
                "syncAcrossDevices": true,
                "createdAt": Date(),
                "updatedAt": Date()
            ]
            
            self.db.collection("users").document(uid).collection("settings").document("userSettings")
                .setData(settingsData) { error in
                    if let error = error {
                        print("Error creating user settings in Firestore: \(error)")
                    } else {
                        // Now fetch the profile to create local copy
                        self.fetchUserProfileFromFirestore(uid: uid)
                    }
                }
        }
    }
    
    private func fetchTasksFromFirestore(userID: String, completion: @escaping ([FirestoreTask]) -> Void) {
        db.collection("users").document(userID).collection("tasks")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching tasks from Firestore: \(error)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let remoteTasks = documents.compactMap { document -> FirestoreTask? in
                    let data = document.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let title = data["title"] as? String else {
                        return nil
                    }
                    
                    return FirestoreTask(
                        id: id,
                        documentID: document.documentID,
                        title: title,
                        details: data["details"] as? String,
                        isCompleted: data["isCompleted"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
                        category: data["category"] as? String,
                        priority: data["priority"] as? Int16 ?? 0,
                        isImportant: data["isImportant"] as? Bool ?? false,
                        order: data["order"] as? Int32 ?? 0,
                        estimatedDuration: data["estimatedDuration"] as? Int32 ?? 1500,
                        completedDate: (data["completedDate"] as? Timestamp)?.dateValue()
                    )
                }
                
                completion(remoteTasks)
            }
    }
    
    private func mergeTasksWithFirestore(localTasks: [Task], remoteTasks: [FirestoreTask], userProfile: UserProfile) {
        let context = coreDataManager.createBackgroundContext()
        
        // First, gather all the IDs
        let localTaskIDs = Set(localTasks.compactMap { $0.id })
        let remoteTaskIDs = Set(remoteTasks.map { $0.id })
        
        // Tasks to create in Core Data
        let tasksToCreateLocally = remoteTasks.filter { !localTaskIDs.contains($0.id) }
        
        // Tasks to create in Firestore
        let tasksToCreateRemotely = localTasks.filter { task in
            guard let id = task.id else { return false }
            return !remoteTaskIDs.contains(id)
        }
        
        // Tasks to update (exist in both places)
        let tasksToCompare = localTasks.filter { task in
            guard let id = task.id else { return false }
            return remoteTaskIDs.contains(id)
        }
        
        // Create tasks in Core Data
        context.perform {
            // Get user from this context
            let userFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "id == %@", userProfile.id! as CVarArg)
            let userInContext = try? context.fetch(userFetchRequest).first
            
            guard let user = userInContext else { return }
            
            for remoteTask in tasksToCreateLocally {
                let task = Task(context: context)
                task.id = remoteTask.id
                task.title = remoteTask.title
                task.details = remoteTask.details
                task.isCompleted = remoteTask.isCompleted
                task.createdAt = remoteTask.createdAt ?? Date()
                task.updatedAt = remoteTask.updatedAt
                task.category = remoteTask.category
                task.priority = remoteTask.priority
                task.isImportant = remoteTask.isImportant
                task.order = remoteTask.order
                task.estimatedDuration = remoteTask.estimatedDuration
                task.completedDate = remoteTask.completedDate
                task.user = user
            }
            
            self.coreDataManager.saveContext(context)
        }
        
        // Create tasks in Firestore
        for localTask in tasksToCreateRemotely {
            guard let taskID = localTask.id?.uuidString else { continue }
            
            let taskData: [String: Any] = [
                "id": taskID,
                "title": localTask.title ?? "",
                "details": localTask.details ?? "",
                "isCompleted": localTask.isCompleted,
                "createdAt": localTask.createdAt ?? Date(),
                "updatedAt": localTask.updatedAt ?? Date(),
                "category": localTask.category ?? "",
                "priority": localTask.priority,
                "isImportant": localTask.isImportant,
                "order": localTask.order,
                "estimatedDuration": localTask.estimatedDuration,
                "completedDate": localTask.completedDate as Any
            ]
            
            self.db.collection("users").document(userProfile.firebaseUID ?? "").collection("tasks")
                .document(taskID).setData(taskData) { error in
                    if let error = error {
                        print("Error creating task in Firestore: \(error)")
                    }
                }
        }
        
        // Update tasks that exist in both places
        for localTask in tasksToCompare {
            guard let taskID = localTask.id,
                  let remoteTask = remoteTasks.first(where: { $0.id == taskID }) else { continue }
            
            // Compare timestamps to determine which version is newer
            if let localUpdated = localTask.updatedAt, let remoteUpdated = remoteTask.updatedAt,
               localUpdated > remoteUpdated {
                // Local is newer, update remote
                updateTaskInFirestore(localTask, userID: userProfile.firebaseUID ?? "", documentID: remoteTask.documentID)
            } else if let localUpdated = localTask.updatedAt, let remoteUpdated = remoteTask.updatedAt,
                      remoteUpdated > localUpdated {
                // Remote is newer, update local
                context.perform {
                    self.updateLocalTask(with: remoteTask, in: context)
                }
            }
        }
    }
    
    private func updateTaskInFirestore(_ task: Task, userID: String, documentID: String) {
        guard let taskID = task.id?.uuidString else { return }
        
        let taskData: [String: Any] = [
            "id": taskID,
            "title": task.title ?? "",
            "details": task.details ?? "",
            "isCompleted": task.isCompleted,
            "updatedAt": Date(),
            "category": task.category ?? "",
            "priority": task.priority,
            "isImportant": task.isImportant,
            "order": task.order,
            "estimatedDuration": task.estimatedDuration,
            "completedDate": task.completedDate as Any
        ]
        
        db.collection("users").document(userID).collection("tasks")
            .document(documentID).updateData(taskData) { error in
                if let error = error {
                    print("Error updating task in Firestore: \(error)")
                }
            }
    }
    
    private func updateLocalTask(with remoteTask: FirestoreTask, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", remoteTask.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let localTask = results.first {
                localTask.title = remoteTask.title
                localTask.details = remoteTask.details
                localTask.isCompleted = remoteTask.isCompleted
                localTask.updatedAt = remoteTask.updatedAt
                localTask.category = remoteTask.category
                localTask.priority = remoteTask.priority
                localTask.isImportant = remoteTask.isImportant
                localTask.order = remoteTask.order
                localTask.estimatedDuration = remoteTask.estimatedDuration
                localTask.completedDate = remoteTask.completedDate
                
                self.coreDataManager.saveContext(context)
            }
        } catch {
            print("Error fetching task to update: \(error)")
        }
    }
    
    // Similar implementations for sessions would follow...
    private func fetchSessionsFromFirestore(userID: String, completion: @escaping ([String: Any]) -> Void) {
        // Stub for now - would implement similar to tasks
        completion([:])
    }
    
    private func mergeSessionsWithFirestore(localSessions: [FocusSession], remoteSessions: [String: Any], userProfile: UserProfile) {
        // Stub for now - would implement similar to tasks
    }
    #endif
}

// MARK: - Supporting Types

/// Status of data synchronization
public enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(error: Error)
}

/// Firestore representation of a Task
struct FirestoreTask {
    let id: UUID
    let documentID: String
    let title: String
    let details: String?
    let isCompleted: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let category: String?
    let priority: Int16
    let isImportant: Bool
    let order: Int32
    let estimatedDuration: Int32
    let completedDate: Date?
} 