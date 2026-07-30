import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable {
        case feed
        case events
        case create
        case matches
        case profile
    }

    @Published var selectedTab: Tab = .feed
    @Published var createEventPresented: Bool = false
    @Published var starsStorePresented: Bool = false
    @Published private(set) var likedPostIds: Set<String> = []
    @Published private(set) var savedEventIds: Set<String> = []
    @Published private(set) var interestedEventIds: Set<String> = []
    @Published private(set) var goingEventIds: Set<String> = []
    @Published private(set) var purchasedTicketEventIds: Set<String> = []
    @Published private(set) var starBalance: Int = 0
    @Published private(set) var createdEvents: [PlayaEvent] = []
    @Published private(set) var blockedUserIds: Set<String> = []

    private let defaults: UserDefaults
    private let likedPostsKey = "playa.posts.liked_ids"
    private let savedEventsKey = "playa.events.saved_ids"
    private let interestedEventsKey = "playa.events.interested_ids"
    private let goingEventsKey = "playa.events.going_ids"
    private let createdEventsKey = "playa.events.created"
    private let starBalanceKey = "playa.stars.balance"
    private let ticketsKey = "playa.tickets.purchased_event_ids"
    private let blockedUsersKey = "playa.safety.blocked_user_ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        likedPostIds = Self.loadStringSet(defaults: defaults, key: likedPostsKey)
        savedEventIds = Self.loadStringSet(defaults: defaults, key: savedEventsKey)
        interestedEventIds = Self.loadStringSet(defaults: defaults, key: interestedEventsKey)
        goingEventIds = Self.loadStringSet(defaults: defaults, key: goingEventsKey)
        createdEvents = Self.loadEvents(defaults: defaults, key: createdEventsKey)
        starBalance = defaults.integer(forKey: starBalanceKey)
        purchasedTicketEventIds = Self.loadStringSet(defaults: defaults, key: ticketsKey)
        blockedUserIds = Self.loadStringSet(defaults: defaults, key: blockedUsersKey)
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

    func toggleInterested(eventId: String) {
        if interestedEventIds.contains(eventId) {
            interestedEventIds.remove(eventId)
            goingEventIds.remove(eventId)
        } else {
            interestedEventIds.insert(eventId)
        }
        persistEventDecisions()
    }

    func markGoing(eventId: String) {
        interestedEventIds.insert(eventId)
        goingEventIds.insert(eventId)
        persistEventDecisions()
    }

    func isInterested(eventId: String) -> Bool {
        interestedEventIds.contains(eventId)
    }

    func isGoing(eventId: String) -> Bool {
        goingEventIds.contains(eventId)
    }

    func isLiked(postId: String) -> Bool {
        likedPostIds.contains(postId)
    }

    func createLocalEvent(
        title: String,
        description: String,
        location: String,
        category: String,
        startsAt: Date,
        starPrice: Int,
        capacity: Int
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let capacityText = capacity > 0 ? "Вместимость: \(capacity)." : ""
        let detail = [trimmedDescription, capacityText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let draftDescription = detail.isEmpty
            ? "Черновик. Добавьте описание перед публикацией."
            : "Черновик • \(detail)"

        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = PlayaEvent(
            id: "local-event-\(UUID().uuidString)",
            title: trimmedTitle,
            description: draftDescription,
            category: category,
            location: trimmedLocation.isEmpty ? "Алматы · площадка не указана" : trimmedLocation,
            imageURL: nil,
            startsAt: startsAt,
            priceValue: max(0, starPrice) * 100
        )
        createdEvents.insert(event, at: 0)
        Self.saveEvents(createdEvents, defaults: defaults, key: createdEventsKey)
    }

    // Compatibility entry point for older call sites.
    func createLocalEvent(title: String, location: String, category: String, starPrice: Int) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        let startsAt = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        createLocalEvent(
            title: title,
            description: "",
            location: location,
            category: category,
            startsAt: startsAt,
            starPrice: starPrice,
            capacity: 0
        )
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
        guard starBalance >= cost else {
            throw StarPurchaseError.insufficientStars(required: cost, balance: starBalance)
        }
        starBalance -= cost
        interestedEventIds.insert(event.id)
        goingEventIds.insert(event.id)
        purchasedTicketEventIds.insert(event.id)
        defaults.set(starBalance, forKey: starBalanceKey)
        persistEventDecisions()
        Self.saveStringSet(purchasedTicketEventIds, defaults: defaults, key: ticketsKey)
    }

    func hasTicket(eventId: String) -> Bool {
        purchasedTicketEventIds.contains(eventId)
    }

    func blockUser(id: String) {
        guard !id.isEmpty else { return }
        blockedUserIds.insert(id)
        Self.saveStringSet(blockedUserIds, defaults: defaults, key: blockedUsersKey)
    }

    func unblockUser(id: String) {
        blockedUserIds.remove(id)
        Self.saveStringSet(blockedUserIds, defaults: defaults, key: blockedUsersKey)
    }

    func isBlocked(userId: String?) -> Bool {
        guard let userId, !userId.isEmpty else { return false }
        return blockedUserIds.contains(userId)
    }

    func resetDemoData() {
        likedPostIds = []
        savedEventIds = []
        interestedEventIds = []
        goingEventIds = []
        purchasedTicketEventIds = []
        starBalance = 0
        createdEvents = []
        blockedUserIds = []

        [
            likedPostsKey,
            savedEventsKey,
            interestedEventsKey,
            goingEventsKey,
            createdEventsKey,
            starBalanceKey,
            ticketsKey,
            blockedUsersKey
        ].forEach(defaults.removeObject(forKey:))
    }

    private func persistEventDecisions() {
        Self.saveStringSet(interestedEventIds, defaults: defaults, key: interestedEventsKey)
        Self.saveStringSet(goingEventIds, defaults: defaults, key: goingEventsKey)
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
        StarPackage(stars: 100, priceText: "Демо"),
        StarPackage(stars: 250, priceText: "Демо"),
        StarPackage(stars: 500, priceText: "Демо"),
        StarPackage(stars: 1_000, priceText: "Демо"),
        StarPackage(stars: 2_500, priceText: "Демо"),
        StarPackage(stars: 10_000, priceText: "Демо"),
        StarPackage(stars: 35_000, priceText: "Демо")
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
