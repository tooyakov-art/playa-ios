import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable {
        case events
        case categories
        case feed
        case matches
        case profile
    }

    @Published var selectedTab: Tab = .events
    @Published var composePresented: Bool = false
}
