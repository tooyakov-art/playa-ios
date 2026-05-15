import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @AppStorage("playa.profile.name") private var profileName = "Адильхан Таргетолог"
    @AppStorage("playa.profile.username") private var profileUsername = "adilkhan.playa"
    @AppStorage("playa.profile.city") private var profileCity = "Алматы"
    @AppStorage("playa.profile.bio") private var profileBio = "Персональный профиль Playa: рекомендации, билеты, QR, чаты событий и посты от компаний. Тут будет нормальная витрина пользователя после регистрации."

    @State private var isEditingProfile = false
    @State private var deleteStage: DeleteStage = .idle
    @State private var errorMessage: String?

    private enum DeleteStage {
        case idle
        case firstConfirm
        case finalConfirm
        case deleting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        stats
                        bio
                        gallery
                        accountControls
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Изм.") { isEditingProfile = true }
                        .font(.system(size: 15, weight: .bold))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                NavigationStack {
                    EditProfileSheet(
                        name: $profileName,
                        username: $profileUsername,
                        city: $profileCity,
                        bio: $profileBio
                    )
                }
            }
            .confirmationDialog(
                "Удалить аккаунт?",
                isPresented: Binding(get: { deleteStage == .firstConfirm }, set: { if !$0 { deleteStage = .idle } }),
                titleVisibility: .visible
            ) {
                Button("Продолжить", role: .destructive) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        deleteStage = .finalConfirm
                    }
                }
                Button("Отмена", role: .cancel) { deleteStage = .idle }
            } message: {
                Text("Аккаунт и связанные данные будут удалены.")
            }
            .confirmationDialog(
                "Точно удалить?",
                isPresented: Binding(get: { deleteStage == .finalConfirm }, set: { if !$0 { deleteStage = .idle } }),
                titleVisibility: .visible
            ) {
                Button("Удалить навсегда", role: .destructive) {
                    Task { await runDelete() }
                }
                Button("Отмена", role: .cancel) { deleteStage = .idle }
            } message: {
                Text("После удаления восстановить профиль нельзя.")
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: URL(string: "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=1200&q=80"))
                .frame(height: 360)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.86)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 10) {
                AvatarView(url: nil, fallback: "А")
                    .frame(width: 74, height: 74)
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))

                Text(profileName)
                    .font(.system(size: 31, weight: .black))
                    .foregroundColor(.white)

                Text("@\(profileUsername)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.68))

                HStack(spacing: 10) {
                    Label(profileCity, systemImage: "mappin.and.ellipse")
                    Label("Создатель событий", systemImage: "sparkles")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.76))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat("24K", "подписчиков")
            stat("252", "подписок")
            stat("732", "активности")
        }
    }

    private var bio: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("О профиле")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
            Text(profileBio)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.68))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("Ink800"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последние события")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DemoContent.events.prefix(4)) { event in
                    ZStack(alignment: .bottomLeading) {
                        RemoteImage(url: event.imageURL)
                            .frame(height: 136)
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        Text(event.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var accountControls: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(appState.starBalance.formatted(.number.grouping(.automatic))) звёзд", systemImage: "star.fill")
                    .foregroundColor(.yellow)
                Spacer()
                Button("Купить") { appState.starsStorePresented = true }
                    .foregroundColor(Color("Hot"))
            }
            .font(.system(size: 15, weight: .bold))
            .padding(.bottom, 2)

            if let email = auth.userEmail {
                row("Email", email)
                row("Вход", auth.isLocalAccount ? "Локальный аккаунт" : "Аккаунт")
            } else {
                row("Режим", auth.isGuest ? "Демо" : "Аккаунт")
            }

            Button {
                Task { await auth.signOut() }
            } label: {
                Text("Выйти")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundColor(.white)
            }

            if !auth.isGuest {
                Button(role: .destructive) {
                    deleteStage = .firstConfirm
                } label: {
                    Text(deleteStage == .deleting ? "Удаление..." : "Удалить аккаунт")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .disabled(deleteStage == .deleting)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            HStack(spacing: 14) {
                Link("Privacy", destination: PlayaConfig.privacyURL)
                Link("Terms", destination: PlayaConfig.termsURL)
                Link("Support", destination: URL(string: "mailto:\(PlayaConfig.supportEmail)")!)
            }
            .font(.footnote)
            .foregroundColor(.white.opacity(0.52))
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color("Ink800"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color("Ink800"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.white.opacity(0.58))
            Spacer()
            Text(value).foregroundColor(.white)
        }
        .font(.system(size: 14, weight: .semibold))
    }

    private func runDelete() async {
        deleteStage = .deleting
        errorMessage = nil
        do {
            try await auth.deleteAccount()
            await MainActor.run { deleteStage = .idle }
        } catch {
            await MainActor.run {
                deleteStage = .idle
                errorMessage = "Ошибка удаления: \(error.localizedDescription)"
            }
        }
    }
}

private struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var name: String
    @Binding var username: String
    @Binding var city: String
    @Binding var bio: String

    @State private var draftName: String
    @State private var draftUsername: String
    @State private var draftCity: String
    @State private var draftBio: String

    init(name: Binding<String>, username: Binding<String>, city: Binding<String>, bio: Binding<String>) {
        _name = name
        _username = username
        _city = city
        _bio = bio
        _draftName = State(initialValue: name.wrappedValue)
        _draftUsername = State(initialValue: username.wrappedValue)
        _draftCity = State(initialValue: city.wrappedValue)
        _draftBio = State(initialValue: bio.wrappedValue)
    }

    var body: some View {
        Form {
            Section("Профиль") {
                TextField("Имя", text: $draftName)
                TextField("Username", text: $draftUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Город", text: $draftCity)
            }

            Section("О себе") {
                TextEditor(text: $draftBio)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("Редактировать")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") {
                    name = cleaned(draftName, fallback: name)
                    username = cleanedUsername(draftUsername, fallback: username)
                    city = cleaned(draftCity, fallback: city)
                    bio = cleaned(draftBio, fallback: bio)
                    dismiss()
                }
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func cleaned(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func cleanedUsername(_ value: String, fallback: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        return trimmed.isEmpty ? fallback : trimmed
    }
}
