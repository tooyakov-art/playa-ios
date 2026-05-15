import SwiftUI

struct ChatThreadView: View {
    let chat: ChatPreview
    let service: SocialService
    let currentUserId: String
    let isGuest: Bool

    @State private var messages: [ChatMessage] = []
    @State private var text = ""
    @State private var errorMessage: String?

    private var isDemoChat: Bool {
        chat.id.hasPrefix("chat-")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(14)
                }
                .background(Color("Ink900"))
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }

            HStack(spacing: 10) {
                TextField("Сообщение", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("Hot"))
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.bar)
        }
        .navigationTitle(chat.otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshLoop() }
    }

    private func refreshLoop() async {
        if isDemoChat {
            messages = DemoContent.messages(for: chat.id)
            return
        }
        await reload()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await reload(silent: true)
        }
    }

    private func reload(silent: Bool = false) async {
        if isDemoChat {
            messages = DemoContent.messages(for: chat.id)
            return
        }
        do {
            messages = try await service.loadChatMessages(chatId: chat.id, currentUserId: currentUserId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func send() async {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if isDemoChat || isGuest {
            messages.append(
                ChatMessage(
                    id: "\(chat.id)-local-\(Date().timeIntervalSince1970)",
                    sender: .user,
                    text: value,
                    createdAt: Date(),
                    senderName: "Вы",
                    senderAvatarURL: nil
                )
            )
            text = ""
            return
        }

        do {
            try await service.sendDirectMessage(chatId: chat.id, senderId: currentUserId, text: value)
            text = ""
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.sender == .user { Spacer(minLength: 48) }

            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(message.sender == .user ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(message.sender == .user ? Color("Hot") : Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if message.sender == .other { Spacer(minLength: 48) }
        }
    }
}
