//
//  ContentView.swift
//  Focus4v4
//
//  Created by Jonathan Serrano on 4/2/25.
//

import SwiftUI
import CoreData
import Focus4Shared

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var connectivityManager: ConnectivityManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                watchConnectionInfo
                
                // Firebase Status Indicator
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    #if canImport(FirebaseAuth)
                    Text(FirebaseManager.shared.isUserSignedIn ? "Firebase: Signed In" : "Firebase: Ready")
                        .font(.headline)
                    #else
                    Text("Firebase: Not Available")
                        .font(.headline)
                    #endif
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                Divider()
                
                List {
                    ForEach(items) { item in
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Focus4")
        }
        .onAppear {
            // Verify connectivity
            print("iPhone-Watch connectivity: \(connectivityManager.isReachable ? "Connected" : "Not connected")")
        }
    }
    
    private var watchConnectionInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: connectivityManager.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                    .font(.title3)
                    .foregroundColor(connectivityManager.isReachable ? .green : .red)
                
                Text(connectivityManager.isReachable ? "Watch Connected" : "Watch Not Connected")
                    .font(.headline)
                
                Spacer()
                
                Button(action: updateWatchStatus) {
                    Label("", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if connectivityManager.isReachable {
                Button("Send Data to Watch") {
                    sendDataToWatch()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func updateWatchStatus() {
        // This will update the isReachable status in the UI
        print("Watch reachable: \(connectivityManager.isReachable)")
    }
    
    private func sendDataToWatch() {
        let currentTime = Date().timeIntervalSince1970
        let message: [String: Any] = [
            "type": "dataUpdate",
            "timestamp": currentTime,
            "itemCount": items.count
        ]
        
        connectivityManager.sendMessage(message,
            replyHandler: { reply in
                print("Watch replied: \(reply)")
            },
            errorHandler: { error in
                print("Error sending to watch: \(error.localizedDescription)")
            }
        )
        
        // Also update complications if they're enabled
        connectivityManager.updateComplications(with: [
            "itemCount": items.count,
            "lastUpdated": currentTime
        ])
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
