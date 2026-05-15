import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable {
        case feed
        case events
        case matches
        case profile
    }

    @Published var selectedTab: Tab = .feed
    @Published var createEventPresented: Bool = false
}
