import SwiftUI

struct MatchesListView: View {
    @EnvironmentObject private var auth: Auth

    @State private var chats: [ChatPreview] = DemoContent.demoChats
    @State private var selectedChat: ChatPreview?
    @State private var isLoading = false
    @State private var chatError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PlayaBackground()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 14)

                        sectionLabel("Диалоги")
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if isLoading {
                            ProgressView()
                                .tint(PlayaStyle.hot)
                                .padding(.vertical, 14)
                        }

                        if let chatError {
                            Text(chatError)
                                .playaCaption()
                                .foregroundColor(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                        }

                        VStack(spacing: 8) {
                            ForEach(chats) { chat in
                                Button { selectedChat = chat } label: {
                                    ChatPreviewRow(chat: chat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        sectionLabel("Бренды и компании")
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        VStack(spacing: 8) {
                            ForEach(DemoContent.companies) { person in
                                Button {
                                    selectedChat = ChatPreview(
                                        id: "chat-\(person.id)",
                                        otherUser: person,
                                        lastMessage: "Здравствуйте! Это тестовый диалог Playa.",
                                        lastMessageAt: Date()
                                    )
                                } label: {
                                    CompanyRow(person: person)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 110)
                }
                .refreshable { await reloadChats() }
            }
            .navigationBarHidden(true)
            .task {
                await reloadChats()
            }
            .sheet(item: $selectedChat) { chat in
                NavigationStack {
                    ChatThreadView(
                        chat: chat,
                        service: SocialService(supabase: auth.supabase),
                        currentUserId: auth.userId ?? "guest",
                        isGuest: auth.isGuest || auth.isLocalAccount
                    )
                }
            }
        }
    }

    private func reloadChats() async {
        guard let userId = auth.userId, !auth.isLocalAccount, !auth.isGuest else {
            chats = DemoContent.demoChats
            return
        }

        isLoading = true
        chatError = nil
        defer { isLoading = false }

        do {
            let liveChats = try await SocialService(supabase: auth.supabase).loadDirectChats(currentUserId: userId)
            chats = liveChats.isEmpty ? DemoContent.demoChats : liveChats
            if liveChats.isEmpty {
                chatError = "Диалогов пока нет, показываем полезные контакты."
            }
        } catch {
            chats = DemoContent.demoChats
            chatError = "Связь с сервером нестабильна, показываем сохранённые диалоги."
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Чаты")
                Text("·")
                Text("\(chats.count + DemoContent.companies.count) активно")
            }
            .playaLabel()

            (
                Text("Город ")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
                +
                Text("на связи")
                    .font(.playaSerif(44))
                    .italic()
                    .foregroundColor(PlayaStyle.hot)
                +
                Text(".")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
            )
            .tracking(-0.6)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text).playaLabel()
            Spacer()
        }
    }
}

// MARK: - Rows

private struct ChatPreviewRow: View {
    let chat: ChatPreview

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: chat.otherUser.avatarURL, fallback: String(chat.otherUser.name.prefix(1)))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(chat.otherUser.name)
                        .font(.playaSans(15, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PlayaStyle.cyan)
                }
                Text(chat.subtitle)
                    .playaCaption()
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .playaPoster()
    }
}

private struct CompanyRow: View {
    let person: PlayaProfile

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: person.avatarURL, fallback: String(person.name.prefix(1)))
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.playaSans(15, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PlayaStyle.cyan)
                }
                Text("@\(person.username ?? "playa")")
                    .playaLabel(color: .white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .playaPoster()
    }
}
