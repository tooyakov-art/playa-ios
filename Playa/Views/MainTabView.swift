import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @State private var previousTab: AppState.Tab = .feed

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(PlayaStyle.ink900).withAlphaComponent(0.72)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

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
        VStack(spacing: 0) {
            if auth.isDemoMode {
                DemoModeBanner()
            }

            TabView(selection: tabSelection) {
                FeedScreen()
                    .tabItem { Label("Главная", systemImage: "house.fill") }
                    .tag(AppState.Tab.feed)

                EventsScreen()
                    .tabItem { Label("События", systemImage: "ticket.fill") }
                    .tag(AppState.Tab.events)

                Color.clear
                    .tabItem { Label("Создать", systemImage: "plus.circle.fill") }
                    .tag(AppState.Tab.create)

                MatchesListView()
                    .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill") }
                    .tag(AppState.Tab.matches)

                ProfileScreen()
                    .tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }
                    .tag(AppState.Tab.profile)
            }
            .tint(Color("Hot"))
        }
        .background(PlayaStyle.ink900.ignoresSafeArea())
        .sheet(isPresented: $appState.createEventPresented) {
            NavigationStack { CreateEventSheet() }
        }
        .sheet(isPresented: $appState.starsStorePresented) {
            StarsStoreSheet()
        }
    }

    private var tabSelection: Binding<AppState.Tab> {
        Binding(
            get: { appState.selectedTab },
            set: { newTab in
                if newTab == .create {
                    PlayaFeedback.impact(.medium)
                    appState.createEventPresented = true
                    appState.selectedTab = previousTab
                    return
                }

                if newTab != appState.selectedTab {
                    PlayaFeedback.selection()
                }
                previousTab = newTab
                appState.selectedTab = newTab
            }
        )
    }
}

private struct DemoModeBanner: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PlayaStyle.hot)
            VStack(alignment: .leading, spacing: 1) {
                Text("ДЕМО-РЕЖИМ")
                    .playaLabel(color: .white)
                Text("Данные только на этом устройстве · без оплаты")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.58))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            PlayaStyle.ink800
                .overlay(PlayaStyle.hot.opacity(0.07))
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(PlayaStyle.hot.opacity(0.24)),
            alignment: .bottom
        )
        .accessibilityElement(children: .combine)
    }
}

