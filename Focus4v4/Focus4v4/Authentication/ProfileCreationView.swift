import SwiftUI
import Focus4Shared
import PhotosUI

/// View for creating a user profile after successful phone verification
/// This is the fourth step in the authentication flow after phone verification
struct ProfileCreationView: View {
    @StateObject private var viewModel = ProfileCreationViewModel()
    @State private var photoPickerItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?
    
    var onProfileCreated: (String) -> Void
    
    enum Field {
        case username
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Create Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top)
                
                Text("Let's set up your Focus4 account")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer().frame(height: 20)
                
                // Profile picture
                VStack {
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.secondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        }
                    }
                    
                    Text("Add Profile Photo")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 10)
                .onChange(of: photoPickerItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.profileImage = image
                            }
                        }
                    }
                }
                
                // Username input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Username")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Choose a username", text: $viewModel.username)
                        .focused($focusedField, equals: .username)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !viewModel.usernameErrorMessage.isEmpty {
                        Text(viewModel.usernameErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer().frame(height: 20)
                
                // Create profile button
                Button {
                    viewModel.createProfile { success, error in
                        if success {
                            onProfileCreated(viewModel.username)
                        }
                    }
                } label: {
                    if viewModel.isCreatingProfile {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 20)
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(viewModel.isValidUsername ? Color.blue : Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
                .disabled(!viewModel.isValidUsername || viewModel.isCreatingProfile)
                
                Spacer().frame(height: 20)
                
                // Skip button (if we want to allow this)
                Button("I'll do this later") {
                    // Generate a random username
                    viewModel.generateRandomUsername { username in
                        onProfileCreated(username)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .username
            }
        }
    }
}

/// ViewModel for the profile creation view
class ProfileCreationViewModel: ObservableObject {
    @Published var username = ""
    @Published var profileImage: UIImage?
    @Published var usernameErrorMessage = ""
    @Published var isCreatingProfile = false
    
    var isValidUsername: Bool {
        username.count >= 3 && usernameErrorMessage.isEmpty
    }
    
    /// Validates the username
    func validateUsername() {
        usernameErrorMessage = ""
        
        // Basic validation
        if username.isEmpty {
            return
        }
        
        if username.count < 3 {
            usernameErrorMessage = "Username must be at least 3 characters"
            return
        }
        
        // Check if username contains only valid characters
        let usernameRegex = "^[a-zA-Z0-9_\\.]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        if !usernamePredicate.evaluate(with: username) {
            usernameErrorMessage = "Username can only contain letters, numbers, underscores, and periods"
            return
        }
        
        // Here you would typically check if the username is already taken
        // For now, we'll just simulate this check
        if username.lowercased() == "admin" {
            usernameErrorMessage = "This username is already taken"
        }
    }
    
    /// Creates the user profile
    func createProfile(completion: @escaping (Bool, Error?) -> Void) {
        validateUsername()
        
        if !isValidUsername {
            completion(false, NSError(domain: "ProfileCreation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid username"]))
            return
        }
        
        isCreatingProfile = true
        
        // In a real app, this would save the profile to Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.isCreatingProfile = false
            completion(true, nil)
        }
    }
    
    /// Generates a random username if the user skips profile creation
    func generateRandomUsername(completion: @escaping (String) -> Void) {
        isCreatingProfile = true
        
        // Generate a random username
        let randomNumber = Int.random(in: 10000...99999)
        let generatedUsername = "user\(randomNumber)"
        
        // In a real app, this would ensure the random username is not taken
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.username = generatedUsername
            self.isCreatingProfile = false
            completion(generatedUsername)
        }
    }
}

#Preview {
    ProfileCreationView { username in
        print("Profile created with username: \(username)")
    }
} 