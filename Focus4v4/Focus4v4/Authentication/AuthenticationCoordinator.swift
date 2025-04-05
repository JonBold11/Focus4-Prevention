import SwiftUI
import Focus4Shared

/// Manages the authentication flow state and transitions
class AuthenticationCoordinator: ObservableObject {
    enum AuthenticationState {
        case welcome
        case phoneNumber
        case verification(phoneNumber: String, verificationID: String)
        case profileCreation
        case recoveryEmail
        case completion(username: String, hasRecoveryEmail: Bool)
        case authenticated
    }
    
    @Published var currentState: AuthenticationState = .welcome
    
    // Holds data across the authentication flow
    private var phoneNumber = ""
    private var verificationID = ""
    private var username = ""
    private var hasRecoveryEmail = false
    
    /// Advances to the next step in the authentication flow based on the current state
    func moveToNextStep() {
        switch currentState {
        case .welcome:
            currentState = .phoneNumber
            
        case .phoneNumber:
            // This transition is handled in validatePhoneNumber
            break
            
        case .verification:
            currentState = .profileCreation
            
        case .profileCreation:
            currentState = .recoveryEmail
            
        case .recoveryEmail:
            currentState = .completion(username: username, hasRecoveryEmail: hasRecoveryEmail)
            
        case .completion:
            currentState = .authenticated
            
        case .authenticated:
            // Already authenticated, nothing to do
            break
        }
    }
    
    /// Handle phone number validation
    func validatePhoneNumber(_ number: String) {
        self.phoneNumber = number
        
        // In a real app, this would call Firebase to validate the phone number
        #if canImport(FirebaseAuth)
        FirebaseManager.shared.signInWithPhoneNumber(number) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let verificationID):
                    self.verificationID = verificationID
                    self.currentState = .verification(phoneNumber: number, verificationID: verificationID)
                case .failure(let error):
                    print("Phone validation error: \(error.localizedDescription)")
                    // Handle error appropriately
                }
            }
        }
        #else
        // Simulate API call for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Generate a fake verification ID
            self.verificationID = "test-verification-id-\(Int.random(in: 10000...99999))"
            self.currentState = .verification(phoneNumber: number, verificationID: self.verificationID)
        }
        #endif
    }
    
    /// Handle phone verification code
    func handleVerificationCompleted() {
        currentState = .profileCreation
    }
    
    /// Handle profile creation
    func handleProfileCreated(_ username: String) {
        self.username = username
        currentState = .recoveryEmail
    }
    
    /// Handle recovery email setup
    func handleRecoveryEmailSetup(didSetup: Bool) {
        self.hasRecoveryEmail = didSetup
        currentState = .completion(username: username, hasRecoveryEmail: didSetup)
    }
    
    /// Check if the user is already authenticated
    func checkAuthenticationStatus() {
        #if canImport(FirebaseAuth)
        if FirebaseManager.shared.isUserSignedIn {
            self.currentState = .authenticated
        } else {
            self.currentState = .welcome
        }
        #else
        // For development, start at welcome screen
        self.currentState = .welcome
        #endif
    }
    
    /// Sign out the current user
    func signOut() {
        #if canImport(FirebaseAuth)
        do {
            try FirebaseManager.shared.signOut()
            self.currentState = .welcome
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        #else
        // For development
        self.currentState = .welcome
        #endif
    }
}

/// The main view that coordinates the authentication flow
struct AuthenticationView: View {
    @StateObject private var coordinator = AuthenticationCoordinator()
    
    var body: some View {
        Group {
            switch coordinator.currentState {
            case .welcome:
                WelcomeView {
                    coordinator.moveToNextStep()
                }
                
            case .phoneNumber:
                PhoneNumberView { phoneNumber in
                    coordinator.validatePhoneNumber(phoneNumber)
                }
                
            case .verification(let phoneNumber, let verificationID):
                VerificationCodeView(
                    phoneNumber: phoneNumber,
                    verificationID: verificationID,
                    onCodeVerified: {
                        coordinator.handleVerificationCompleted()
                    },
                    onResendCode: {
                        // Re-request verification code
                        coordinator.validatePhoneNumber(phoneNumber)
                    }
                )
                
            case .profileCreation:
                ProfileCreationView { username in
                    coordinator.handleProfileCreated(username)
                }
                
            case .recoveryEmail:
                RecoveryEmailSetupView { didSetupEmail in
                    coordinator.handleRecoveryEmailSetup(didSetup: didSetupEmail)
                }
                
            case .completion(let username, let hasRecoveryEmail):
                OnboardingCompletionView(
                    username: username,
                    hasRecoveryEmail: hasRecoveryEmail,
                    onComplete: {
                        coordinator.moveToNextStep()
                    }
                )
                
            case .authenticated:
                // Show the main app content
                ContentView()
            }
        }
        .onAppear {
            // Check if user is already authenticated
            coordinator.checkAuthenticationStatus()
        }
    }
}

#Preview {
    AuthenticationView()
} 