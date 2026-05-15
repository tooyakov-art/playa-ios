import SwiftUI

struct EventsScreen: View {
    @EnvironmentObject private var auth: Auth
    @StateObject private var service: EventsService
    @State private var selectedEvent: PlayaEvent?

    init() {
        // EventsService is created here so that it owns its own lifecycle per
        // tab; access token comes from the shared Auth.supabase client.
        _service = StateObject(wrappedValue: EventsService(supabase: SupabaseClient()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                if service.isLoading && service.events.isEmpty {
                    ProgressView().tint(Color("Hot"))
                } else if service.events.isEmpty {
                    EmptyStateView(
                        title: "Скоро появятся события",
                        message: service.lastError ?? "Загляните позже — афиша обновляется каждый день."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(service.events) { event in
                                EventCard(event: event) {
                                    selectedEvent = event
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("События")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await service.reload() }
            .refreshable { await service.reload() }
            .navigationDestination(item: $selectedEvent) { event in
                EventChatView(event: event, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest)
            }
        }
    }
}

struct EventCard: View {
    let event: PlayaEvent
    let onOpenChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: event.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        LinearGradient(
                            colors: [Color("Ink800"), Color("Ink700")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()

                Text(event.priceText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.55), in: Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(event.dateText)
                    if !event.timeText.isEmpty {
                        Text("·").foregroundColor(.white.opacity(0.4))
                        Text(event.timeText)
                    }
                    Spacer()
                    if let category = event.category {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.6)
                            .foregroundColor(Color("Hot"))
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(location).lineLimit(1)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                }

                Button(action: onOpenChat) {
                    Label("Чат события", systemImage: "bubble.left.and.bubble.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("Hot"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 8)
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
