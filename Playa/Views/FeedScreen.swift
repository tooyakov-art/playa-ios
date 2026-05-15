import SwiftUI

struct FeedScreen: View {
    @EnvironmentObject private var auth: Auth

    @State private var posts: [PlayaPost] = []
    @State private var nextPostIndex = 0
    @State private var selectedPost: PlayaPost?
    @State private var selectedEvent: PlayaEvent?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        MovieRail(movies: DemoContent.movies)

                        BannerRail(banners: DemoContent.banners) { banner in
                            if let event = DemoContent.events.first(where: { $0.id == banner.eventId }) {
                                selectedEvent = event
                            }
                        }

                        EventRail(events: Array(DemoContent.events.prefix(6))) { event in
                            selectedEvent = event
                        }

                        ForEach(posts) { post in
                            PostCard(
                                post: post,
                                onComments: { selectedPost = post },
                                onReport: {},
                                onOpenEvent: {
                                    if let eventId = post.eventId,
                                       let event = DemoContent.events.first(where: { $0.id == eventId }) {
                                        selectedEvent = event
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .onAppear {
                                if post.id == posts.last?.id {
                                    appendMorePosts()
                                }
                            }
                        }
                    }
                    .padding(.bottom, 96)
                }
                .refreshable { reloadDemoFeed() }
            }
            .navigationTitle("Playa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if posts.isEmpty {
                    reloadDemoFeed()
                }
            }
            .sheet(item: $selectedPost) { post in
                PostCommentsSheet(post: post, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest)
            }
            .sheet(item: $selectedEvent) { event in
                NavigationStack {
                    EventDetailSheet(event: event)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Сегодня в Алматы")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("Hot"))
                Text("Фильмы, события и посты")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)
                Text("Лента рекомендаций от казахстанских компаний и площадок.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.58))
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(Color("Hot"), in: Circle())
        }
    }

    private func reloadDemoFeed() {
        posts = DemoContent.recommendedPosts(count: 30)
        nextPostIndex = posts.count
    }

    private func appendMorePosts() {
        guard posts.count < 180 else { return }
        let newPosts = (nextPostIndex..<(nextPostIndex + 12)).map(DemoContent.recommendedPost(index:))
        posts.append(contentsOf: newPosts)
        nextPostIndex += newPosts.count
    }
}

