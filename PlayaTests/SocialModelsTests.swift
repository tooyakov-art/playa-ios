import XCTest
@testable import Playa

final class SocialModelsTests: XCTestCase {
    func testPostRowDecodesAuthorAndCounters() throws {
        let json = """
        {
          "id": "post-1",
          "author_id": "user-1",
          "text": "Hello Playa",
          "image_url": null,
          "likes_count": 3,
          "comments_count": 2,
          "event_id": null,
          "created_at": "2026-05-15T10:00:00Z",
          "profiles": {
            "id": "user-1",
            "name": "Aigerim",
            "username": "aigerim",
            "avatar_url": null
          }
        }
        """.data(using: .utf8)!

        let row = try JSONDecoder().decode(PlayaPost.Row.self, from: json)
        let post = PlayaPost(row: row)

        XCTAssertEqual(post.id, "post-1")
        XCTAssertEqual(post.author.id, "user-1")
        XCTAssertEqual(post.author.name, "Aigerim")
        XCTAssertEqual(post.likesCount, 3)
        XCTAssertEqual(post.commentsCount, 2)
    }

    func testMessageRowMarksCurrentUserAsUserSender() throws {
        let json = """
        {
          "id": "message-1",
          "text": "Yo",
          "created_at": "2026-05-15T10:00:00Z",
          "sender_id": "me",
          "profiles": {
            "id": "me",
            "name": "Me",
            "username": "me",
            "avatar_url": null
          }
        }
        """.data(using: .utf8)!

        let row = try JSONDecoder().decode(ChatMessage.Row.self, from: json)
        let message = ChatMessage(row: row, currentUserId: "me")

        XCTAssertEqual(message.id, "message-1")
        XCTAssertEqual(message.sender, .user)
        XCTAssertEqual(message.text, "Yo")
    }

    func testDemoFeedContainsOneHundredDifferentPosts() {
        let posts = DemoContent.recommendedPosts(count: 100)
        XCTAssertEqual(posts.count, 100)
        XCTAssertEqual(Set(posts.map(\.id)).count, 100)
        XCTAssertGreaterThan(Set(posts.map(\.author.name)).count, 10)
        XCTAssertTrue(posts.contains { $0.eventId != nil })
    }

    func testDemoChatsHaveMessages() {
        let chat = DemoContent.demoChats[0]
        let messages = DemoContent.messages(for: chat.id)
        XCTAssertGreaterThanOrEqual(messages.count, 4)
        XCTAssertTrue(messages.contains { $0.sender == .user })
        XCTAssertTrue(messages.contains { $0.sender == .other })
    }

    @MainActor
    func testStarsBuyTicketAndPersistBalance() throws {
        let suiteName = "playa.tests.stars.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = AppState(defaults: defaults)
        let event = DemoContent.events.first { $0.starPrice > 0 }!
        XCTAssertThrowsError(try state.buyTicket(event: event))

        state.buyStars(package: StarPackage(stars: 100, priceText: "test"))
        try state.buyTicket(event: event)

        XCTAssertTrue(state.hasTicket(eventId: event.id))
        XCTAssertEqual(state.starBalance, 100 - event.starPrice)
    }
}
