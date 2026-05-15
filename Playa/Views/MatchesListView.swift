import SwiftUI

struct MatchesListView: View {
    @EnvironmentObject private var auth: Auth

    @State private var chats: [ChatPreview] = DemoContent.demoChats
    @State private var selectedChat: ChatPreview?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Демо-чаты")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.white)
                            Text("Организаторы, компании и тестовые сообщения уже внутри.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.58))
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Диалоги") {
                        ForEach(chats) { chat in
                            Button {
                                selectedChat = chat
                            } label: {
                                ChatPreviewRow(chat: chat)
                            }
                        }
                    }

                    Section("Аккаунты компаний") {
                        ForEach(DemoContent.companies) { person in
                            Button {
                                selectedChat = ChatPreview(
                                    id: "chat-\(person.id)",
                                    otherUser: person,
                                    lastMessage: "Здравствуйте! Это тестовый диалог Playa.",
                                    lastMessageAt: Date()
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(url: person.avatarURL, fallback: String(person.name.prefix(1)))
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 5) {
                                            Text(person.name)
                                                .font(.system(size: 15, weight: .bold))
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(Color("Cyan"))
                                        }
                                        Text("@\(person.username ?? "playa")")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("Ink900"))
            }
            .navigationTitle("Чаты")
            .sheet(item: $selectedChat) { chat in
                NavigationStack {
                    ChatThreadView(chat: chat, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId ?? "guest", isGuest: auth.isGuest)
                }
            }
        }
    }
}

private struct ChatPreviewRow: View {
    let chat: ChatPreview

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: chat.otherUser.avatarURL, fallback: String(chat.otherUser.name.prefix(1)))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(chat.otherUser.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color("Cyan"))
                }
                Text(chat.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
