import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject private var appState: AppState

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
        ZStack {
            PlayaBackground()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    AvatarView(url: chat.otherUser.avatarURL, fallback: String(chat.otherUser.name.prefix(1)))
                        .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(chat.otherUser.name)
                                .font(.playaSans(15, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(PlayaStyle.cyan)
                        }
                        Text("@\(chat.otherUser.username ?? "playa")")
                            .playaLabel(color: .white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(PlayaStyle.ink900.opacity(0.6))
                        .background(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(PlayaStyle.hairline),
                            alignment: .bottom
                        )
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    onReport: { reportMessage(message) },
                                    onBlock: { blockUser(message.senderId ?? chat.otherUser.id) }
                                )
                                    .id(message.id)
                            }
                        }
                        .padding(14)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .playaCaption()
                        .foregroundColor(PlayaStyle.hot)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 4)
                }

                HStack(spacing: 10) {
                    TextField("", text: $text, prompt: Text("Сообщение").foregroundColor(.white.opacity(0.4)), axis: .vertical)
                        .font(.playaSans(15, weight: .regular))
                        .foregroundColor(.white)
                        .tint(PlayaStyle.hot)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    .buttonStyle(ChatSendButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(PlayaStyle.ink900.opacity(0.7))
                        .background(.ultraThinMaterial)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await refreshLoop() }
    }

    private func refreshLoop() async {
        if isDemoChat {
            messages = DemoContent.messages(for: chat.id).filter { !appState.isBlocked(userId: $0.senderId) }
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
            messages = DemoContent.messages(for: chat.id).filter { !appState.isBlocked(userId: $0.senderId) }
            return
        }
        do {
            messages = try await service.loadChatMessages(chatId: chat.id, currentUserId: currentUserId)
                .filter { !appState.isBlocked(userId: $0.senderId) }
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
                    senderAvatarURL: nil,
                    senderId: currentUserId
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

    private func reportMessage(_ message: ChatMessage) {
        Task {
            if isDemoChat || isGuest {
                ToastCenter.shared.success("Жалоба сохранена для модерации")
                return
            }
            do {
                try await service.reportContent(reporterId: currentUserId, kind: "message", targetId: message.id, reason: "Direct chat report")
                ToastCenter.shared.success("Жалоба отправлена")
            } catch {
                ToastCenter.shared.error("Не удалось отправить жалобу")
            }
        }
    }

    private func blockUser(_ userId: String) {
        appState.blockUser(id: userId)
        messages.removeAll { $0.senderId == userId }
        ToastCenter.shared.success("Пользователь заблокирован")
    }
}

// MARK: - Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?

    private var isMine: Bool { message.sender == .user }
    private var canModerate: Bool { !isMine && (onReport != nil || onBlock != nil) }

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 48) }

            Text(message.text)
                .font(.playaSans(15, weight: .regular))
                .foregroundColor(isMine ? .white : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    bubbleShape
                        .fill(isMine ? PlayaStyle.hot : Color.white.opacity(0.08))
                )
                .overlay(
                    bubbleShape.stroke(
                        isMine ? Color.white.opacity(0.12) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
                )

            if canModerate {
                Menu {
                    Button("Пожаловаться", systemImage: "exclamationmark.bubble") {
                        onReport?()
                    }
                    Button("Заблокировать пользователя", systemImage: "hand.raised.fill", role: .destructive) {
                        onBlock?()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                }
            }

            if !isMine { Spacer(minLength: 48) }
        }
    }

    /// Asymmetric corner: rounded on three corners (16pt), sharp 3pt on the side
    /// that points to the speaker. Matches the web POSTER v2 chat bubble.
    private var bubbleShape: UnevenRoundedRectangle {
        if isMine {
            return UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 16, bottomLeading: 16, bottomTrailing: 3, topTrailing: 16),
                style: .continuous
            )
        } else {
            return UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 16, bottomLeading: 3, bottomTrailing: 16, topTrailing: 16),
                style: .continuous
            )
        }
    }
}

private struct ChatSendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy))
            .foregroundColor(.white)
            .frame(width: 46, height: 46)
            .background(
                Circle()
                    .fill(PlayaStyle.hot)
                    .shadow(color: PlayaStyle.hot.opacity(0.34), radius: 12, x: 0, y: 6)
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
