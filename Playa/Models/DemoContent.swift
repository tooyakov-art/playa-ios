import Foundation

struct DemoMovie: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}

struct DemoBanner: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    let eventId: String?
}

enum DemoContent {
    static let companies: [PlayaProfile] = [
        profile("kaspi", "Kaspi.kz", "kaspi.kz"),
        profile("halyk", "Halyk Bank", "halykbank"),
        profile("airastana", "Air Astana", "airastana"),
        profile("ticketon", "Ticketon", "ticketon.kz"),
        profile("kinopark", "Kinopark Theatres", "kinopark"),
        profile("magnum", "Magnum", "magnumclub"),
        profile("technodom", "Technodom", "technodom"),
        profile("sulpak", "Sulpak", "sulpak"),
        profile("chocofamily", "ChocoFamily", "chocofamily"),
        profile("kolesa", "Kolesa Group", "kolesagroup"),
        profile("krisha", "Krisha.kz", "krisha.kz"),
        profile("meloman", "Meloman", "meloman.kz"),
        profile("fora", "ForteBank", "fortebank"),
        profile("arbuz", "Arbuz.kz", "arbuz.kz"),
        profile("aviata", "Aviata", "aviata.kz")
    ]

    static let movies: [DemoMovie] = [
        DemoMovie(id: "movie-dune", title: "Dune: Part Two", subtitle: "IMAX сегодня вечером", imageURL: image("photo-1500530855697-b586d89ba3ee")),
        DemoMovie(id: "movie-inside", title: "Inside Out 2", subtitle: "Семейный сеанс в Kinopark", imageURL: image("photo-1489599849927-2ee91cede3ba")),
        DemoMovie(id: "movie-nomad", title: "Nomad Stories", subtitle: "Казахстанская премьера", imageURL: image("photo-1524985069026-dd778a71c7b4")),
        DemoMovie(id: "movie-jazz", title: "Jazz Night Cinema", subtitle: "Фильм + live band", imageURL: image("photo-1497032628192-86f99bcd76bc"))
    ]

    static let banners: [DemoBanner] = [
        DemoBanner(id: "banner-air", title: "Air Astana Weekend", subtitle: "Розыгрыш билетов и travel-talk в Esentai", imageURL: image("photo-1436491865332-7a61a109cc05"), eventId: "event-air-weekend"),
        DemoBanner(id: "banner-kaspi", title: "Kaspi City Day", subtitle: "Маркет, музыка и полезные сервисы города", imageURL: image("photo-1514525253161-7a46d19cd819"), eventId: "event-kaspi-city"),
        DemoBanner(id: "banner-kino", title: "Kinopark Premiere", subtitle: "Ночная премьера, попкорн и afterparty", imageURL: image("photo-1489599849927-2ee91cede3ba"), eventId: "event-kino-premiere")
    ]

    static let events: [PlayaEvent] = [
        event("event-kaspi-city", "Kaspi City Day", "Маркет, музыка и городские сервисы", "Фестиваль", "Almaty Arena", "photo-1514525253161-7a46d19cd819", 0, 1, 19),
        event("event-air-weekend", "Air Astana Weekend", "Travel-talk, розыгрыши и networking", "Travel", "Esentai Mall", "photo-1436491865332-7a61a109cc05", 5000, 2, 18),
        event("event-kino-premiere", "Kinopark Premiere Night", "Премьера, гости и закрытый показ", "Кино", "Kinopark 11 IMAX", "photo-1489599849927-2ee91cede3ba", 3500, 0, 22),
        event("event-ticketon-live", "Ticketon Live: Q-pop Night", "Сцена молодых артистов Казахстана", "Концерт", "Republic Palace", "photo-1501386761578-eac5c94b800a", 7000, 4, 20),
        event("event-magnum-food", "Magnum Food Fest", "Еда, дегустации и семейный weekend", "Food", "Mega Alma-Ata", "photo-1555939594-58d7cb561ad1", 0, 5, 12),
        event("event-technodom", "Technodom Gaming Cup", "Турнир, консоли и призы", "Gaming", "Dostyk Plaza", "photo-1542751371-adc38448a05e", 2500, 3, 16),
        event("event-choco", "ChocoFamily Picnic", "Летний пикник для друзей", "Lifestyle", "Central Park", "photo-1492684223066-81342ee5ff30", 0, 6, 15),
        event("event-forte", "Forte Jazz Rooftop", "Живой джаз на крыше", "Музыка", "The Ritz-Carlton", "photo-1506157786151-b8491531f063", 9000, 7, 21),
        event("event-kolesa", "Kolesa Auto Meet", "Тест-драйвы и комьюнити", "Auto", "Sokol Track", "photo-1503376780353-7e6692767b70", 3000, 8, 11),
        event("event-meloman", "Meloman Book & Vinyl Day", "Книги, винил и авторские встречи", "Culture", "Forum Almaty", "photo-1513475382585-d06e58bcb0e0", 0, 9, 14)
    ]

