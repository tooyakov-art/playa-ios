import Foundation

final class SocialService {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    func loadPosts() async throws -> [PlayaPost] {
        let data = try await supabase.restGetAnon(
            path: "posts",
            query: [
                URLQueryItem(name: "select", value: "id,author_id,text,image_url,likes_count,comments_count,event_id,created_at"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "50")
            ]
        )
        let rows = try JSONDecoder().decode([PlayaPost.Row].self, from: data)
        return rows.map(PlayaPost.init(row:))
    }

    func createPost(authorId: String, text: String) async throws -> PlayaPost? {
        let data = try await supabase.restPost(
            path: "posts",
            body: [
                "author_id": authorId,
                "text": text
            ],
            query: [
                URLQueryItem(name: "select", value: "id,author_id,text,image_url,likes_count,comments_count,event_id,created_at")
            ]
        )
        let rows = try JSONDecoder().decode([PlayaPost.Row].self, from: data)
        return rows.first.map(PlayaPost.init(row:))
    }

    func loadPostComments(postId: String) async throws -> [PostComment] {
        let data = try await supabase.restGetAnon(
            path: "post_comments",
            query: [
                URLQueryItem(name: "select", value: "id,post_id,author_id,text,created_at"),
                URLQueryItem(name: "post_id", value: "eq.\(postId)"),
                URLQueryItem(name: "order", value: "created_at.asc")
            ]
        )
        let rows = try JSONDecoder().decode([PostComment.Row].self, from: data)
        return rows.map(PostComment.init(row:))
    }

    func createPostComment(authorId: String, postId: String, text: String) async throws -> PostComment? {
        let data = try await supabase.restPost(
            path: "post_comments",
            body: [
                "author_id": authorId,
                "post_id": postId,
                "text": text
            ],
            query: [
                URLQueryItem(name: "select", value: "id,post_id,author_id,text,created_at")
            ]
        )
        let rows = try JSONDecoder().decode([PostComment.Row].self, from: data)
        return rows.first.map(PostComment.init(row:))
    }

    func loadProfiles(excluding currentUserId: String) async throws -> [PlayaProfile] {
        let data = try await supabase.restGet(
            path: "profiles",
            query: [
                URLQueryItem(name: "select", value: "id,name,username,avatar_url"),
                URLQueryItem(name: "id", value: "neq.\(currentUserId)"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "30")
            ]
        )
        let rows = try JSONDecoder().decode([PlayaProfile.Row].self, from: data)
        return rows.map { PlayaProfile(row: $0) }
    }

