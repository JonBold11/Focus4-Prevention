import SwiftUI
import Focus4Shared

/// View for entering the SMS verification code
/// This is the third step in the authentication flow after phone number entry
struct VerificationCodeView: View {
    @StateObject private var viewModel: VerificationViewModel
    @FocusState private var focusedField: Int?
    
    var onCodeVerified: () -> Void
    var onResendCode: () -> Void
    
    init(phoneNumber: String, verificationID: String, onCodeVerified: @escaping () -> Void, onResendCode: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: VerificationViewModel(phoneNumber: phoneNumber, verificationID: verificationID))
        self.onCodeVerified = onCodeVerified
        self.onResendCode = onResendCode
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Verification Code")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.top)
            
            Text("Enter the 6-digit code sent to \(viewModel.formattedPhoneNumber)")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer().frame(height: 30)
            
            // Code entry fields
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    codeTextField(index)
                }
            }
            .padding(.horizontal)
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Resend code timer
            HStack {
                if viewModel.canResendCode {
                    Button {
                        viewModel.resendCode()
                        onResendCode()
                    } label: {
                        Text("Resend Code")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("Resend code in \(viewModel.timeRemaining)s")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .padding(.top)
            
            Spacer()
            
            // Verify button
            Button {
                viewModel.verifyCode { success in
                    if success {
                        onCodeVerified()
                    }
                }
            } label: {
                if viewModel.isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(height: 20)
                } else {
                    Text("Verify")
                        .font(.headline)
                }
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(viewModel.isCodeComplete ? Color.blue : Color.blue.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal)
            .disabled(!viewModel.isCodeComplete || viewModel.isVerifying)
            
            // Help link
            Button {
                viewModel.showHelpOptions = true
            } label: {
                Text("Didn't receive a code?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .underline()
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            // Start the timer when the view appears
            viewModel.startTimer()
            // Focus the first field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
        .onChange(of: viewModel.codeDigits.joined()) { _, newValue in
            // Automatically move to next field or attempt verification when code is complete
            if newValue.count == 6 {
                viewModel.verifyCode { success in
                    if success {
                        onCodeVerified()
                    }
                }
            }
        }
        .alert("Need Help?", isPresented: $viewModel.showHelpOptions) {
            Button("SMS Not Working?", role: .none) {
                // Show SMS troubleshooting
            }
            Button("Contact Support", role: .none) {
                // Show contact info
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select an option to resolve verification issues")
        }
    }
    
    /// Creates a single code digit text field
    private func codeTextField(_ index: Int) -> some View {
        return TextField("", text: $viewModel.codeDigits[index])
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 45, height: 60)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .focused($focusedField, equals: index)
            .onChange(of: viewModel.codeDigits[index]) { _, newValue in
                if newValue.count > 1 {
                    // Keep only the last digit
                    viewModel.codeDigits[index] = String(newValue.suffix(1))
                }
                
                if newValue.count == 1 && index < 5 {
                    // Move to next field
                    focusedField = index + 1
                }
                
                // Handle deletion and move to previous field
                if newValue.isEmpty && index > 0 {
                    focusedField = index - 1
                }
            }
    }
}

/// ViewModel for the verification code view
class VerificationViewModel: ObservableObject {
    @Published var codeDigits: [String] = Array(repeating: "", count: 6)
    @Published var errorMessage = ""
    @Published var isVerifying = false
    @Published var timeRemaining = 30
    @Published var canResendCode = false
    @Published var showHelpOptions = false
    
    private var timer: Timer?
    private let phoneNumber: String
    private let verificationID: String
    
    var formattedPhoneNumber: String {
        // Simple formatting - last 4 digits visible
        if phoneNumber.count > 4 {
            let lastFour = String(phoneNumber.suffix(4))
            return "******\(lastFour)"
        }
        return phoneNumber
    }
    
    var isCodeComplete: Bool {
        codeDigits.joined().count == 6
    }
    
    init(phoneNumber: String, verificationID: String) {
        self.phoneNumber = phoneNumber
        self.verificationID = verificationID
    }
    
    /// Starts the countdown timer for resend code option
    func startTimer() {
        timer?.invalidate()
        timeRemaining = 30
        canResendCode = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.canResendCode = true
                timer.invalidate()
            }
        }
    }
    
    /// Reset the timer when user requests a new code
    func resendCode() {
        startTimer()
        errorMessage = ""
    }
    
    /// Verifies the entered code with Firebase
    func verifyCode(completion: @escaping (Bool) -> Void) {
        guard isCodeComplete else {
            errorMessage = "Please enter the complete 6-digit code"
            completion(false)
            return
        }
        
        let code = codeDigits.joined()
        isVerifying = true
        errorMessage = ""
        
        // Simulate verification (in a real app, this would use Firebase Authentication)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            #if canImport(FirebaseAuth)
            // In a real app, we would use Firebase to verify
            FirebaseManager.shared.verifyCode(code, verificationID: self.verificationID) { result in
                DispatchQueue.main.async {
                    self.isVerifying = false
                    
                    switch result {
                    case .success(_):
                        completion(true)
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            }
            #else
            // Simulate successful verification
            self.isVerifying = false
            
            // For testing, consider all codes valid except "000000"
            if code == "000000" {
                self.errorMessage = "Invalid verification code. Please try again."
                completion(false)
            } else {
                completion(true)
            }
            #endif
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

#Preview {
    VerificationCodeView(
        phoneNumber: "+1 (555) 555-1234",
        verificationID: "test-verification-id",
        onCodeVerified: {
            print("Code verified")
        },
        onResendCode: {
            print("Resend code requested")
        }
    )
} 