import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $appState.selectedTab) {
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
                appState.createEventPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(Color("Hot"), in: Circle())
                    .shadow(color: Color("Hot").opacity(0.45), radius: 18, y: 8)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 70)
        }
        .sheet(isPresented: $appState.createEventPresented) {
            NavigationStack {
                CreateEventSheet()
            }
        }
    }
}

private struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var location = "Алматы"
    @State private var category = "Кино"
    @State private var price = "0"

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
                TextField("Цена, ₸", text: $price)
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