    func openOrCreateDirectChat(userId: String, otherUserId: String) async throws -> String? {
        let existing = try await supabase.restGet(
            path: "chats",
            query: [
                URLQueryItem(name: "select", value: "id"),
                URLQueryItem(name: "or", value: "(and(user1_id.eq.\(userId),user2_id.eq.\(otherUserId)),and(user1_id.eq.\(otherUserId),user2_id.eq.\(userId)))"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        let existingRows = try JSONDecoder().decode([IdRow].self, from: existing)
        if let id = existingRows.first?.id {
            return id
        }

        let created = try await supabase.restPost(
            path: "chats",
            body: [
                "user1_id": userId,
                "user2_id": otherUserId
            ],
            query: [URLQueryItem(name: "select", value: "id")]
        )
        return try JSONDecoder().decode([IdRow].self, from: created).first?.id
    }

    func loadDirectChats(currentUserId: String) async throws -> [ChatPreview] {
        let chatData = try await supabase.restGet(
            path: "chats",
            query: [
                URLQueryItem(name: "select", value: "id,user1_id,user2_id"),
                URLQueryItem(name: "or", value: "(user1_id.eq.\(currentUserId),user2_id.eq.\(currentUserId))")
            ]
        )
        let chats = try JSONDecoder().decode([ChatRow].self, from: chatData)
        let chatIds = chats.map(\.id)
        let otherIds = chats.map { $0.user1_id == currentUserId ? $0.user2_id : $0.user1_id }
        let profiles = try await loadProfilesMap(ids: otherIds)
        var lastMessages: [String: LastMessageRow] = [:]

        if !chatIds.isEmpty {
            let msgData = try await supabase.restGet(
                path: "messages",
                query: [
                    URLQueryItem(name: "select", value: "chat_id,text,created_at"),
                    URLQueryItem(name: "chat_id", value: "in.(\(chatIds.joined(separator: ",")))"),
                    URLQueryItem(name: "order", value: "created_at.desc")
                ]
            )
            let rows = try JSONDecoder().decode([LastMessageRow].self, from: msgData)
            for row in rows where lastMessages[row.chat_id] == nil {
                lastMessages[row.chat_id] = row
            }
        }

        return chats.map { row in
            let otherId = row.user1_id == currentUserId ? row.user2_id : row.user1_id
            let other = profiles[otherId]
            let last = lastMessages[row.id]
            return ChatPreview(
                id: row.id,
                otherUser: PlayaProfile(row: other),
                lastMessage: last?.text,
                lastMessageAt: last?.created_at.flatMap(Date.playaISO)
            )
        }
        .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
    }

    func loadChatMessages(chatId: String, currentUserId: String) async throws -> [ChatMessage] {
        let data = try await supabase.restGet(
            path: "messages",
            query: [
                URLQueryItem(name: "select", value: "id,text,created_at,sender_id"),
                URLQueryItem(name: "chat_id", value: "eq.\(chatId)"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "200")
            ]
        )
        let rows = try JSONDecoder().decode([ChatMessage.Row].self, from: data)
        return rows.map { ChatMessage(row: $0, currentUserId: currentUserId) }
    }

    func sendDirectMessage(chatId: String, senderId: String, text: String) async throws {
        _ = try await supabase.restPost(
            path: "messages",
            body: [
                "chat_id": chatId,
                "sender_id": senderId,
                "text": text
            ]
        )
    }

    func joinEvent(eventId: String, userId: String) async throws {
        _ = try? await supabase.restPost(
            path: "event_members",
            body: [
                "event_id": eventId,
                "profile_id": userId,
                "role": "member"
            ]
        )
    }

    func loadEventMessages(eventId: String, currentUserId: String) async throws -> [ChatMessage] {
        let data = try await supabase.restGet(
            path: "event_messages",
            query: [
                URLQueryItem(name: "select", value: "id,text,created_at,sender_id"),
                URLQueryItem(name: "event_id", value: "eq.\(eventId)"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "200")
            ]
        )
        let rows = try JSONDecoder().decode([ChatMessage.Row].self, from: data)
        return rows.map { ChatMessage(row: $0, currentUserId: currentUserId) }
    }

    func sendEventMessage(eventId: String, senderId: String, text: String) async throws {
        _ = try await supabase.restPost(
            path: "event_messages",
            body: [
                "event_id": eventId,
                "sender_id": senderId,
                "text": text
            ]
        )
    }

    func reportContent(reporterId: String, kind: String, targetId: String, reason: String = "User report") async {
        _ = try? await supabase.restPost(
            path: "content_reports",
            body: [
                "reporter_id": reporterId,
                "content_type": kind,
                "content_id": targetId,
                "reason": reason
            ]
        )
    }

    private func loadProfilesMap(ids: [String]) async throws -> [String: PlayaProfile.Row] {
        let uniqueIds = Array(Set(ids)).filter { !$0.isEmpty }
        guard !uniqueIds.isEmpty else { return [:] }
        let data = try await supabase.restGet(
            path: "profiles",
            query: [
                URLQueryItem(name: "select", value: "id,name,username,avatar_url"),
                URLQueryItem(name: "id", value: "in.(\(uniqueIds.joined(separator: ",")))")
            ]
        )
        let rows = try JSONDecoder().decode([PlayaProfile.Row].self, from: data)
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }
}

private struct IdRow: Decodable {
    let id: String
}

private struct LastMessageRow: Decodable {
    let chat_id: String
    let text: String?
    let created_at: String?
}

private struct ChatRow: Decodable {
    let id: String
    let user1_id: String
    let user2_id: String
    let u1: PlayaProfile.Row?
    let u2: PlayaProfile.Row?
}
