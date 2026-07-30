import SwiftUI

struct MatchesListView: View {
    @EnvironmentObject private var auth: Auth

    @State private var chats: [ChatPreview] = DemoContent.demoChats
    @State private var selectedChat: ChatPreview?
    @State private var isLoading = false
    @State private var chatError: String?
    @State private var filter: ChatFilter = .messages

    var body: some View {
        NavigationStack {
            ZStack {
                PlayaBackground()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Picker("Раздел чатов", selection: $filter) {
                            ForEach(ChatFilter.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .accessibilityLabel("Выбрать диалоги или бренды")

                        if isLoading && filter == .messages {
                            ProgressView("Обновляем диалоги")
                                .tint(PlayaStyle.hot)
                                .foregroundColor(.white.opacity(0.65))
                                .padding(.vertical, 10)
                        }

                        if let chatError, filter == .messages {
                            VStack(spacing: 10) {
                                Text(chatError)
                                    .playaCaption()
                                    .foregroundColor(.white.opacity(0.58))
                                    .multilineTextAlignment(.center)
                                Button {
                                    Task { await reloadChats() }
                                } label: {
                                    Label("Повторить", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(PlayaGhostButton())
                            }
                            .padding(.horizontal, 20)
                        }

                        content
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)
                }
                .refreshable {
                    if filter == .messages {
                        await reloadChats()
                    }
                }
            }
            .navigationBarHidden(true)
            .task { await reloadChats() }
            .sheet(item: $selectedChat) { chat in
                NavigationStack {
                    ChatThreadView(
                        chat: chat,
                        service: SocialService(supabase: auth.supabase),
                        currentUserId: auth.userId ?? "guest",
                        isGuest: auth.isDemoMode
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch filter {
        case .messages:
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Личные диалоги", count: chats.count)
                if chats.isEmpty && !isLoading {
                    EmptyStateView(
                        title: "Диалогов пока нет",
                        message: "Когда ты напишешь организатору или участнику, беседа появится здесь."
                    )
                    .playaPoster()
                } else {
                    VStack(spacing: 8) {
                        ForEach(chats) { chat in
                            Button { selectedChat = chat } label: {
                                ChatPreviewRow(chat: chat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        case .brands:
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Площадки и организаторы", count: DemoContent.companies.count)
                VStack(spacing: 8) {
                    ForEach(DemoContent.companies) { person in
                        Button {
                            selectedChat = ChatPreview(
                                id: "chat-\(person.id)",
                                otherUser: person,
                                lastMessage: "Откройте диалог, чтобы задать вопрос организатору.",
                                lastMessageAt: Date()
                            )
                        } label: {
                            CompanyRow(person: person)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func reloadChats() async {
        guard !auth.isDemoMode, let userId = auth.userId else {
            chats = DemoContent.demoChats
            return
        }

        isLoading = true
        chatError = nil
        defer { isLoading = false }

        do {
            let liveChats = try await SocialService(supabase: auth.supabase).loadDirectChats(currentUserId: userId)
            chats = liveChats
            if liveChats.isEmpty {
                chatError = nil
            }
        } catch {
            chats = DemoContent.demoChats
            chatError = "Сервер не ответил. Показываем сохранённые демо-диалоги."
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Чаты")
                Text("·")
                Text(filter == .messages ? "\(chats.count) диалогов" : "\(DemoContent.companies.count) брендов")
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

            Text("Личные беседы и страницы организаторов теперь разделены.")
                .playaBody()
                .foregroundColor(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionLabel(_ text: String, count: Int) -> some View {
        HStack {
            Text(text).playaLabel()
            Spacer()
            Text("\(count)")
                .playaLabel(color: .white.opacity(0.42))
        }
    }
}

private enum ChatFilter: String, CaseIterable, Identifiable {
    case messages
    case brands

    var id: String { rawValue }

    var title: String {
        switch self {
        case .messages: return "Диалоги"
        case .brands: return "Бренды"
        }
    }
}

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
            Text("ОРГАНИЗАТОР")
                .playaLabel(color: .white.opacity(0.38))
                .minimumScaleFactor(0.7)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .playaPoster()
    }
}