private struct CreateEventSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var venue = ""
    @State private var category = "Кино"
    @State private var price = "0"
    @State private var capacity = ""
    @State private var eventDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var eventTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var previewPresented = false

    private let categories = ["Кино", "Концерт", "Фестиваль", "Еда", "Игры", "Бизнес", "Спорт", "Выставка"]

    var body: some View {
        ZStack {
            PlayaBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headline
                    field(label: "Название", placeholder: "Что за событие?", text: $title)
                    multilineField(label: "Описание", placeholder: "Что произойдёт и кому будет интересно?", text: $description)
                    field(label: "Точный адрес", placeholder: "Город · площадка · улица", text: $venue)
                    dateAndTime
                    categoryPicker

                    HStack(alignment: .top, spacing: 12) {
                        field(label: "Вместимость", placeholder: "100", text: $capacity, keyboard: .numberPad)
                        field(label: "Демо-звёзды", placeholder: "0", text: $price, keyboard: .numberPad)
                    }

                    Button {
                        previewPresented = true
                    } label: {
                        Label("Предпросмотр", systemImage: "eye.fill")
                    }
                    .buttonStyle(PlayaGhostButton())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        saveDraft()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Сохранить черновик")
                        }
                    }
                    .buttonStyle(PlayaPrimaryButton())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)

                    Text("Черновик не публикуется и виден только на этом устройстве. Для реальной публикации ещё понадобятся обложка, правила билета и подключённая база.")
                        .playaCaption()
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 2)
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
                .accessibilityLabel("Закрыть")
            }
            ToolbarItem(placement: .principal) {
                Text("Черновик события")
                    .font(.playaMono(11, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $previewPresented) {
            NavigationStack {
                DraftEventPreview(
                    title: title,
                    description: description,
                    venue: venue,
                    category: category,
                    startsAt: combinedStartDate,
                    capacity: Int(capacity) ?? 0,
                    stars: Int(price) ?? 0
                )
            }
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Создание")
                Text("·")
                Text("не опубликовано")
            }
            .playaLabel(color: PlayaStyle.hot)

            (
                Text("Собери ")
                    .font(.playaDisplay(32, weight: .black))
                    .foregroundColor(.white)
                +
                Text("черновик")
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

    private var dateAndTime: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дата и время").playaLabel()
            DatePicker("Дата", selection: $eventDate, in: Date()..., displayedComponents: .date)
            Divider().background(PlayaStyle.hairline)
            DatePicker("Начало", selection: $eventTime, displayedComponents: .hourAndMinute)
        }
        .font(.playaSans(15, weight: .semibold))
        .foregroundColor(.white)
        .tint(PlayaStyle.hot)
        .padding(14)
        .playaPoster()
    }

    private func field(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).playaLabel()
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.35)))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func multilineField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).playaLabel()
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.playaSans(16, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text)
                    .font(.playaSans(16, weight: .medium))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(8)
            }
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

    private var combinedStartDate: Date {
        let calendar = Calendar.current
        let dateParts = calendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeParts = calendar.dateComponents([.hour, .minute], from: eventTime)
        var components = DateComponents()
        components.year = dateParts.year
        components.month = dateParts.month
        components.day = dateParts.day
        components.hour = timeParts.hour
        components.minute = timeParts.minute
        return calendar.date(from: components) ?? eventDate
    }

    private func saveDraft() {
        PlayaFeedback.impact(.medium)
        appState.createLocalEvent(
            title: title,
            description: description,
            location: venue,
            category: category,
            startsAt: combinedStartDate,
            starPrice: Int(price.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
            capacity: Int(capacity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        )
        appState.selectedTab = .events
        ToastCenter.shared.success("Черновик сохранён на устройстве")
        dismiss()
    }
}

private struct DraftEventPreview: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let description: String
    let venue: String
    let category: String
    let startsAt: Date
    let capacity: Int
    let stars: Int

    var body: some View {
        ZStack {
            PlayaBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("ПРЕДПРОСМОТР ЧЕРНОВИКА")
                        .playaLabel(color: PlayaStyle.hot)
                    Text(title.isEmpty ? "Без названия" : title)
                        .font(.playaDisplay(34, weight: .black))
                        .foregroundColor(.white)
                    Text(description.isEmpty ? "Описание пока не добавлено." : description)
                        .playaBody()
                        .foregroundColor(.white.opacity(0.72))

                    VStack(spacing: 0) {
                        previewRow("Категория", category)
                        Divider().background(PlayaStyle.hairline)
                        previewRow("Когда", startsAt.formatted(date: .abbreviated, time: .shortened))
                        Divider().background(PlayaStyle.hairline)
                        previewRow("Где", venue.isEmpty ? "Адрес не указан" : venue)
                        Divider().background(PlayaStyle.hairline)
                        previewRow("Вместимость", capacity > 0 ? "\(capacity)" : "Не указана")
                        Divider().background(PlayaStyle.hairline)
                        previewRow("Стоимость", stars > 0 ? "\(stars) демо-звёзд" : "Бесплатно")
                    }
                    .padding(16)
                    .playaPoster()

                    Text("Это только локальный черновик. Кнопки покупки и публикации не показываются.")
                        .playaCaption()
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(20)
            }
        }
        .navigationTitle("Предпросмотр")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { dismiss() }
            }
        }
    }

    private func previewRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(title)
                .playaLabel(color: .white.opacity(0.45))
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.playaSans(14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 11)
    }
}
