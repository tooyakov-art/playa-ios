import Foundation

struct PlayaProfile: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let username: String?
    let avatarURL: URL?

    init(id: String, name: String, username: String?, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.username = username
        self.avatarURL = avatarURL
    }

    init(row: Row?) {
        let fallbackName = row?.username ?? "Playa User"
        self.id = row?.id ?? ""
        self.name = row?.name ?? fallbackName
        self.username = row?.username
        self.avatarURL = row?.avatar_url.flatMap(URL.init(string:))
    }

    struct Row: Decodable {
        let id: String
        let name: String?
        let username: String?
        let avatar_url: String?
    }
}

struct PlayaPost: Identifiable, Hashable {
    let id: String
    let authorId: String
    let text: String
    let imageURL: URL?
    let likesCount: Int
    let commentsCount: Int
    let eventId: String?
    let createdAt: Date?
    let author: PlayaProfile

    var createdText: String {
        guard let createdAt else { return "" }
        return RelativeDateTimeFormatter.playa.localizedString(for: createdAt, relativeTo: Date())
    }
}

extension PlayaPost {
    init(row: Row) {
        self.id = row.id
        self.authorId = row.author_id
        self.text = row.text
        self.imageURL = row.image_url.flatMap(URL.init(string:))
        self.likesCount = row.likes_count ?? 0
        self.commentsCount = row.comments_count ?? 0
        self.eventId = row.event_id
        self.createdAt = Date.playaISO(row.created_at)
        self.author = PlayaProfile(row: row.profile)
    }

    struct Row: Decodable {
        let id: String
        let author_id: String
        let text: String
        let image_url: String?
        let likes_count: Int?
        let comments_count: Int?
        let event_id: String?
        let created_at: String
        let profile: PlayaProfile.Row?

        enum CodingKeys: String, CodingKey {
            case id
            case author_id
            case text
            case image_url
            case likes_count
            case comments_count
            case event_id
            case created_at
            case profiles
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            author_id = try container.decode(String.self, forKey: .author_id)
            text = try container.decode(String.self, forKey: .text)
            image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
            likes_count = try container.decodeIfPresent(Int.self, forKey: .likes_count)
            comments_count = try container.decodeIfPresent(Int.self, forKey: .comments_count)
            event_id = try container.decodeIfPresent(String.self, forKey: .event_id)
            created_at = try container.decode(String.self, forKey: .created_at)
            profile = try container.decodeFlexibleProfile(forKey: .profiles)
        }
    }
}

struct PostComment: Identifiable, Hashable {
    let id: String
    let postId: String
    let authorId: String
    let text: String
    let createdAt: Date?
    let author: PlayaProfile
}

extension PostComment {
    init(row: Row) {
        self.id = row.id
        self.postId = row.post_id
        self.authorId = row.author_id
        self.text = row.text
        self.createdAt = Date.playaISO(row.created_at)
        self.author = PlayaProfile(row: row.profile)
    }

    struct Row: Decodable {
        let id: String
        let post_id: String
        let author_id: String
        let text: String
        let created_at: String
        let profile: PlayaProfile.Row?

        enum CodingKeys: String, CodingKey {
            case id
            case post_id
            case author_id
            case text
            case created_at
            case profiles
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            post_id = try container.decode(String.self, forKey: .post_id)
            author_id = try container.decode(String.self, forKey: .author_id)
            text = try container.decode(String.self, forKey: .text)
            created_at = try container.decode(String.self, forKey: .created_at)
            profile = try container.decodeFlexibleProfile(forKey: .profiles)
        }
    }
}

struct ChatPreview: Identifiable, Hashable {
    let id: String
    let otherUser: PlayaProfile
    let lastMessage: String?
    let lastMessageAt: Date?

    var subtitle: String {
        lastMessage ?? "No messages yet"
    }
}

struct ChatMessage: Identifiable, Hashable {
    enum Sender: String {
        case user
        case other
    }

    let id: String
    let sender: Sender
    let text: String
    let createdAt: Date?
    let senderName: String
    let senderAvatarURL: URL?
}

extension ChatMessage {
    init(row: Row, currentUserId: String) {
        let profile = PlayaProfile(row: row.profile)
        self.id = row.id
        self.sender = row.sender_id == currentUserId ? .user : .other
        self.text = row.text
        self.createdAt = Date.playaISO(row.created_at)
        self.senderName = profile.name
        self.senderAvatarURL = profile.avatarURL
    }

    struct Row: Decodable {
        let id: String
        let text: String
        let created_at: String
        let sender_id: String
        let profile: PlayaProfile.Row?

        enum CodingKeys: String, CodingKey {
            case id
            case text
            case created_at
            case sender_id
            case profiles
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            text = try container.decode(String.self, forKey: .text)
            created_at = try container.decode(String.self, forKey: .created_at)
            sender_id = try container.decode(String.self, forKey: .sender_id)
            profile = try container.decodeFlexibleProfile(forKey: .profiles)
        }
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleProfile(forKey key: Key) throws -> PlayaProfile.Row? {
        if let single = try? decodeIfPresent(PlayaProfile.Row.self, forKey: key) {
            return single
        }
        if let many = try? decodeIfPresent([PlayaProfile.Row].self, forKey: key) {
            return many.first ?? nil
        }
        return nil
    }
}

extension Date {
    static func playaISO(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

extension RelativeDateTimeFormatter {
    static let playa: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter
    }()
}
