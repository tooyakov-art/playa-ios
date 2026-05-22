import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: SettingsStore

    @AppStorage("playa.profile.name") private var profileName = "Адильхан Таргетолог"
    @AppStorage("playa.profile.username") private var profileUsername = "adilkhan.playa"
    @AppStorage("playa.profile.city") private var profileCity = "Алматы"
    @AppStorage("playa.profile.bio") private var profileBio = "Персональный профиль Playa: рекомендации, билеты, QR, чаты событий и посты от компаний."

    @State private var isEditingProfile = false
    @State private var settingsPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                PlayaBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        stats
                        profileHighlights
                        bio
                        gallery
                        profileActions
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $settingsPresented) {
                NavigationStack { SettingsScreen() }
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
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top action row: settings + edit
            HStack {
                HStack(spacing: 8) {
                    Text("Профиль")
                    Text("·")
                    Text(profileCity.uppercased())
                }
                .playaLabel()

                Spacer()

                Button { settingsPresented = true } label: {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(PlayaIconButton(size: 40))

                Button { isEditingProfile = true } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(PlayaIconButton(size: 40))
            }

            // Avatar + name with serif italic surname
            VStack(alignment: .leading, spacing: 14) {
                AvatarView(url: nil, fallback: String(profileName.prefix(1)))
                    .frame(width: 84, height: 84)
                    .playaGlassCircle()

                heroName

                Text("@\(profileUsername)")
                    .playaLabel(color: .white.opacity(0.6))
            }
        }
        .padding(.top, 6)
    }

    private var heroName: some View {
        let parts = profileName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
        let first = parts.first ?? profileName
        let rest = parts.count > 1 ? parts[1] : ""

        return (
            Text(first + (rest.isEmpty ? "" : "\n"))
                .font(.playaDisplay(38, weight: .black))
                .foregroundColor(.white)
            +
            Text(rest)
                .font(.playaSerif(42))
                .italic()
                .foregroundColor(PlayaStyle.hot)
        )
        .tracking(-0.5)
        .lineSpacing(-2)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat("24K", "Подписчиков")
            Divider().background(PlayaStyle.hairline).frame(height: 56)
            stat("252", "Подписки")
            Divider().background(PlayaStyle.hairline).frame(height: 56)
            stat("\(DemoContent.events.count.formatted(.number.precision(.integerLength(2))))", "Событий")
        }
        .playaPoster()
    }

    private var profileHighlights: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                highlight(title: "Подписка", value: settings.subscriptionTier.title, icon: "crown.fill", color: PlayaStyle.hot)
                highlight(title: "Звёзды", value: appState.starBalance.formatted(.number.grouping(.automatic)), icon: "star.fill", color: PlayaStyle.lime)
            }
            HStack(spacing: 10) {
                highlight(title: "Билеты", value: "\(appState.purchasedTicketEventIds.count)", icon: "ticket.fill", color: PlayaStyle.ember)
                highlight(title: "Сохранено", value: "\(appState.savedEventIds.count)", icon: "bookmark.fill", color: PlayaStyle.cyan)
            }
        }
    }

    private var bio: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("О профиле").playaLabel()
            Text(profileBio)
                .playaBody()
                .foregroundColor(.white.opacity(0.72))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .playaPoster()
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние события").playaLabel()
                Spacer()
                Text("\(DemoContent.events.count.formatted(.number.precision(.integerLength(2))))")
                    .playaLabel(color: .white.opacity(0.4))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DemoContent.events.prefix(4)) { event in
                    ZStack(alignment: .bottomLeading) {
                        RemoteImage(url: event.imageURL)
                            .frame(height: 156)
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 4) {
                            if let date = event.dateText.split(separator: " ").first {
                                Text(String(date).uppercased())
                                    .playaLabel(color: PlayaStyle.bone.opacity(0.7))
                            }
                            Text(event.title)
                                .font(.playaSans(13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: PlayaStyle.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PlayaStyle.radiusCard, style: .continuous)
                            .stroke(PlayaStyle.hairline, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var profileActions: some View {
        VStack(spacing: 10) {
            Button {
                appState.starsStorePresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text("Купить звёзды")
                }
            }
            .buttonStyle(PlayaPrimaryButton())

            Button {
                settingsPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки аккаунта")
                }
            }
            .buttonStyle(PlayaGhostButton())

            VStack(spacing: 0) {
                if let email = auth.userEmail {
                    SettingsValueInline(title: "Email", value: email)
                    Divider().background(PlayaStyle.hairline).padding(.vertical, 10)
                }
                SettingsValueInline(title: "Режим", value: auth.isLocalAccount ? "Локальный TestFlight" : "Supabase Auth")
            }
            .padding(16)
            .playaPoster()
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.playaDisplay(22, weight: .black))
                .foregroundColor(.white)
                .tracking(-0.5)
            Text(label).playaLabel(color: .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func highlight(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.14), in: Circle())
                .overlay(Circle().stroke(color.opacity(0.32), lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).playaLabel(color: .white.opacity(0.45))
                Text(value)
                    .font(.playaSans(16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .playaPoster()
    }
}

private struct SettingsValueInline: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).playaLabel(color: .white.opacity(0.45))
            Spacer()
            Text(value)
                .font(.playaSans(14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
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
