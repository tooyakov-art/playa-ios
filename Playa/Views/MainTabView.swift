import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            EventsScreen()
                .tabItem { Label("События", systemImage: "sparkles") }
                .tag(AppState.Tab.events)

            CategoriesScreen()
                .tabItem { Label("Категории", systemImage: "square.grid.2x2") }
                .tag(AppState.Tab.categories)

            FeedScreen()
                .tabItem { Label("Лента", systemImage: "rectangle.grid.1x2") }
                .tag(AppState.Tab.feed)

            MatchesListView()
                .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right") }
                .tag(AppState.Tab.matches)

            ProfileScreen()
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
                .tag(AppState.Tab.profile)
        }
        .tint(Color("Hot"))
    }
}