    static let demoChats: [ChatPreview] = [
        ChatPreview(id: "chat-ticketon", otherUser: companies[3], lastMessage: "Ваши билеты на Q-pop Night готовы.", lastMessageAt: Date().addingTimeInterval(-900)),
        ChatPreview(id: "chat-kinopark", otherUser: companies[4], lastMessage: "Премьера начнется в 22:00. Бронь держим.", lastMessageAt: Date().addingTimeInterval(-3_600)),
        ChatPreview(id: "chat-kaspi", otherUser: companies[0], lastMessage: "Добавили карту площадки и расписание.", lastMessageAt: Date().addingTimeInterval(-7_200)),
        ChatPreview(id: "chat-air", otherUser: companies[2], lastMessage: "Регистрация на travel-talk открыта.", lastMessageAt: Date().addingTimeInterval(-10_800))
    ]

    static func messages(for chatId: String) -> [ChatMessage] {
        let profile = demoChats.first(where: { $0.id == chatId })?.otherUser ?? companies[0]
        return [
            ChatMessage(id: "\(chatId)-1", sender: .other, text: "Привет! Это демо-чат Playa. Здесь будет живая переписка с организатором.", createdAt: Date().addingTimeInterval(-3_600), senderName: profile.name, senderAvatarURL: profile.avatarURL),
            ChatMessage(id: "\(chatId)-2", sender: .user, text: "Отлично. Можно узнать детали события?", createdAt: Date().addingTimeInterval(-2_900), senderName: "Вы", senderAvatarURL: nil),
            ChatMessage(id: "\(chatId)-3", sender: .other, text: "Да. В ленте нажимаете на карточку события, покупаете билет и получаете QR.", createdAt: Date().addingTimeInterval(-2_200), senderName: profile.name, senderAvatarURL: profile.avatarURL),
            ChatMessage(id: "\(chatId)-4", sender: .other, text: "Для TestFlight сделали демо-сообщения, чтобы экран не был пустым.", createdAt: Date().addingTimeInterval(-900), senderName: profile.name, senderAvatarURL: profile.avatarURL)
        ]
    }

    static func eventMessages(for event: PlayaEvent) -> [ChatMessage] {
        [
            ChatMessage(id: "\(event.id)-event-1", sender: .other, text: "Добро пожаловать в чат события \(event.title).", createdAt: Date().addingTimeInterval(-4_000), senderName: "Playa", senderAvatarURL: nil),
            ChatMessage(id: "\(event.id)-event-2", sender: .other, text: "Организатор уже добавил тайминг, билеты и место встречи.", createdAt: Date().addingTimeInterval(-2_000), senderName: event.title, senderAvatarURL: nil),
            ChatMessage(id: "\(event.id)-event-3", sender: .user, text: "Супер, я приду.", createdAt: Date().addingTimeInterval(-1_000), senderName: "Вы", senderAvatarURL: nil)
        ]
    }

