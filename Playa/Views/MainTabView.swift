import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            activeScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomControls
        }
        .sheet(isPresented: $appState.createEventPresented) {
            NavigationStack {
                CreateEventSheet()
            }
        }
        .sheet(isPresented: $appState.starsStorePresented) {
            StarsStoreSheet()
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch appState.selectedTab {
        case .feed:
            FeedScreen()
        case .events:
            EventsScreen()
        case .matches:
            MatchesListView()
        case .profile:
            ProfileScreen()
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                TabBarButton(tab: .feed, title: "Главная", icon: "house.fill")
                TabBarButton(tab: .events, title: "События", icon: "ticket.fill")
                TabBarButton(tab: .matches, title: "Чаты", icon: "bubble.left.and.bubble.right.fill")
                TabBarButton(tab: .profile, title: "Профиль", icon: "person.crop.circle.fill")
            }
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)

            Button {
                appState.createEventPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 68, height: 68)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.09), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

private struct TabBarButton: View {
    @EnvironmentObject private var appState: AppState
    let tab: AppState.Tab
    let title: String
    let icon: String

    private var isSelected: Bool {
        appState.selectedTab == tab
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.58))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 6)
            .background(isSelected ? Color.white.opacity(0.14) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CreateEventSheet: View {
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
                TextField("Цена, звёзды", text: $price)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    dismiss()
                } label: {
                    Label("Создать демо-событие", systemImage: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("В TestFlight это демо-форма. Следующий шаг - сохранить событие в Supabase и показать его в рекомендациях.")
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
