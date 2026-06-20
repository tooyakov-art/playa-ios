import SwiftUI

struct FeedScreen: View {
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var appState: AppState

    @State private var posts: [PlayaPost] = []
    @State private var liveEvents: [PlayaEvent] = []
    @State private var nextPostIndex = 0
    @State private var selectedPost: PlayaPost?
    @State private var selectedEvent: PlayaEvent?
    @State private var isLoading = false
    @State private var feedError: String?
    @State private var selectedCategory: String?
    @State private var categoriesExpanded = false

    private var eventCatalog: [PlayaEvent] {
        appState.createdEvents + (liveEvents.isEmpty ? DemoContent.events : liveEvents)
    }

    private var categoryEvents: [PlayaEvent] {
        guard let selectedCategory else { return eventCatalog }
        let exact = eventCatalog.filter { ($0.category ?? "").localizedCaseInsensitiveContains(selectedCategory) }
        return exact.isEmpty ? eventCatalog : exact
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlayaBackground()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        FeedCategoryBar(
                            selectedCategory: $selectedCategory,
                            isExpanded: $categoriesExpanded
                        )
                        .padding(.top, -2)

                        MovieRail(movies: DemoContent.movies)

                        BannerRail(banners: DemoContent.banners) { banner in
                            if let event = eventCatalog.first(where: { $0.id == banner.eventId }) {
                                selectedEvent = event
                            }
                        }

                        EventRail(events: Array(categoryEvents.prefix(6))) { event in
                            selectedEvent = event
                        }

                        if isLoading && posts.isEmpty {
                            ProgressView()
                                .tint(PlayaStyle.hot)
                                .padding(.vertical, 24)
                        }

                        if let feedError {
                            Text(feedError)
                                .playaCaption()
                                .foregroundColor(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        ForEach(posts) { post in
                            PostCard(
                                post: post,
                                onComments: { selectedPost = post },
                                onReport: { report(post) },
                                onOpenEvent: {
                                    if let eventId = post.eventId,
                                       let event = eventCatalog.first(where: { $0.id == eventId }) {
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
                .refreshable { await reloadFeed(forceDemo: false) }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if posts.isEmpty {
                    await reloadFeed(forceDemo: false)
                }
            }
            .sheet(item: $selectedPost) { post in
                PostCommentsSheet(post: post, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest || auth.isLocalAccount)
            }
            .sheet(item: $selectedEvent) { event in
                NavigationStack {
                    EventDetailSheet(event: event)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Лента")
                Text("·")
                Text("Алматы")
                Spacer()
                Text("Live")
            }
            .playaLabel()

            // «Город *говорит*»
            (
                Text("Город ")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
                +
                Text("говорит")
                    .font(.playaSerif(44))
                    .italic()
                    .foregroundColor(PlayaStyle.hot)
                +
                Text(".")
                    .font(.playaDisplay(40, weight: .black))
                    .foregroundColor(.white)
            )
            .tracking(-0.6)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Text("Фильмы, события и посты от площадок и людей в твоём городе.")
                .playaBody()
                .foregroundColor(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reloadFeed(forceDemo: Bool) async {
        if forceDemo || auth.isLocalAccount || auth.isGuest {
            reloadDemoFeed()
            return
        }

        isLoading = true
        feedError = nil
        defer { isLoading = false }

        async let loadedPosts = SocialService(supabase: auth.supabase).loadPosts()
        async let loadedEvents: Void = loadLiveEvents()

        do {
            let remotePosts = try await loadedPosts
            _ = await loadedEvents
            if remotePosts.isEmpty {
                reloadDemoFeed()
                feedError = "Лента пока пустая, показываем подборку для старта."
            } else {
                posts = remotePosts
                nextPostIndex = remotePosts.count
            }
        } catch {
            _ = await loadedEvents
            reloadDemoFeed()
            feedError = "Связь с сервером нестабильна, показываем сохранённую подборку."
        }
    }

    private func loadLiveEvents() async {
        let service = EventsService(supabase: auth.supabase)
        await service.reload()
        if !service.events.isEmpty {
            liveEvents = service.events
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

    private func report(_ post: PlayaPost) {
        guard let userId = auth.userId, !auth.isLocalAccount, !auth.isGuest else {
            ToastCenter.shared.success("Жалоба сохранена")
            return
        }
        Task {
            do {
                try await SocialService(supabase: auth.supabase).reportContent(reporterId: userId, kind: "post", targetId: post.id)
                ToastCenter.shared.success("Жалоба отправлена")
            } catch {
                ToastCenter.shared.error("Не удалось отправить жалобу")
            }
        }
    }
}

private struct FeedCategory: Identifiable, Hashable {
    let title: String
    let icon: String
    let tint: Color

    var id: String { title }

    static let all: [FeedCategory] = [
        FeedCategory(title: "Кино", icon: "film.fill", tint: PlayaStyle.cyan),
        FeedCategory(title: "Музыка", icon: "music.note", tint: PlayaStyle.hot),
        FeedCategory(title: "Концерт", icon: "sparkles", tint: PlayaStyle.lime),
        FeedCategory(title: "Фестиваль", icon: "party.popper.fill", tint: PlayaStyle.ember),
        FeedCategory(title: "Еда", icon: "fork.knife", tint: PlayaStyle.bone),
        FeedCategory(title: "Gaming", icon: "gamecontroller.fill", tint: PlayaStyle.violet),
        FeedCategory(title: "Business", icon: "briefcase.fill", tint: PlayaStyle.cyan),
        FeedCategory(title: "Travel", icon: "airplane", tint: PlayaStyle.lime)
    ]
}

private struct FeedCategoryBar: View {
    @Binding var selectedCategory: String?
    @Binding var isExpanded: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryButton(title: "Все", icon: "square.grid.2x2.fill", tint: PlayaStyle.hot, isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(FeedCategory.all) { category in
                            categoryButton(
                                title: category.title,
                                icon: category.icon,
                                tint: category.tint,
                                isSelected: selectedCategory == category.title
                            ) {
                                toggle(category.title)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 2)
                }

                Button {
                    PlayaFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .heavy))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(PlayaIconButton(size: 42))
                .padding(.trailing, 16)
            }

            if isExpanded {
                LazyVGrid(columns: columns, spacing: 8) {
                    categoryTile(title: "Все", icon: "square.grid.2x2.fill", tint: PlayaStyle.hot, isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(FeedCategory.all) { category in
                        categoryTile(
                            title: category.title,
                            icon: category.icon,
                            tint: category.tint,
                            isSelected: selectedCategory == category.title
                        ) {
                            toggle(category.title)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func categoryButton(
        title: String,
        icon: String,
        tint: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            PlayaFeedback.selection()
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .lineLimit(1)
            }
            .font(.playaMono(11, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundColor(isSelected ? PlayaStyle.ink900 : .white)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.24) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ title: String) {
        selectedCategory = selectedCategory == title ? nil : title
    }

    private func categoryTile(
        title: String,
        icon: String,
        tint: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            PlayaFeedback.selection()
            action()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                Text(title)
                    .font(.playaMono(10, weight: .bold))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(isSelected ? PlayaStyle.ink900 : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? tint : Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.22 : 0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        .playaPoster()
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title.uppercased())
                .playaLabel(color: .white)
            Spacer()
            Text(subtitle)
                .playaLabel(color: .white.opacity(0.45))
        }
    }
}

/// Legacy entry point for existing call sites — now backed by `CachedAsyncImage`,
/// so every Playa image goes through `ImageCache.shared` automatically.
struct RemoteImage: View {
    let url: URL?

    var body: some View {
        CachedAsyncImage(url: url, contentMode: .fill)
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
            VStack(alignment: .leading, spacing: 18) {
                ZStack(alignment: .topLeading) {
                    RemoteImage(url: event.imageURL)
                        .frame(height: 260)
                        .clipped()
                    LinearGradient(
                        colors: [Color.black.opacity(0.55), .clear, .clear, Color.black.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 260)

                    HStack(spacing: 8) {
                        Text(event.category?.uppercased() ?? "EVENT")
                        Text("·")
                        Text(event.dateText.uppercased())
                    }
                    .playaLabel()
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: PlayaStyle.radiusCard, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text(event.title)
                        .font(.playaDisplay(32, weight: .black))
                        .foregroundColor(.white)
                        .tracking(-0.5)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(event.description ?? "Событие Playa")
                        .playaBody()
                        .foregroundColor(.white.opacity(0.72))

                    metaGrid

                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").foregroundColor(PlayaStyle.lime)
                            Text("Баланс \(appState.starBalance.formatted(.number.grouping(.automatic)))")
                        }
                        .playaLabel(color: .white.opacity(0.88))
                        Spacer()
                        Button("Добавить демо-звёзды") { starsStorePresented = true }
                            .playaLabel(color: PlayaStyle.hot)
                    }
                }
                .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    Button {
                        buyTicket()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: hasTicket ? "checkmark.seal.fill" : "qrcode")
                            Text(ticketButtonTitle)
                        }
                    }
                    .buttonStyle(PlayaPrimaryButton())
                    .disabled(hasTicket)
                    .opacity(hasTicket ? 0.6 : 1)

                    Button {
                        appState.toggleSavedEvent(eventId: event.id)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            Text(isSaved ? "Сохранено" : "Сохранить")
                        }
                    }
                    .buttonStyle(PlayaGhostButton())
                }

                if let ticketMessage {
                    Text(ticketMessage)
                        .playaCaption()
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
        }
        .background(PlayaBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $starsStorePresented) {
            StarsStoreSheet()
        }
    }

    private var metaGrid: some View {
        HStack(spacing: 0) {
            metaCell(label: "Дата", value: event.dateText)
            Divider().background(PlayaStyle.hairline)
            metaCell(label: "Время", value: event.timeText.isEmpty ? "—" : event.timeText)
            Divider().background(PlayaStyle.hairline)
            metaCell(label: "Город", value: event.location ?? "Алматы")
        }
        .frame(height: 64)
        .playaPoster()
    }

    private func metaCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).playaLabel(color: .white.opacity(0.5))
            Text(value)
                .font(.playaSans(15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
    }

    private var ticketButtonTitle: String {
        if hasTicket { return "Демо-билет добавлен" }
        if event.starPrice == 0 { return "Добавить бесплатный демо-билет" }
        return "Добавить демо-билет · \(event.priceText)"
    }

    private func buyTicket() {
        do {
            try appState.buyTicket(event: event)
            ticketMessage = "Демо-билет добавлен. Звёзды списаны из тестового баланса."
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
