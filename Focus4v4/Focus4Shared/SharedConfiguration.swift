import Foundation

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