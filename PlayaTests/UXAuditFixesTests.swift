import XCTest
@testable import Playa

@MainActor
final class UXAuditFixesTests: XCTestCase {
    func testGoingAlwaysImpliesInterested() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        state.markGoing(eventId: "event-1")

        XCTAssertTrue(state.isInterested(eventId: "event-1"))
        XCTAssertTrue(state.isGoing(eventId: "event-1"))
    }

    func testDraftStoresTruthfulLocalState() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let start = Date(timeIntervalSince1970: 1_800_000_000)
        state.createLocalEvent(
            title: "Ночной показ",
            description: "Фильм и обсуждение",
            location: "Алматы · Арбат, 10",
            category: "Кино",
            startsAt: start,
            starPrice: 25,
            capacity: 80
        )

        let draft = try? XCTUnwrap(state.createdEvents.first)
        XCTAssertEqual(draft??.title, "Ночной показ")
        XCTAssertEqual(draft??.startsAt, start)
        XCTAssertEqual(draft??.starPrice, 25)
        XCTAssertTrue(draft??.id.hasPrefix("local-event-") == true)
        XCTAssertTrue(draft??.description?.contains("Черновик") == true)
        XCTAssertTrue(draft??.description?.contains("Вместимость: 80") == true)
    }

    func testResetDemoDataClearsLocalActivity() {
        let (state, defaults, suiteName) = makeState()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        state.toggleLike(postId: "post-1")
        state.toggleSavedEvent(eventId: "event-1")
        state.markGoing(eventId: "event-1")
        state.blockUser(id: "user-1")
        state.createLocalEvent(title: "Черновик", location: "Алматы", category: "Кино", starPrice: 0)

        state.resetDemoData()

        XCTAssertTrue(state.likedPostIds.isEmpty)
        XCTAssertTrue(state.savedEventIds.isEmpty)
        XCTAssertTrue(state.interestedEventIds.isEmpty)
        XCTAssertTrue(state.goingEventIds.isEmpty)
        XCTAssertTrue(state.purchasedTicketEventIds.isEmpty)
        XCTAssertTrue(state.createdEvents.isEmpty)
        XCTAssertTrue(state.blockedUserIds.isEmpty)
        XCTAssertEqual(state.starBalance, 0)
    }

    private func makeState() -> (AppState, UserDefaults, String) {
        let suiteName = "PlayaTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (AppState(defaults: defaults), defaults, suiteName)
    }
}
