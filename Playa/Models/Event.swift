import Foundation

struct PlayaEvent: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let description: String?
    let category: String?
    let location: String?
    let imageURL: URL?
    let startsAt: Date?
    let priceValue: Int

    var priceText: String {
        priceValue == 0 ? "Бесплатно" : "\(priceValue) ₸"
    }

    var dateText: String {
        guard let startsAt else { return "—" }
        return DateFormatter.playaDate.string(from: startsAt)
    }

    var timeText: String {
        guard let startsAt else { return "" }
        return DateFormatter.playaTime.string(from: startsAt)
    }
}

extension PlayaEvent {
    init(row: Row) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        self.id = row.id
        self.title = row.title ?? "Событие"
        self.description = row.description
        self.category = row.category
        self.location = row.location
        self.imageURL = row.image_url.flatMap(URL.init(string:))
        self.startsAt = row.starts_at.flatMap { iso in
            formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        }
        self.priceValue = row.price_value ?? 0
    }

    struct Row: Decodable {
        let id: String
        let title: String?
        let description: String?
        let category: String?
        let location: String?
        let image_url: String?
        let starts_at: String?
        let price_value: Int?
    }
}

extension DateFormatter {
    static let playaDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM"
        return f
    }()

    static let playaTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()
}
