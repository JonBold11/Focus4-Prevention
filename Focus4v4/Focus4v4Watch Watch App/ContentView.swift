//
//  ContentView.swift
//  Focus4v4Watch Watch App
//
//  Created by Jonathan Serrano on 4/2/25.
//

import SwiftUI
import Focus4Shared

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var connectivityManager: ConnectivityManager
    
    @State private var connectionStatus = "Checking..."
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Focus4 Watch")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Connection Status:")
                    .font(.headline)
                
                Text(connectionStatus)
                    .foregroundColor(connectivityManager.isReachable ? .green : .red)
                    .fontWeight(.medium)
                
                Button(action: checkConnection) {
                    Label("Check Connection", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                
                if connectivityManager.isReachable {
                    Button(action: sendTestMessage) {
                        Label("Send Test Message", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
                
                Text(messageStatus)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
            .padding()
            .onAppear {
                checkConnection()
            }
        }
    }
    
    private var messageStatus: String {
        if let lastMessage = connectivityManager.lastMessage {
            return "Last message: \(lastMessage)"
        } else {
            return "No messages received"
        }
    }
    
    private func checkConnection() {
        connectionStatus = connectivityManager.isReachable ? "Connected" : "Not Connected"
    }
    
    private func sendTestMessage() {
        let message = ["type": "test", "timestamp": Date().timeIntervalSince1970]
        connectivityManager.sendMessage(message,
            replyHandler: { reply in
                print("Reply received: \(reply)")
            },
            errorHandler: { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        )
    }
}

#Preview {
    ContentView()
}
