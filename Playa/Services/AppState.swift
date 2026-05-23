import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable {
        case feed
        case events
        case matches
        case profile
    }

    @Published var selectedTab: Tab = .feed
    @Published var createEventPresented: Bool = false
    @Published var starsStorePresented: Bool = false
    @Published private(set) var likedPostIds: Set<String> = []
    @Published private(set) var savedEventIds: Set<String> = []
    @Published private(set) var purchasedTicketEventIds: Set<String> = []
    @Published private(set) var starBalance: Int = 0
    @Published private(set) var createdEvents: [PlayaEvent] = []

    private let defaults: UserDefaults
    private let likedPostsKey = "playa.posts.liked_ids"
    private let savedEventsKey = "playa.events.saved_ids"
    private let createdEventsKey = "playa.events.created"
    private let starBalanceKey = "playa.stars.balance"
    private let ticketsKey = "playa.tickets.purchased_event_ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        likedPostIds = Self.loadStringSet(defaults: defaults, key: likedPostsKey)
        savedEventIds = Self.loadStringSet(defaults: defaults, key: savedEventsKey)
        createdEvents = Self.loadEvents(defaults: defaults, key: createdEventsKey)
        starBalance = defaults.integer(forKey: starBalanceKey)
        purchasedTicketEventIds = Self.loadStringSet(defaults: defaults, key: ticketsKey)
    }

    func toggleLike(postId: String) {
        if likedPostIds.contains(postId) {
            likedPostIds.remove(postId)
        } else {
            likedPostIds.insert(postId)
        }
        Self.saveStringSet(likedPostIds, defaults: defaults, key: likedPostsKey)
    }

    func toggleSavedEvent(eventId: String) {
        if savedEventIds.contains(eventId) {
            savedEventIds.remove(eventId)
        } else {
            savedEventIds.insert(eventId)
        }
        Self.saveStringSet(savedEventIds, defaults: defaults, key: savedEventsKey)
    }

    func isLiked(postId: String) -> Bool {
        likedPostIds.contains(postId)
    }

    func createLocalEvent(title: String, location: String, category: String, starPrice: Int) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let calendar = Calendar.current
        let tomorrow = Date().addingTimeInterval(86_400)
        let startsAt = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let event = PlayaEvent(
            id: "local-event-\(UUID().uuidString)",
            title: trimmedTitle,
            description: "Черновик события. Его можно показать в афише и доработать перед публикацией.",
            category: category,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Алматы" : location,
            imageURL: nil,
            startsAt: startsAt,
            priceValue: max(0, starPrice) * 100
        )
        createdEvents.insert(event, at: 0)
        Self.saveEvents(createdEvents, defaults: defaults, key: createdEventsKey)
    }

    func isEventSaved(eventId: String) -> Bool {
        savedEventIds.contains(eventId)
    }

    func buyStars(package: StarPackage) {
        starBalance += package.stars
        defaults.set(starBalance, forKey: starBalanceKey)
    }

    func buyTicket(event: PlayaEvent) throws {
        let cost = event.starPrice
        guard !purchasedTicketEventIds.contains(event.id) else { return }
        guard starBalance >= cost else { throw StarPurchaseError.insufficientStars(required: cost, balance: starBalance) }
        starBalance -= cost
        purchasedTicketEventIds.insert(event.id)
        defaults.set(starBalance, forKey: starBalanceKey)
        Self.saveStringSet(purchasedTicketEventIds, defaults: defaults, key: ticketsKey)
    }

    func hasTicket(eventId: String) -> Bool {
        purchasedTicketEventIds.contains(eventId)
    }

    private static func loadStringSet(defaults: UserDefaults, key: String) -> Set<String> {
        guard let data = defaults.data(forKey: key),
              let values = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return Set(values)
    }

    private static func saveStringSet(_ set: Set<String>, defaults: UserDefaults, key: String) {
        guard let data = try? JSONEncoder().encode(Array(set).sorted()) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadEvents(defaults: UserDefaults, key: String) -> [PlayaEvent] {
        guard let data = defaults.data(forKey: key),
              let values = try? JSONDecoder().decode([PlayaEvent].self, from: data)
        else {
            return []
        }
        return values
    }

    private static func saveEvents(_ events: [PlayaEvent], defaults: UserDefaults, key: String) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: key)
    }
}

struct StarPackage: Identifiable, Hashable {
    let stars: Int
    let priceText: String

    var id: Int { stars }

    static let telegramStyle: [StarPackage] = [
        StarPackage(stars: 100, priceText: "₸1 190,00"),
        StarPackage(stars: 250, priceText: "₸2 900,00"),
        StarPackage(stars: 500, priceText: "₸5 890,00"),
        StarPackage(stars: 1_000, priceText: "₸11 790,00"),
        StarPackage(stars: 2_500, priceText: "₸29 000,00"),
        StarPackage(stars: 10_000, priceText: "₸117 990,00"),
        StarPackage(stars: 35_000, priceText: "₸414 990,00")
    ]
}

enum StarPurchaseError: LocalizedError {
    case insufficientStars(required: Int, balance: Int)

    var errorDescription: String? {
        switch self {
        case .insufficientStars(let required, let balance):
            return "Нужно \(required) звёзд, на балансе \(balance)."
        }
    }
}
