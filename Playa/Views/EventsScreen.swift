import SwiftUI

struct EventsScreen: View {
    @EnvironmentObject private var auth: Auth
    @State private var selectedEvent: PlayaEvent?
    @State private var chatEvent: PlayaEvent?

    private let events = DemoContent.events

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Афиша")
                                .font(.system(size: 30, weight: .black))
                                .foregroundColor(.white)
                            Text("Кино, концерты, бренды и городские встречи.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.58))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        ForEach(events) { event in
                            EventCard(
                                event: event,
                                onOpen: { selectedEvent = event },
                                onOpenChat: { chatEvent = event }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("События")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedEvent) { event in
                NavigationStack { EventDetailSheet(event: event) }
            }
            .sheet(item: $chatEvent) { event in
                NavigationStack {
                    EventChatView(event: event, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest)
                }
            }
        }
    }
}

struct EventCard: View {
    let event: PlayaEvent
    let onOpen: () -> Void
    let onOpenChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                ZStack(alignment: .topTrailing) {
                    RemoteImage(url: event.imageURL)
                        .frame(height: 188)
                        .clipped()

                    Text(event.priceText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.58), in: Capsule())
                        .padding(12)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(event.dateText)
                    if !event.timeText.isEmpty {
                        Text("·").foregroundColor(.white.opacity(0.4))
                        Text(event.timeText)
                    }
                    Spacer()
                    Text((event.category ?? "EVENT").uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color("Hot"))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

                Text(event.title)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(event.description ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .lineLimit(2)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.62))
                }

                HStack(spacing: 10) {
                    Button(action: onOpen) {
                        Label("Билет", systemImage: "qrcode")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color("Hot"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundColor(.white)
                    }

                    Button(action: onOpenChat) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 48, height: 42)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 6)
            }
            .padding(14)
        }
        .background(Color("Ink800"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(Color("Hot"))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
