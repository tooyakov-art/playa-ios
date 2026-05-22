import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    init() {
        // Editorial dark tab bar — translucent ink with hairline top border.
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(PlayaStyle.ink900).withAlphaComponent(0.55)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)

        let normal = UIColor.white.withAlphaComponent(0.40)
        let selected = UIColor(PlayaStyle.hot)
        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = normal
        item.normal.titleTextAttributes = [
            .foregroundColor: normal,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        item.selected.iconColor = selected
        item.selected.titleTextAttributes = [
            .foregroundColor: selected,
            .font: UIFont.systemFont(ofSize: 10, weight: .heavy)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: Binding(
                get: { appState.selectedTab },
                set: { newTab in
                    if newTab != appState.selectedTab { PlayaFeedback.selection() }
                    appState.selectedTab = newTab
                }
            )) {
                FeedScreen()
                    .tabItem { Label("Главная", systemImage: "house.fill") }
                    .tag(AppState.Tab.feed)

                EventsScreen()
                    .tabItem { Label("События", systemImage: "ticket.fill") }
                    .tag(AppState.Tab.events)

                MatchesListView()
                    .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill") }
                    .tag(AppState.Tab.matches)

                ProfileScreen()
                    .tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }
                    .tag(AppState.Tab.profile)
            }
            .tint(Color("Hot"))

            Button {
                PlayaFeedback.impact(.medium)
                appState.createEventPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        Circle()
                            .fill(PlayaStyle.hot)
                            .shadow(color: PlayaStyle.hot.opacity(0.46), radius: 22, x: 0, y: 10)
                    )
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    )
            }
            .accessibilityLabel("Создать мероприятие")
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $appState.createEventPresented) {
            NavigationStack { CreateEventSheet() }
        }
        .sheet(isPresented: $appState.starsStorePresented) {
            StarsStoreSheet()
        }
    }
}

private struct CreateEventSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var location = "Алматы"
    @State private var category = "Кино"
    @State private var price = "50"

    var body: some View {
        Form {
            Section("Новое мероприятие") {
                TextField("Название", text: $title)
                TextField("Локация", text: $location)
                Picker("Категория", selection: $category) {
                    ForEach(["Кино", "Концерт", "Фестиваль", "Food", "Gaming", "Business"], id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                TextField("Цена, звезды", text: $price)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    let stars = Int(price.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                    appState.createLocalEvent(title: title, location: location, category: category, starPrice: stars)
                    appState.selectedTab = .events
                    dismiss()
                } label: {
                    Label("Создать мероприятие", systemImage: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("В TestFlight мероприятие создается локально и сразу появляется во вкладке «События». После подключения живой базы форма будет сохранять событие в Supabase.")
            }
        }
        .navigationTitle("Создать событие")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
        }
    }
}
