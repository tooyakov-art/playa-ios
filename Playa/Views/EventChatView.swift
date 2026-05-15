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

    var body: some View {
        VStack(spacing: 0) {
            if messages.isEmpty {
                EmptyStateView(
                    title: "Чат события",
                    message: "Здесь будет разговор участников \(event.title)."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Ink900"))
            } else {
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
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }

            HStack(spacing: 10) {
                TextField(isGuest ? "Войдите, чтобы писать" : "Сообщение в событие", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isGuest)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("Hot"))
                }
                .disabled(isGuest || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.bar)
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshLoop() }
    }

    private func refreshLoop() async {
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
        guard let currentUserId, !isGuest else { return }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
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
