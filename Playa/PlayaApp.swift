import SwiftUI

@main
struct PlayaApp: App {
    @StateObject private var auth = Auth()
    @StateObject private var appState = AppState()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(appState)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}
