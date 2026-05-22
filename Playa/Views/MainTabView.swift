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

    private let categories = ["Кино", "Концерт", "Фестиваль", "Food", "Gaming", "Business"]

    var body: some View {
        ZStack {
            PlayaBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headline
                    field(label: "Название", placeholder: "Что за событие?", text: $title)
                    field(label: "Локация", placeholder: "Город · площадка", text: $location)
                    categoryPicker
                    field(label: "Цена, звёзды", placeholder: "50", text: $price, keyboard: .numberPad)

                    Button {
                        PlayaFeedback.impact(.medium)
                        let stars = Int(price.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                        appState.createLocalEvent(title: title, location: location, category: category, starPrice: stars)
                        appState.selectedTab = .events
                        ToastCenter.shared.success("Событие создано")
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Опубликовать")
                        }
                    }
                    .buttonStyle(PlayaPrimaryButton())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                    .padding(.top, 6)

                    Text("В TestFlight событие создаётся локально и сразу попадает на вкладку «События». После подключения живой базы форма будет сохранять событие в Supabase.")
                        .playaCaption()
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    PlayaFeedback.selection()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(PlayaIconButton(size: 36))
            }
            ToolbarItem(placement: .principal) {
                Text("Новое событие")
                    .font(.playaMono(11, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Pieces

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Создать")
                Text("·")
                Text("TestFlight demo")
            }
            .playaLabel()

            (
                Text("Город ")
                    .font(.playaDisplay(32, weight: .black))
                    .foregroundColor(.white)
                +
                Text("придёт")
                    .font(.playaSerif(36))
                    .italic()
                    .foregroundColor(PlayaStyle.hot)
                +
                Text(".")
                    .font(.playaDisplay(32, weight: .black))
                    .foregroundColor(.white)
            )
            .tracking(-0.4)
            .padding(.top, 4)
        }
        .padding(.top, 12)
    }

    private func field(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).playaLabel()
            TextField("", text: text,
                      prompt: Text(placeholder).foregroundColor(.white.opacity(0.35)))
                .font(.playaSans(16, weight: .medium))
                .foregroundColor(.white)
                .tint(PlayaStyle.hot)
                .keyboardType(keyboard)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Категория").playaLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { item in
                        Button {
                            PlayaFeedback.selection()
                            category = item
                        } label: {
                            Text(item)
                        }
                        .buttonStyle(PlayaChipButton(active: category == item))
                    }
                }
            }
        }
    }
}
