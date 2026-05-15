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
}
