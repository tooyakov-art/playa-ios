import SwiftUI

@main
struct PlayaApp: App {
    @StateObject private var auth = Auth()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
