import Foundation
import CoreData
import Combine

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

/// A service for managing user profile data and connecting authentication with user data
public class UserProfileService {
    // MARK: - Properties
    
    /// The shared singleton instance
    public static let shared = UserProfileService()
    
    /// The Core Data manager
    private let coreDataManager = CoreDataManager.shared
    
    /// The data synchronization service
    private let syncService = DataSynchronizationService.shared
    
    /// Current user publisher
    private let currentUserSubject = CurrentValueSubject<UserProfile?, Never>(nil)
    public var currentUser: AnyPublisher<UserProfile?, Never> {
        return currentUserSubject.eraseToAnyPublisher()
    }
    
    /// User status publisher
    private let userStatusSubject = CurrentValueSubject<UserStatus, Never>(.notAuthenticated)
    public var userStatus: AnyPublisher<UserStatus, Never> {
        return userStatusSubject.eraseToAnyPublisher()
    }
    
    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupAuthenticationObserver()
    }
    
    // MARK: - Public Methods
    
    /// Creates or updates a user profile from authentication data
    /// - Parameters:
    ///   - firebaseUID: The Firebase UID
    ///   - displayName: The user's display name
    ///   - phoneNumber: The user's phone number
    ///   - recoveryEmail: Optional recovery email
    ///   - completion: Callback with the created/updated profile
    public func createOrUpdateUserProfile(
        firebaseUID: String,
        displayName: String,
        phoneNumber: String,
        recoveryEmail: String? = nil,
        completion: @escaping (UserProfile?) -> Void
    ) {
        // First check if user already exists
        if let existingProfile = coreDataManager.fetchUserProfile(withFirebaseUID: firebaseUID) {
            // Update existing profile
            let context = coreDataManager.createBackgroundContext()
            
            context.perform {
                // Refetch profile in this context
                let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)
                
                do {
                    let results = try context.fetch(fetchRequest)
                    if let profile = results.first {
                        profile.displayName = displayName
                        profile.phoneNumber = phoneNumber
                        profile.recoveryEmail = recoveryEmail
                        profile.updatedAt = Date()
                        profile.lastActiveDate = Date()
                        
                        self.coreDataManager.saveContext(context)
                        
                        // Update current user
                        self.refreshCurrentUser()
                        
                        DispatchQueue.main.async {
                            completion(self.currentUserSubject.value)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error fetching profile to update: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        } else {
            // Create new profile
            let profile = coreDataManager.createUserProfile(
                firebaseUID: firebaseUID,
                displayName: displayName,
                phoneNumber: phoneNumber,
                recoveryEmail: recoveryEmail
            )
            
            // Update current user
            refreshCurrentUser()
            
            completion(profile)
        }
    }
    
    /// Updates the user's profile data
    /// - Parameters:
    ///   - displayName: The new display name
    ///   - profileImage: The profile image path
    ///   - completion: Callback with success status
    public func updateUserProfile(
        displayName: String? = nil,
        profileImage: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUser = currentUserSubject.value else {
            completion(false)
            return
        }
        
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", currentUser.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let profile = results.first {
                    if let displayName = displayName {
                        profile.displayName = displayName
                    }
                    
                    if let profileImage = profileImage {
                        profile.profileImagePath = profileImage
                    }
                    
                    profile.updatedAt = Date()
                    
                    self.coreDataManager.saveContext(context)
                    
                    // Trigger sync
                    self.syncService.syncUserProfile()
                    
                    // Refresh current user
                    self.refreshCurrentUser()
                    
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } catch {
                print("Error updating user profile: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Updates user settings
    /// - Parameters:
    ///   - theme: The theme name
    ///   - defaultSessionDuration: The default session duration in seconds
    ///   - enableFriction: Whether friction is enabled
    ///   - frictionLevel: The friction level (1-4)
    ///   - enableHapticFeedback: Whether haptic feedback is enabled
    ///   - enableNotifications: Whether notifications are enabled
    ///   - showCompletedTasks: Whether to show completed tasks
    ///   - syncAcrossDevices: Whether to sync across devices
    ///   - completion: Callback with success status
    public func updateUserSettings(
        theme: String? = nil,
        defaultSessionDuration: Int32? = nil,
        enableFriction: Bool? = nil,
        frictionLevel: Int16? = nil,
        enableHapticFeedback: Bool? = nil,
        enableNotifications: Bool? = nil,
        showCompletedTasks: Bool? = nil,
        syncAcrossDevices: Bool? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUser = currentUserSubject.value,
              let settings = currentUser.settings else {
            completion(false)
            return
        }
        
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", settings.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let settingsInContext = results.first {
                    self.coreDataManager.updateUserSettings(
                        settings: settingsInContext,
                        theme: theme,
                        defaultSessionDuration: defaultSessionDuration,
                        enableFriction: enableFriction,
                        frictionLevel: frictionLevel,
                        enableHapticFeedback: enableHapticFeedback,
                        enableNotifications: enableNotifications,
                        showCompletedTasks: showCompletedTasks,
                        syncAcrossDevices: syncAcrossDevices,
                        in: context
                    )
                    
                    // Trigger sync
                    self.syncService.syncUserProfile()
                    
                    // Refresh current user
                    self.refreshCurrentUser()
                    
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } catch {
                print("Error updating user settings: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Refreshes the current user from Core Data
    public func refreshCurrentUser() {
        #if canImport(FirebaseAuth)
        guard let uid = Auth.auth().currentUser?.uid else {
            currentUserSubject.send(nil)
            userStatusSubject.send(.notAuthenticated)
            return
        }
        
        if let profile = coreDataManager.fetchUserProfile(withFirebaseUID: uid) {
            currentUserSubject.send(profile)
            userStatusSubject.send(.authenticated)
        } else {
            // No profile found, check if we can create one
            if let user = Auth.auth().currentUser,
               let phoneNumber = user.phoneNumber {
                let displayName = user.displayName ?? "User"
                
                createOrUpdateUserProfile(
                    firebaseUID: uid,
                    displayName: displayName,
                    phoneNumber: phoneNumber,
                    recoveryEmail: user.email
                ) { profile in
                    if profile != nil {
                        self.userStatusSubject.send(.authenticated)
                    } else {
                        self.userStatusSubject.send(.error)
                    }
                }
            } else {
                userStatusSubject.send(.error)
            }
        }
        #else
        currentUserSubject.send(nil)
        userStatusSubject.send(.notAuthenticated)
        #endif
    }
    
    // MARK: - Private Methods
    
    private func setupAuthenticationObserver() {
        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                // User signed in
                self?.userStatusSubject.send(.loading)
                self?.refreshCurrentUser()
            } else {
                // User signed out
                self?.currentUserSubject.send(nil)
                self?.userStatusSubject.send(.notAuthenticated)
            }
        }
        #endif
    }
}

// MARK: - Supporting Types

/// Status of the user authentication
public enum UserStatus {
    case notAuthenticated
    case loading
    case authenticated
    case error
} 