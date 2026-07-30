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
    @AppStorage("playa.profile.bio") private var profileBio = "Здесь появятся твои планы, билеты и сохранённые события."

    @State private var deleteStage: DeleteStage = .idle
    @State private var accountError: String?
    @State private var resetDemoConfirmation = false

    private enum DeleteStage {
        case idle
        case firstConfirm
        case finalConfirm
        case deleting
    }

    var body: some View {
        List {
            accountStatusSection
            profileSection
            languageSection
            subscriptionSection
            if auth.isDemoMode {
                demoDataSection
            }
            notificationsSection
            documentsSection
            appSection
            dangerSection
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
            Text(auth.isDemoMode
                 ? "Локальный демо-профиль и данные на устройстве будут удалены."
                 : "Профиль, билеты, чаты и сохранённые данные будут удалены.")
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
        .confirmationDialog(
            "Очистить демо-данные?",
            isPresented: $resetDemoConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                appState.resetDemoData()
                ToastCenter.shared.success("Демо-данные очищены")
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Черновики, интересы, сохранённые события, билеты, звёзды и локальные реакции будут удалены только с этого устройства.")
        }
    }

    private var accountStatusSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: auth.isDemoMode ? "sparkles" : "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(auth.isDemoMode ? Color("Hot") : .green)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.07), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(auth.accountModeTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(auth.isDemoMode
                         ? "Аккаунт не подключён. Данные не синхронизируются и не являются реальной активностью."
                         : "Сессия подключена к Playa и может синхронизироваться с сервером.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let email = auth.userEmail, !auth.isDemoMode {
                SettingsValueRow(title: "Email", value: email)
            }
        } header: {
            Text("Состояние аккаунта")
        } footer: {
            if auth.isDemoMode {
                Text("Синтетический адрес больше не показывается: демо-режим не притворяется входом через Google или Apple.")
            }
        }
        .listRowBackground(Color("Ink800"))
    }

    private var profileSection: some View {
        Section("Профиль") {
            TextField("Имя", text: $profileName)
            TextField("Username", text: $profileUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Город", text: $profileCity)
            TextField("О себе", text: $profileBio, axis: .vertical)
                .lineLimit(3...6)
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
            Text("Выбор сохраняется сразу. Полный перевод всех экранов будет применён после подключения локализованных строк.")
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
            Text("Это выбор интерфейса. Реальная оплата отключена до подключения продуктов App Store.")
        }
        .listRowBackground(Color("Ink800"))
    }

    private var demoDataSection: some View {
        Section {
            SettingsValueRow(title: "Звёзды", value: appState.starBalance.formatted(.number.grouping(.automatic)))
            SettingsValueRow(title: "Билеты", value: "\(appState.purchasedTicketEventIds.count)")
            SettingsValueRow(title: "Черновики", value: "\(appState.createdEvents.count)")
            SettingsValueRow(title: "Сохранено", value: "\(appState.savedEventIds.count)")

            Button(role: .destructive) {
                resetDemoConfirmation = true
            } label: {
                Label("Очистить демо-данные", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Демо-данные на устройстве")
        } footer: {
            Text("Это не покупки, не реальные билеты и не серверная статистика.")
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
        Section("Документы и помощь") {
            ForEach(settings.legalDocuments) { document in
                Link(destination: document.url) {
                    Label(document.title, systemImage: "doc.text")
                }
            }

            Button {
                openURL(URL(string: "mailto:\(PlayaConfig.supportEmail)")!)
            } label: {
                Label("Написать в поддержку", systemImage: "envelope")
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

    private var dangerSection: some View {
        Section {
            Button {
                Task { await auth.signOut() }
            } label: {
                Label(auth.isDemoMode ? "Закрыть демо-режим" : "Выйти", systemImage: "rectangle.portrait.and.arrow.right")
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
        } header: {
            Text("Управление аккаунтом")
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
            if auth.isDemoMode {
                appState.resetDemoData()
            }
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
                Label("Проверить ещё раз", systemImage: "arrow.clockwise")
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
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .font(.system(size: 14, weight: .semibold))
    }
}