private struct MovieRail: View {
    let movies: [DemoMovie]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Фильмы сверху", subtitle: "Быстрый выбор на вечер")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movies) { movie in
                        ZStack(alignment: .bottomLeading) {
                            RemoteImage(url: movie.imageURL)
                                .frame(width: 250, height: 146)
                                .clipped()

                            LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(movie.title)
                                    .font(.system(size: 19, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(movie.subtitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.78))
                            }
                            .padding(14)
                        }
                        .frame(width: 250, height: 146)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct BannerRail: View {
    let banners: [DemoBanner]
    let onTap: (DemoBanner) -> Void

    var body: some View {
        TabView {
            ForEach(banners) { banner in
                Button { onTap(banner) } label: {
                    ZStack(alignment: .bottomLeading) {
                        RemoteImage(url: banner.imageURL)
                            .frame(height: 188)
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(banner.title)
                                .font(.system(size: 25, weight: .black))
                                .foregroundColor(.white)
                            Text(banner.subtitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.78))
                                .lineLimit(2)
                            Label("Открыть событие", systemImage: "arrow.up.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color("Hot"), in: Capsule())
                        }
                        .padding(16)
                    }
                }
                .buttonStyle(.plain)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 206)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

private struct EventRail: View {
    let events: [PlayaEvent]
    let onTap: (PlayaEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "События из рекомендаций", subtitle: "Из ленты сразу можно пойти")
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(events) { event in
                        Button { onTap(event) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                RemoteImage(url: event.imageURL)
                                    .frame(width: 178, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(event.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                Text("\(event.dateText) · \(event.priceText)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color("Hot"))
                            }
                            .padding(10)
                            .frame(width: 198, alignment: .leading)
                            .background(Color("Ink800"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct PostCard: View {
    @EnvironmentObject private var appState: AppState

    let post: PlayaPost
    let onComments: () -> Void
    let onReport: () -> Void
    let onOpenEvent: () -> Void

    private var isLiked: Bool {
        appState.isLiked(postId: post.id)
    }

    private var visibleLikes: Int {
        post.likesCount + (isLiked ? 1 : 0)
    }

    private var isEventSaved: Bool {
        guard let eventId = post.eventId else { return false }
        return appState.isEventSaved(eventId: eventId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                AvatarView(url: post.author.avatarURL, fallback: String(post.author.name.prefix(1)))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.author.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color("Cyan"))
                    }
                    Text(post.author.username.map { "@\($0)" } ?? post.createdText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Menu {
                    Button("Пожаловаться", role: .destructive, action: onReport)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                }
            }

            Text(post.text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            RemoteImage(url: post.imageURL)
                .frame(height: 226)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let eventId = post.eventId {
                HStack(spacing: 10) {
                    Button(action: onOpenEvent) {
                        Label("Перейти к мероприятию", systemImage: "ticket.fill")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color("Hot"), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .foregroundColor(.white)
                    }

                    Button {
                        appState.toggleSavedEvent(eventId: eventId)
                    } label: {
                        Image(systemName: isEventSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 46, height: 42)
                            .background(Color.white.opacity(isEventSaved ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .foregroundColor(isEventSaved ? Color("Hot") : .white)
                    }
                }
            }

            HStack(spacing: 18) {
                Button {
                    appState.toggleLike(postId: post.id)
                } label: {
                    Label("\(visibleLikes)", systemImage: isLiked ? "heart.fill" : "heart")
                }
                .foregroundColor(isLiked ? Color("Hot") : .white.opacity(0.65))

                Button(action: onComments) {
                    Label("\(post.commentsCount)", systemImage: "bubble.right")
                }
                Spacer()
                Text(post.createdText)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.65))
        }
        .padding(14)
        .background(Color("Ink800"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
            Spacer()
            Text(subtitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.48))
        }
    }
}

struct RemoteImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                LinearGradient(
                    colors: [Color("Ink800"), Color("Ink700"), Color("HotDeep").opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EventDetailSheet: View {
    @EnvironmentObject private var appState: AppState

    let event: PlayaEvent
    @State private var ticketMessage: String?
    @State private var starsStorePresented = false

    private var isSaved: Bool {
        appState.isEventSaved(eventId: event.id)
    }

    private var hasTicket: Bool {
        appState.hasTicket(eventId: event.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RemoteImage(url: event.imageURL)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(event.category?.uppercased() ?? "EVENT")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color("Hot"))
                    Text(event.title)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                    Text(event.description ?? "Событие Playa")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                    Label("\(event.dateText) \(event.timeText) · \(event.location ?? "Алматы")", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.72))
                    HStack(spacing: 10) {
                        Label("Баланс \(appState.starBalance.formatted(.number.grouping(.automatic)))", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                        Spacer()
                        Button("Купить звёзды") { starsStorePresented = true }
                            .foregroundColor(Color("Hot"))
                    }
                    .font(.system(size: 14, weight: .bold))
                }

                HStack(spacing: 10) {
                    Button {
                        buyTicket()
                    } label: {
                        Label(ticketButtonTitle, systemImage: hasTicket ? "checkmark.seal.fill" : "star.fill")
                            .font(.system(size: 16, weight: .black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(hasTicket ? Color.green.opacity(0.85) : Color("Hot"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundColor(.white)
                    }
                    .disabled(hasTicket)

                    Button {
                        appState.toggleSavedEvent(eventId: event.id)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20, weight: .black))
                            .frame(width: 58, height: 52)
                            .background(Color.white.opacity(isSaved ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundColor(isSaved ? Color("Hot") : .white)
                    }
                }

                if let ticketMessage {
                    Text(ticketMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.68))
                }
            }
            .padding(16)
        }
        .background(Color("Ink900").ignoresSafeArea())
        .navigationTitle("Мероприятие")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $starsStorePresented) {
            StarsStoreSheet()
        }
    }

    private var ticketButtonTitle: String {
        if hasTicket { return "Билет куплен" }
        if event.starPrice == 0 { return "Получить билет бесплатно" }
        return "Купить билет · \(event.priceText)"
    }

    private func buyTicket() {
        do {
            try appState.buyTicket(event: event)
            ticketMessage = "Билет добавлен. Оплата прошла звёздами."
        } catch {
            ticketMessage = error.localizedDescription
            starsStorePresented = true
        }
    }
}

struct AvatarView: View {
    let url: URL?
    let fallback: String

    var body: some View {
        ZStack {
            Circle().fill(
                LinearGradient(colors: [Color("Hot"), Color("Cyan").opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Text(fallback.uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text(fallback.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
    }
}
