import SwiftUI

struct EventsScreen: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState
    @State private var selectedEvent: PlayaEvent?
    @State private var chatEvent: PlayaEvent?
    @State private var liveEvents: [PlayaEvent] = []
    @State private var isLoading = false
    @State private var eventsError: String?

    private var events: [PlayaEvent] {
        appState.createdEvents + (liveEvents.isEmpty ? DemoContent.events : liveEvents)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlayaBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        EventsHeader(count: events.count, isLive: !liveEvents.isEmpty)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        if isLoading && liveEvents.isEmpty {
                            ProgressView()
                                .tint(PlayaStyle.hot)
                                .padding(.vertical, 10)
                        }

                        if let eventsError {
                            Text(eventsError)
                                .playaCaption()
                                .foregroundColor(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        ForEach(events) { event in
                            EventCard(
                                event: event,
                                onOpen: { selectedEvent = event },
                                onOpenChat: { chatEvent = event }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 110)
                }
                .refreshable { await reloadEvents() }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if liveEvents.isEmpty {
                    await reloadEvents()
                }
            }
            .sheet(item: $selectedEvent) { event in
                NavigationStack { EventDetailSheet(event: event) }
            }
            .sheet(item: $chatEvent) { event in
                NavigationStack {
                    EventChatView(event: event, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest || auth.isLocalAccount)
                }
            }
        }
    }

    private func reloadEvents() async {
        guard !auth.isLocalAccount, !auth.isGuest else { return }
        isLoading = true
        eventsError = nil
        defer { isLoading = false }

        let service = EventsService(supabase: auth.supabase)
        await service.reload()
        if !service.events.isEmpty {
            liveEvents = service.events
        } else if let error = service.lastError {
            eventsError = "Связь с сервером нестабильна, показываем сохранённую афишу."
            if !error.isEmpty {
                settingsDebugLog(error)
            }
        }
    }

    private func settingsDebugLog(_ message: String) {
        #if DEBUG
        print("Events reload failed: \(message)")
        #endif
    }
}

// MARK: - Header

private struct EventsHeader: View {
    let count: Int
    let isLive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Афиша")
                Text("·")
                Text(isLive ? "Live" : "Алматы")
                Spacer()
                Text(count.formatted(.number.precision(.integerLength(2))))
            }
            .playaLabel()

            // «Сегодня в *городе*»
            (
                Text("Сегодня\nв ")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
                +
                Text("городе")
                    .font(.playaSerif(44))
                    .italic()
                    .foregroundColor(PlayaStyle.hot)
                +
                Text(".")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
            )
            .tracking(-0.6)
            .lineSpacing(-4)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Event card (poster style)

struct EventCard: View {
    @EnvironmentObject private var appState: AppState

    let event: PlayaEvent
    let onOpen: () -> Void
    let onOpenChat: () -> Void

    private var isSaved: Bool { appState.isEventSaved(eventId: event.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image with mono metadata strip
            Button(action: onOpen) {
                ZStack(alignment: .topLeading) {
                    RemoteImage(url: event.imageURL)
                        .frame(height: 220)
                        .clipped()

                    LinearGradient(
                        colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.45)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 220)

                    HStack(spacing: 8) {
                        Text(event.dateText.uppercased())
                        if !event.timeText.isEmpty {
                            Text("·")
                            Text(event.timeText)
                        }
                        if let location = event.location, !location.isEmpty {
                            Text("·")
                            Text(location.uppercased())
                                .lineLimit(1)
                        }
                    }
                    .playaLabel(color: .white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                }
                .overlay(
                    HStack {
                        Text(event.priceText.uppercased())
                            .playaLabel(color: PlayaStyle.ink900)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous).fill(PlayaStyle.bone)
                            )
                        Spacer()
                        if let category = event.category {
                            Text(category.uppercased())
                                .playaLabel(color: .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous).fill(PlayaStyle.hot)
                                )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12),
                    alignment: .bottom
                )
            }
            .buttonStyle(.plain)

            // Title + description + CTA
            VStack(alignment: .leading, spacing: 12) {
                Text(event.title)
                    .font(.playaDisplay(22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .tracking(-0.3)

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .playaBody()
                        .foregroundColor(.white.opacity(0.68))
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Button(action: onOpen) {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode")
                            Text("Открыть демо-билет")
                        }
                    }
                    .buttonStyle(PlayaPrimaryButton())

                    Button(action: onOpenChat) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                    }
                    .buttonStyle(PlayaIconButton(size: 52))

                    Button {
                        appState.toggleSavedEvent(eventId: event.id)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isSaved ? PlayaStyle.hot : .white)
                    }
                    .buttonStyle(PlayaIconButton(size: 52))
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .playaPoster()
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(PlayaStyle.hot)
            Text(title)
                .playaH3()
            Text(message)
                .playaCaption()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }
}
