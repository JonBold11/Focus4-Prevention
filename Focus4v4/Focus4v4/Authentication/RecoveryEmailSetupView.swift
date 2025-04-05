import SwiftUI
import Focus4Shared

/// View for setting up an optional recovery email
/// This is the fifth step in the authentication flow after profile creation
struct RecoveryEmailSetupView: View {
    @StateObject private var viewModel = RecoveryEmailViewModel()
    @FocusState private var focusedField: Field?
    
    var onComplete: (Bool) -> Void
    
    enum Field {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Account Recovery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top)
                
                Text("Set up a recovery email to ensure you can always access your account")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Security info card
                securityInfoCard
                
                // Email and password fields
                emailPasswordFields
                
                // Setup button
                Button {
                    viewModel.setupRecoveryEmail { success in
                        if success {
                            onComplete(true)
                        }
                    }
                } label: {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 20)
                    } else {
                        Text("Set Up Recovery")
                            .font(.headline)
                    }
                }
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(viewModel.isValid ? Color.blue : Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
                .disabled(!viewModel.isValid || viewModel.isProcessing)
                
                // Skip option
                Button {
                    onComplete(false)
                } label: {
                    Text("Skip for now")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .underline()
                }
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .email
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Security information card
    private var securityInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Why This Matters")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text("Your phone number is the primary way to access your account. A recovery email gives you a backup option if you can't receive SMS codes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Secure account recovery if you change phone numbers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Protection against losing access to your data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.vertical, 10)
    }
    
    /// Email and password input fields
    private var emailPasswordFields: some View {
        VStack(spacing: 15) {
            // Email field
            VStack(alignment: .leading, spacing: 5) {
                Text("Recovery Email")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email address", text: $viewModel.email)
                    .focused($focusedField, equals: .email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.email) { _, _ in viewModel.validateEmail() }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                
                if !viewModel.emailError.isEmpty {
                    Text(viewModel.emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 5) {
                Text("Recovery Password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                SecureField("Create a password", text: $viewModel.password)
                    .focused($focusedField, equals: .password)
                    .textContentType(.newPassword)
                    .onChange(of: viewModel.password) { _, _ in viewModel.validatePassword() }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                
                if !viewModel.passwordError.isEmpty {
                    Text(viewModel.passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    passwordStrengthIndicator
                }
            }
            
            // Confirm Password field
            VStack(alignment: .leading, spacing: 5) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                SecureField("Confirm your password", text: $viewModel.confirmPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .textContentType(.newPassword)
                    .onChange(of: viewModel.confirmPassword) { _, _ in viewModel.validateConfirmPassword() }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                
                if !viewModel.confirmPasswordError.isEmpty {
                    Text(viewModel.confirmPasswordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    /// Password strength indicator
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(viewModel.passwordStrength.description)
                    .font(.caption)
                    .foregroundColor(viewModel.passwordStrength.color)
            }
            
            HStack(spacing: 5) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .frame(height: 5)
                        .foregroundColor(index < viewModel.passwordStrength.rawValue ? viewModel.passwordStrength.color : Color.gray.opacity(0.3))
                        .cornerRadius(2.5)
                }
            }
        }
    }
}

/// ViewModel for the recovery email setup
class RecoveryEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var emailError = ""
    @Published var passwordError = ""
    @Published var confirmPasswordError = ""
    
    @Published var isProcessing = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    enum PasswordStrength: Int, CaseIterable {
        case veryWeak = 0
        case weak = 1
        case moderate = 2
        case strong = 3
        
        var description: String {
            switch self {
            case .veryWeak: return "Very Weak"
            case .weak: return "Weak"
            case .moderate: return "Moderate"
            case .strong: return "Strong"
            }
        }
        
        var color: Color {
            switch self {
            case .veryWeak: return .red
            case .weak: return .orange
            case .moderate: return .yellow
            case .strong: return .green
            }
        }
    }
    
    var passwordStrength: PasswordStrength {
        var score = 0
        
        // Length check
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Complexity checks
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        if hasUppercase && hasLowercase { score += 1 }
        if hasNumber { score += 1 }
        if hasSpecialChar { score += 1 }
        
        switch score {
        case 0...1: return .veryWeak
        case 2: return .weak
        case 3: return .moderate
        default: return .strong
        }
    }
    
    var isValid: Bool {
        return emailError.isEmpty && passwordError.isEmpty && confirmPasswordError.isEmpty &&
               !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
               passwordStrength.rawValue >= PasswordStrength.moderate.rawValue
    }
    
    func validateEmail() {
        emailError = ""
        
        if email.isEmpty { return }
        
        // Basic email validation
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid email address"
        }
    }
    
    func validatePassword() {
        passwordError = ""
        
        if password.isEmpty { return }
        
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else if passwordStrength.rawValue < PasswordStrength.moderate.rawValue {
            passwordError = "Please use a stronger password with numbers and special characters"
        }
        
        // If confirm password is not empty, validate it against the new password
        if !confirmPassword.isEmpty {
            validateConfirmPassword()
        }
    }
    
    func validateConfirmPassword() {
        confirmPasswordError = ""
        
        if confirmPassword.isEmpty { return }
        
        if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
        }
    }
    
    func setupRecoveryEmail(completion: @escaping (Bool) -> Void) {
        // Validate all fields
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        
        if !isValid {
            completion(false)
            return
        }
        
        isProcessing = true
        
        // In a real app, this would call Firebase to add the recovery email
        #if canImport(FirebaseAuth)
        FirebaseManager.shared.addRecoveryEmail(email, password: password) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isProcessing = false
                
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
        #else
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.isProcessing = false
            
            self.showAlert = true
            self.alertTitle = "Email Verification Sent"
            self.alertMessage = "We've sent a verification link to \(self.email). Please check your email and click the link to verify."
            
            completion(true)
        }
        #endif
    }
}

#Preview {
    RecoveryEmailSetupView { didSetupEmail in
        print("Recovery email setup complete. Email setup: \(didSetupEmail)")
    }
} 