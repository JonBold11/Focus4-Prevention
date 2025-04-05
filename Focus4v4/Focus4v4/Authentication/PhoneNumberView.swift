import SwiftUI
import Focus4Shared
import PhoneNumberKit

/// View for entering and validating a phone number
/// This is the second step in the authentication flow after the welcome screen
struct PhoneNumberView: View {
    @StateObject private var viewModel = PhoneNumberViewModel()
    @FocusState private var isPhoneFieldFocused: Bool
    
    var onNumberValidated: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Your Phone Number")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.top)
            
            Text("We'll send a verification code to this number")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer().frame(height: 20)
            
            // Phone number input
            HStack(alignment: .center, spacing: 10) {
                // Country code selector
                Menu {
                    ForEach(viewModel.countryCodes, id: \.code) { country in
                        Button(action: {
                            viewModel.selectedCountry = country
                        }) {
                            Text("\(country.flag) \(country.name) (\(country.dialCode))")
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCountry.flag)
                            .font(.title2)
                        
                        Text(viewModel.selectedCountry.dialCode)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Phone number field
                TextField("", text: $viewModel.phoneNumber)
                    .focused($isPhoneFieldFocused)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: viewModel.phoneNumber) { _, newValue in
                        viewModel.formatPhoneNumber()
                    }
            }
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Next button
            Button {
                viewModel.validatePhoneNumber { isValid in
                    if isValid {
                        let formattedNumber = "\(viewModel.selectedCountry.dialCode)\(viewModel.phoneNumber)"
                        onNumberValidated(formattedNumber)
                    }
                }
            } label: {
                if viewModel.isValidating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(height: 20)
                } else {
                    Text("Next")
                        .font(.headline)
                }
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(viewModel.isValidPhoneNumber ? Color.blue : Color.blue.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal)
            .disabled(!viewModel.isValidPhoneNumber || viewModel.isValidating)
        }
        .padding()
        .onAppear {
            // Focus the phone field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPhoneFieldFocused = true
            }
        }
    }
}

/// ViewModel for the phone number entry view
class PhoneNumberViewModel: ObservableObject {
    private let phoneNumberKit = PhoneNumberKit()
    
    @Published var phoneNumber = ""
    @Published var errorMessage = ""
    @Published var isValidating = false
    @Published var isValidPhoneNumber = false
    
    // Country data with dial codes and flags
    struct Country {
        let code: String
        let name: String
        let dialCode: String
        let flag: String
    }
    
    @Published var selectedCountry: Country
    let countryCodes: [Country]
    
    init() {
        // Initialize with common countries
        countryCodes = [
            Country(code: "US", name: "United States", dialCode: "+1", flag: "🇺🇸"),
            Country(code: "CA", name: "Canada", dialCode: "+1", flag: "🇨🇦"),
            Country(code: "MX", name: "Mexico", dialCode: "+52", flag: "🇲🇽"),
            Country(code: "GB", name: "United Kingdom", dialCode: "+44", flag: "🇬🇧"),
            Country(code: "IN", name: "India", dialCode: "+91", flag: "🇮🇳"),
            Country(code: "CN", name: "China", dialCode: "+86", flag: "🇨🇳"),
            Country(code: "JP", name: "Japan", dialCode: "+81", flag: "🇯🇵"),
            Country(code: "DE", name: "Germany", dialCode: "+49", flag: "🇩🇪"),
            Country(code: "FR", name: "France", dialCode: "+33", flag: "🇫🇷"),
            Country(code: "ES", name: "Spain", dialCode: "+34", flag: "🇪🇸"),
            // Add more countries as needed
        ]
        
        // Default to US or based on locale
        self.selectedCountry = countryCodes.first!
    }
    
    /// Formats the phone number as the user types
    func formatPhoneNumber() {
        // Basic formatting only - PhoneNumberKit would handle actual formatting
        // Strip non-numeric characters for validation
        let numericOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Basic validation
        isValidPhoneNumber = numericOnly.count >= 10
        
        // Clear error when user types
        if !phoneNumber.isEmpty {
            errorMessage = ""
        }
    }
    
    /// Validates the phone number with Firebase or PhoneNumberKit
    func validatePhoneNumber(completion: @escaping (Bool) -> Void) {
        isValidating = true
        errorMessage = ""
        
        // Simulate validation (in real app, this would call Firebase)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Simple validation for now
            let isValid = self.phoneNumber.count >= 10
            
            if !isValid {
                self.errorMessage = "Please enter a valid phone number"
            }
            
            self.isValidating = false
            completion(isValid)
        }
    }
}

#Preview {
    PhoneNumberView { phoneNumber in
        print("Phone number validated: \(phoneNumber)")
    }
} 