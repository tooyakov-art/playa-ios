import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: Auth

    var body: some View {
        ZStack {
            Group {
                if auth.isAuthenticated {
                    MainTabView()
                } else {
                    LoginScreen()
                }
            }
            .animation(.easeInOut(duration: 0.22), value: auth.isAuthenticated)

            ToastOverlay()
                .padding(.top, 8)
        }
    }
}
