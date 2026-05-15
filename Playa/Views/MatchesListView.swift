import SwiftUI

struct MatchesListView: View {
    @EnvironmentObject private var auth: Auth

    @State private var chats: [ChatPreview] = []
    @State private var people: [PlayaProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedChat: ChatPreview?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                if auth.isGuest {
                    EmptyStateView(
                        title: "Чаты после входа",
                        message: "Войдите через Apple, чтобы писать людям и участникам событий."
                    )
                } else if isLoading && chats.isEmpty && people.isEmpty {
                    ProgressView().tint(Color("Hot"))
                } else {
                    List {
                        if !chats.isEmpty {
                            Section("Диалоги") {
                                ForEach(chats) { chat in
                                    Button {
                                        selectedChat = chat
                                    } label: {
                                        ChatPreviewRow(chat: chat)
                                    }
                                }
                            }
                        }

                        if !people.isEmpty {
                            Section("Люди") {
                                ForEach(people) { person in
                                    Button {
                                        Task { await openChat(with: person) }
                                    } label: {
                                        HStack(spacing: 12) {
                                            AvatarView(url: person.avatarURL, fallback: String(person.name.prefix(1)))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(person.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                if let username = person.username {
                                                    Text("@\(username)")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if let errorMessage {
                            Section {
                                Text(errorMessage).foregroundColor(.red)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color("Ink900"))
                    .refreshable { await reload() }
                }
            }
            .navigationTitle("Чаты")
            .task { await reload() }
            .sheet(item: $selectedChat) { chat in
                NavigationStack {
                    ChatThreadView(chat: chat, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId ?? "", isGuest: auth.isGuest)
                }
            }
        }
    }

    private func reload() async {
        guard let userId = auth.userId, !auth.isGuest else { return }
        isLoading = true
        do {
            let service = SocialService(supabase: auth.supabase)
            chats = try await service.loadDirectChats(currentUserId: userId)
            people = try await service.loadProfiles(excluding: userId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func openChat(with person: PlayaProfile) async {
        guard let userId = auth.userId, !auth.isGuest else { return }
        do {
            let service = SocialService(supabase: auth.supabase)
            guard let chatId = try await service.openOrCreateDirectChat(userId: userId, otherUserId: person.id) else { return }
            selectedChat = ChatPreview(id: chatId, otherUser: person, lastMessage: nil, lastMessageAt: nil)
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ChatPreviewRow: View {
    let chat: ChatPreview

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: chat.otherUser.avatarURL, fallback: String(chat.otherUser.name.prefix(1)))
            VStack(alignment: .leading, spacing: 3) {
                Text(chat.otherUser.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(chat.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