    static func comments(for post: PlayaPost) -> [PostComment] {
        let first = companies[(abs(post.id.hashValue) + 1) % companies.count]
        let second = companies[(abs(post.id.hashValue) + 5) % companies.count]
        return [
            PostComment(id: "\(post.id)-comment-1", postId: post.id, authorId: first.id, text: "Выглядит интересно. Добавили в планы на вечер.", createdAt: Date().addingTimeInterval(-1_800), author: first),
            PostComment(id: "\(post.id)-comment-2", postId: post.id, authorId: second.id, text: "Playa хорошо показывает такие события в рекомендациях.", createdAt: Date().addingTimeInterval(-900), author: second)
        ]
    }

    static func recommendedPost(index: Int) -> PlayaPost {
        let company = companies[index % companies.count]
        let event = events[index % events.count]
        let hooks = [
            "Сегодня в Алматы",
            "Рекомендация для выходных",
            "Новый формат встречи",
            "Проверено командой Playa",
            "Лучшее рядом с вами",
            "Для тех, кто не хочет сидеть дома",
            "Городская афиша недели",
            "Место, куда стоит позвать друзей"
        ]
        let details = [
            "\(event.title): \(event.description ?? "событие для города"). Лента подбирает это по вашим интересам.",
            "Запустили демо-акцию для гостей Playa. Можно перейти из поста прямо в событие и забронировать место.",
            "Будет музыка, люди, QR-билеты и быстрый чат с организатором. Добавили это в рекомендации.",
            "Партнерский пост для афиши. Сохраняйте, если хотите увидеть больше похожих мероприятий.",
            "Собрали программу на вечер: фильм, встреча и afterparty. Playa покажет похожие события ниже.",
            "Новая точка на карте города. Внутри есть чат, билеты и детали по времени.",
            "Демо-публикация от аккаунта компании. Так будет выглядеть промо в живой ленте.",
            "Коротко: \(event.location ?? "Алматы"), \(event.dateText), вход \(event.priceText.lowercased())."
        ]
        let imageIds = [
            "photo-1514525253161-7a46d19cd819",
            "photo-1489599849927-2ee91cede3ba",
            "photo-1501386761578-eac5c94b800a",
            "photo-1555939594-58d7cb561ad1",
            "photo-1542751371-adc38448a05e",
            "photo-1492684223066-81342ee5ff30",
            "photo-1506157786151-b8491531f063",
            "photo-1503376780353-7e6692767b70",
            "photo-1513475382585-d06e58bcb0e0",
            "photo-1524985069026-dd778a71c7b4"
        ]
        let text = "\(hooks[index % hooks.count]). \(details[(index / 2) % details.count])"
        return PlayaPost(
            id: "demo-post-\(index)",
            authorId: company.id,
            text: text,
            imageURL: image(imageIds[index % imageIds.count]),
            likesCount: 80 + ((index * 37) % 2_400),
            commentsCount: 4 + ((index * 11) % 180),
            eventId: index % 3 == 0 ? event.id : nil,
            createdAt: Date().addingTimeInterval(TimeInterval(-index * 1_800)),
            author: company
        )
    }

    static func recommendedPosts(count: Int = 100) -> [PlayaPost] {
        (0..<count).map(recommendedPost(index:))
    }

    private static func profile(_ id: String, _ name: String, _ username: String) -> PlayaProfile {
        PlayaProfile(id: "demo-\(id)", name: name, username: username, avatarURL: nil)
    }

    private static func event(_ id: String, _ title: String, _ description: String, _ category: String, _ location: String, _ imageId: String, _ price: Int, _ days: Int, _ hour: Int) -> PlayaEvent {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date().addingTimeInterval(TimeInterval(days * 86_400)))
        return PlayaEvent(id: id, title: title, description: description, category: category, location: location, imageURL: image(imageId), startsAt: start, priceValue: price)
    }

    private static func image(_ id: String) -> URL? {
        URL(string: "https://images.unsplash.com/\(id)?auto=format&fit=crop&w=1200&q=80")
    }
}
