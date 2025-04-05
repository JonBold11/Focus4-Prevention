import SwiftUI
import Focus4Shared

/// View for the final step of the authentication flow
/// Shown after the user has completed setup, either with or without a recovery email
struct OnboardingCompletionView: View {
    private let username: String
    private let hasRecoveryEmail: Bool
    
    @State private var isAnimating = false
    
    var onComplete: () -> Void
    
    init(username: String, hasRecoveryEmail: Bool, onComplete: @escaping () -> Void) {
        self.username = username
        self.hasRecoveryEmail = hasRecoveryEmail
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1 : 0.25)
                    .opacity(isAnimating ? 1 : 0)
            }
            
            // Welcome text
            Text("Welcome to Focus4")
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Text("Your account is ready, \(username)")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Spacer()
            
            // Account security status
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.blue)
                    
                    Text("Account Security")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(hasRecoveryEmail ? "Strong" : "Basic")
                        .font(.subheadline)
                        .foregroundColor(hasRecoveryEmail ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(hasRecoveryEmail ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        )
                }
                
                securityInfoRow(
                    icon: "phone.fill",
                    title: "Phone Authentication",
                    status: "Active",
                    statusColor: .green
                )
                
                securityInfoRow(
                    icon: "envelope.fill",
                    title: "Recovery Email",
                    status: hasRecoveryEmail ? "Configured" : "Not Set",
                    statusColor: hasRecoveryEmail ? .green : .secondary
                )
                
                if !hasRecoveryEmail {
                    Text("You can add a recovery email later in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 35)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
            
            Spacer()
            
            // Continue button
            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            .opacity(isAnimating ? 1 : 0)
            .padding(.bottom, 30)
        }
        .onAppear {
            // Start the animation sequence
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    /// Helper function to create security info rows
    private func securityInfoRow(icon: String, title: String, status: String, statusColor: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .padding(.leading, 5)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(status)
                .font(.subheadline)
                .foregroundColor(statusColor)
        }
    }
}

#Preview {
    OnboardingCompletionView(
        username: "johndoe",
        hasRecoveryEmail: true,
        onComplete: {
            print("Onboarding completed")
        }
    )
} 