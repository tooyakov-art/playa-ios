import SwiftUI

@MainActor
struct SettingsScreen: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("playa.profile.name") private var profileName = "Гость Playa"
    @AppStorage("playa.profile.username") private var profileUsername = "playa.user"
    @AppStorage("playa.profile.city") private var profileCity = "Алматы"
    @AppStorage("playa.profile.bio") private var profileBio = "Здесь будут рекомендации, билеты, QR, чаты событий и сохранённые места."

    @State private var deleteStage: DeleteStage = .idle
    @State private var accountError: String?

    private enum DeleteStage {
        case idle
        case firstConfirm
        case finalConfirm
        case deleting
    }

    var body: some View {
        List {
            accountSection
            languageSection
            subscriptionSection
            starsSection
            notificationsSection
            documentsSection
            appSection
        }
        .scrollContentBackground(.hidden)
        .background(PlayaBackground())
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
        }
        .task {
            if settings.backendStatus == .unchecked {
                await refreshBackendStatus()
            }
        }
        .confirmationDialog(
            "Удалить аккаунт?",
            isPresented: Binding(get: { deleteStage == .firstConfirm }, set: { if !$0 { deleteStage = .idle } }),
            titleVisibility: .visible
        ) {
            Button("Продолжить", role: .destructive) { deleteStage = .finalConfirm }
            Button("Отмена", role: .cancel) { deleteStage = .idle }
        } message: {
            Text("Профиль, билеты, чаты и сохраненные данные будут удалены.")
        }
        .confirmationDialog(
            "Точно удалить навсегда?",
            isPresented: Binding(get: { deleteStage == .finalConfirm }, set: { if !$0 { deleteStage = .idle } }),
            titleVisibility: .visible
        ) {
            Button("Удалить аккаунт", role: .destructive) {
                Task { await runDeleteAccount() }
            }
            Button("Отмена", role: .cancel) { deleteStage = .idle }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }

    private var accountSection: some View {
        Section("Аккаунт") {
            TextField("Имя", text: $profileName)
            TextField("Username", text: $profileUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Город", text: $profileCity)
            TextField("О себе", text: $profileBio, axis: .vertical)
                .lineLimit(3...6)

            SettingsValueRow(title: "Email", value: auth.userEmail ?? "Не указан")
            SettingsValueRow(title: "Вход", value: auth.isLocalAccount ? "На этом устройстве" : "Аккаунт Playa")

            Button {
                Task { await auth.signOut() }
            } label: {
                Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
            }

            Button(role: .destructive) {
                deleteStage = .firstConfirm
            } label: {
                Label(deleteStage == .deleting ? "Удаление..." : "Удалить аккаунт", systemImage: "trash")
            }
            .disabled(deleteStage == .deleting)

            if let accountError {
                Text(accountError)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .listRowBackground(Color("Ink800"))
    }

    private var languageSection: some View {
        Section {
            Picker("Язык приложения", selection: $settings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Язык")
        } footer: {
            Text("Выбранный язык сохранится для следующих экранов приложения.")
        }
        .listRowBackground(Color("Ink800"))
    }

    private var subscriptionSection: some View {
        Section {
            ForEach(SubscriptionTier.allCases) { tier in
                Button {
                    settings.subscriptionTier = tier
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: settings.subscriptionTier == tier ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(settings.subscriptionTier == tier ? Color("Hot") : .white.opacity(0.45))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tier.title)
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Text(tier.priceText)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Text(tier.subtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.58))
                        }
                    }
                    .foregroundColor(.white)
                }
            }
        } header: {
            Text("Подписка")
        } footer: {
            Text("Тариф сохранится в профиле. Оплата станет доступна после подключения продуктов в App Store.")
        }
        .listRowBackground(Color("Ink800"))
    }

    private var starsSection: some View {
        Section("Звезды и билеты") {
            HStack {
                Label("Баланс", systemImage: "star.fill")
                    .foregroundColor(.yellow)
                Spacer()
                Text(appState.starBalance.formatted(.number.grouping(.automatic)))
                    .font(.system(size: 16, weight: .bold))
            }

            Button {
                appState.starsStorePresented = true
            } label: {
                Label("Купить звезды", systemImage: "sparkles")
            }

            SettingsValueRow(title: "История", value: "Покупки на этом устройстве")
            SettingsValueRow(title: "Оплата билетов", value: "Только звездами")
        }
        .listRowBackground(Color("Ink800"))
    }

    private var notificationsSection: some View {
        Section("Уведомления") {
            Toggle("Сообщения в чатах", isOn: $settings.chatNotificationsEnabled)
            Toggle("Напоминания о событиях", isOn: $settings.eventRemindersEnabled)
            Toggle("Рекомендации в ленте", isOn: $settings.recommendationsEnabled)
        }
        .listRowBackground(Color("Ink800"))
    }

    private var documentsSection: some View {
        Section("Документы") {
            ForEach(settings.legalDocuments) { document in
                Link(destination: document.url) {
                    Label(document.title, systemImage: "doc.text")
                }
            }

            Button {
                openURL(URL(string: "mailto:\(PlayaConfig.supportEmail)")!)
            } label: {
                Label("Support", systemImage: "envelope")
            }
        }
        .listRowBackground(Color("Ink800"))
    }

    private var appSection: some View {
        Section("Приложение") {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: backendIcon)
                    .foregroundColor(backendColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.backendStatus.title)
                        .font(.system(size: 15, weight: .bold))
                    Text(settings.backendStatus.detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.58))
                }
            }

            Button {
                Task { await refreshBackendStatus() }
            } label: {
                Label("Проверить базу", systemImage: "arrow.clockwise")
            }

            SettingsValueRow(title: "Версия", value: "\(PlayaConfig.appVersion) (\(PlayaConfig.appBuild))")
            SettingsValueRow(title: "Bundle", value: "app.playahub")
            SettingsValueRow(title: "Сервер", value: PlayaConfig.supabaseURL.host ?? "не задан")
        }
        .listRowBackground(Color("Ink800"))
    }

    private var backendColor: Color {
        switch settings.backendStatus {
        case .online: return .green
        case .offline: return .red
        case .checking: return .yellow
        case .unchecked: return .white.opacity(0.55)
        }
    }

    private var backendIcon: String {
        switch settings.backendStatus {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.octagon.fill"
        case .checking: return "hourglass"
        case .unchecked: return "questionmark.circle"
        }
    }

    private func refreshBackendStatus() async {
        settings.backendStatus = .checking
        settings.backendStatus = await auth.supabase.backendDiagnostic()
    }

    private func runDeleteAccount() async {
        deleteStage = .deleting
        accountError = nil
        do {
            try await auth.deleteAccount()
            deleteStage = .idle
            dismiss()
        } catch {
            deleteStage = .idle
            accountError = "Ошибка удаления: \(error.localizedDescription)"
        }
    }
}

@MainActor
struct BackendDiagnosticsView: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .bold))
                .foregroundColor(color)

            VStack(spacing: 8) {
                Text(settings.backendStatus.title)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                Text(settings.backendStatus.detail)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await refresh() }
            } label: {
                Label("Проверить еще раз", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("Hot"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Ink900").ignoresSafeArea())
        .navigationTitle("Статус базы")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
    }

    private var color: Color {
        switch settings.backendStatus {
        case .online: return .green
        case .offline: return .red
        case .checking: return .yellow
        case .unchecked: return .white.opacity(0.55)
        }
    }

    private var icon: String {
        switch settings.backendStatus {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.octagon.fill"
        case .checking: return "hourglass"
        case .unchecked: return "questionmark.circle"
        }
    }

    private func refresh() async {
        settings.backendStatus = .checking
        settings.backendStatus = await auth.supabase.backendDiagnostic()
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.62))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14, weight: .semibold))
    }
}
