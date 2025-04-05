import SwiftUI
import Focus4Shared

/// The initial welcome screen shown to users when the app is first launched
/// This is the entry point to the authentication flow
struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showGetStarted = false
    
    var onGetStartedTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App logo and title
            VStack(spacing: 20) {
                Image(systemName: "circle.hexagongrid.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)
                
                Text("Focus4")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(isAnimating ? 1 : 0)
            }
            
            // App description
            Text("The next generation focus and productivity app")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
            
            Spacer()
            
            // Get started button
            Button {
                onGetStartedTapped()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(14)
                    .padding(.horizontal, 30)
            }
            .opacity(showGetStarted ? 1 : 0)
            .offset(y: showGetStarted ? 0 : 20)
            
            // Terms and privacy links
            HStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    // Show terms of service
                } label: {
                    Text("Terms")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    // Show privacy policy
                } label: {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 30)
            .opacity(showGetStarted ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // Slight delay before showing the get started button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showGetStarted = true
                }
            }
        }
    }
}

#Preview {
    WelcomeView {
        print("Get Started tapped")
    }
} 