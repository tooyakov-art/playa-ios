import SwiftUI

struct EventChatView: View {
    let event: PlayaEvent
    let service: SocialService
    let currentUserId: String?
    let isGuest: Bool

    @State private var messages: [ChatMessage] = []
    @State private var text = ""
    @State private var errorMessage: String?
    @State private var hasJoined = false

    private var isDemoEvent: Bool {
        event.id.hasPrefix("event-")
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
                TextField("Сообщение в событие", text: $text, axis: .vertical)
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
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshLoop() }
    }

    private func refreshLoop() async {
        if isDemoEvent {
            messages = DemoContent.eventMessages(for: event)
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
        try? await service.joinEvent(eventId: event.id, userId: currentUserId)
        hasJoined = true
    }

    private func reload() async {
        guard let currentUserId else { return }
        do {
            messages = try await service.loadEventMessages(eventId: event.id, currentUserId: currentUserId)
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
                    senderAvatarURL: nil
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
}
