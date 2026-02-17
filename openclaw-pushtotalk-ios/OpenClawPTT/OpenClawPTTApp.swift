import SwiftUI

@main
struct OpenClawPTTApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var pttManager = PTTManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(pttManager)
        }
    }
}
