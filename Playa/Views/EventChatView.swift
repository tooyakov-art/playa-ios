import SwiftUI

struct EventChatView: View {
    @EnvironmentObject private var appState: AppState

    let event: PlayaEvent
    let service: SocialService
    let currentUserId: String?
    let isGuest: Bool

    @State private var messages: [ChatMessage] = []
    @State private var text = ""
    @State private var errorMessage: String?
    @State private var hasJoined = false

    private var isDemoEvent: Bool {
        event.id.hasPrefix("event-") || event.id.hasPrefix("local-event-")
    }

    var body: some View {
        ZStack {
            PlayaBackground()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Чат события").playaLabel()
                    Text(event.title)
                        .font(.playaDisplay(20, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(-0.3)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
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
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    onReport: { reportMessage(message) },
                                    onBlock: { blockUser(message.senderId) }
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
                    TextField("", text: $text, prompt: Text("Сообщение в событие").foregroundColor(.white.opacity(0.4)), axis: .vertical)
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
                    .buttonStyle(SendButtonStyle())
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
        if isDemoEvent {
            messages = DemoContent.eventMessages(for: event).filter { !appState.isBlocked(userId: $0.senderId) }
            return
        }
        await joinIfNeeded()
        await reload()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await reload()
        }
    }

    private func joinIfNeeded() async {
        guard let currentUserId, !isGuest, !hasJoined else { return }
        do {
            try await service.joinEvent(eventId: event.id, userId: currentUserId)
            hasJoined = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() async {
        guard let currentUserId else { return }
        do {
            messages = try await service.loadEventMessages(eventId: event.id, currentUserId: currentUserId)
                .filter { !appState.isBlocked(userId: $0.senderId) }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func send() async {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if isDemoEvent || isGuest {
            messages.append(
                ChatMessage(
                    id: "\(event.id)-local-\(Date().timeIntervalSince1970)",
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

        guard let currentUserId else { return }
        do {
            await joinIfNeeded()
            try await service.sendEventMessage(eventId: event.id, senderId: currentUserId, text: value)
            text = ""
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reportMessage(_ message: ChatMessage) {
        Task {
            guard let reporterId = currentUserId, !isGuest, !isDemoEvent else {
                ToastCenter.shared.success("Жалоба сохранена для модерации")
                return
            }
            do {
                try await service.reportContent(reporterId: reporterId, kind: "event_message", targetId: message.id, reason: "Event chat report")
                ToastCenter.shared.success("Жалоба отправлена")
            } catch {
                ToastCenter.shared.error("Не удалось отправить жалобу")
            }
        }
    }

    private func blockUser(_ userId: String?) {
        guard let userId, !userId.isEmpty else { return }
        appState.blockUser(id: userId)
        messages.removeAll { $0.senderId == userId }
        ToastCenter.shared.success("Пользователь заблокирован")
    }
}

private struct SendButtonStyle: ButtonStyle {
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
