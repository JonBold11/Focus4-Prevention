import Foundation
import WatchConnectivity

// Only import Firebase-related modules if available for the current platform
#if canImport(FirebaseCore) && canImport(FirebaseAuth)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif

public enum SharedConfiguration {
    /// The app group identifier used for sharing data between the main app, watch app, and extensions
    public static let appGroupIdentifier = "group.com.jonathanserrano.Focus4v4.shared"
    
    /// Shared UserDefaults instance that uses the app group container
    public static let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
    
    /// Shared container URL for the app group
    public static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// Verify if app group access is properly configured
    public static func verifyAppGroupAccess() -> Bool {
        guard let defaults = sharedDefaults else {
            print("⚠️ Failed to access shared UserDefaults")
            return false
        }
        
        // Try writing and reading a test value
        let testKey = "appGroupAccessTest"
        defaults.set(true, forKey: testKey)
        let testValue = defaults.bool(forKey: testKey)
        defaults.removeObject(forKey: testKey)
        
        if !testValue {
            print("⚠️ Failed to write/read from shared UserDefaults")
            return false
        }
        
        guard let containerURL = sharedContainerURL else {
            print("⚠️ Failed to access shared container URL")
            return false
        }
        
        // Verify we can write to the shared container
        let testFileURL = containerURL.appendingPathComponent("test.txt")
        do {
            try "test".write(to: testFileURL, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFileURL)
        } catch {
            print("⚠️ Failed to write to shared container: \(error)")
            return false
        }
        
        return true
    }
}

/// Keys used for data synchronization between devices
public struct SyncKeys {
    public static let lastSyncTimestamp = "lastSyncTimestamp"
    public static let focusSessionUpdate = "focusSessionUpdate"
    public static let settingsUpdate = "settingsUpdate"
    public static let complicationUpdate = "complicationUpdate"
}

/// A class to manage connectivity between the iOS app and watchOS app
public class ConnectivityManager: NSObject, ObservableObject {
    public static let shared = ConnectivityManager()
    private let session: WCSession
    
    @Published public var isReachable = false
    @Published public var isCompanionAppInstalled = false
    @Published public var lastMessage: [String: Any]? = nil
    
    override private init() {
        self.session = WCSession.default
        super.init()
        
        // Only activate the session if the device supports Watch Connectivity
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    /// Send message to the counterpart device (iOS to watch or watch to iOS)
    public func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        // Only send if the session is reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
        } else {
            print("⚠️ Watch is not reachable")
            errorHandler?(NSError(domain: "ConnectivityManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Watch is not reachable"]))
        }
    }
    
    /// Transfer user data to the counterpart device (for larger data transfers than messages)
    public func transferUserInfo(_ userInfo: [String: Any]) -> WCSessionUserInfoTransfer {
        return session.transferUserInfo(userInfo)
    }
    
    /// Update the app's complications on the watch
    public func updateComplications(with data: [String: Any]) {
        #if os(iOS)
        if session.isComplicationEnabled {
            session.transferCurrentComplicationUserInfo(data)
            print("Updating watch complications")
        } else {
            print("Watch complications not enabled")
        }
        #endif
    }
}

// MARK: - WCSessionDelegate
extension ConnectivityManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession activation failed with error: \(error.localizedDescription)")
                return
            }
            
            print("WCSession activated with state: \(activationState.rawValue)")
            self.isReachable = session.isReachable
            #if os(iOS)
            self.isCompanionAppInstalled = session.isWatchAppInstalled
            #else
            self.isCompanionAppInstalled = session.isCompanionAppInstalled
            #endif
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("Watch reachability changed: \(session.isReachable)")
        }
    }
    
    // Required to conform to WCSessionDelegate
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate the session if needed
        WCSession.default.activate()
    }
    #endif
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.lastMessage = message
            print("Received message: \(message)")
            
            // Process different message types here
            // This can be expanded to handle different types of data
            // The implementation will depend on your app's specific needs
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.lastMessage = message
            print("Received message with reply handler: \(message)")
            
            // TODO: Process message and prepare response
            let response: [String: Any] = ["received": true, "timestamp": Date().timeIntervalSince1970]
            replyHandler(response)
        }
    }
}

// MARK: - Firebase Services
#if canImport(FirebaseCore) && canImport(FirebaseAuth)
/// A class to manage Firebase services
public class FirebaseManager {
    public static let shared = FirebaseManager()
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Check if a user is currently signed in
    public var isUserSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Get the current user's ID
    public var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Check if current user has a recovery email
    public var hasRecoveryEmail: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        return user.email != nil && !user.email!.isEmpty
    }
    
    /// Sign in with phone number
    public func signInWithPhoneNumber(_ phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let verificationID = verificationID {
                completion(.success(verificationID))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Verification ID is nil"])))
            }
        }
    }
    
    /// Verify phone number with code
    public func verifyCode(_ code: String, verificationID: String, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = authResult?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is nil"])))
            }
        }
    }
    
    /// Add recovery email to an existing phone-authenticated account
    public func addRecoveryEmail(_ email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
            return
        }
        
        // Create email credential
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        // Link the email credential to the current user
        user.link(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Send verification email
            user.sendEmailVerification { error in
                if let error = error {
                    print("Warning: Failed to send verification email: \(error.localizedDescription)")
                    // We still consider this a success since the email was linked
                }
                
                completion(.success(()))
            }
        }
    }
    
    /// Check if recovery email is verified
    public func isRecoveryEmailVerified(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // Reload user to get the latest emailVerified status
        user.reload { error in
            if let error = error {
                print("Error reloading user: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(user.isEmailVerified)
        }
    }
    
    /// Initiate recovery with email
    public func initiateRecovery(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordResetEmail(to: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Complete recovery with email by signing in
    public func recoverWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is nil"])))
            }
        }
    }
    
    /// Update recovery email
    public func updateRecoveryEmail(_ newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
            return
        }
        
        user.updateEmail(to: newEmail) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Send verification email
            user.sendEmailVerification { error in
                if let error = error {
                    print("Warning: Failed to send verification email: \(error.localizedDescription)")
                    // Still consider success since email was updated
                }
                
                completion(.success(()))
            }
        }
    }
    
    /// Change recovery email password
    public func updateRecoveryPassword(currentPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user with email found"])))
            return
        }
        
        // Re-authenticate first
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Now update password
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    /// Send verification email for recovery email
    public func sendVerificationEmail(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Sign out the current user
    public func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Firestore
    
    /// Get a reference to the Firestore database
    public var db: Firestore {
        return Firestore.firestore()
    }
    
    /// Create or update a document in Firestore
    public func saveDocument<T: Encodable>(_ data: T, collection: String, documentID: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            if let documentID = documentID {
                // Update existing document
                try db.collection(collection).document(documentID).setData(from: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(documentID))
                    }
                }
            } else {
                // Create new document
                let reference = try db.collection(collection).addDocument(from: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(reference.documentID))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Get a document from Firestore
    public func getDocument<T: Decodable>(_ type: T.Type, collection: String, documentID: String, completion: @escaping (Result<T, Error>) -> Void) {
        db.collection(collection).document(documentID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                return
            }
            
            do {
                let object = try snapshot.data(as: type)
                completion(.success(object))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
#endif 