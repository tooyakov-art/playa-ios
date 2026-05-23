import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case kazakh = "kk"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russian: return "Русский"
        case .kazakh: return "Қазақша"
        case .english: return "English"
        }
    }
}

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free
    case plus
    case organizer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Playa Plus"
        case .organizer: return "Organizer"
        }
    }

    var priceText: String {
        switch self {
        case .free: return "0 ₸"
        case .plus: return "1 990 ₸ / месяц"
        case .organizer: return "9 990 ₸ / месяц"
        }
    }

    var subtitle: String {
        switch self {
        case .free:
            return "Лента, события, чаты и билеты."
        case .plus:
            return "Больше рекомендаций, избранное и быстрые билеты."
        case .organizer:
            return "Создание мероприятий, промо-посты и аналитика."
        }
    }
}

struct LegalDocument: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL

    static let standard: [LegalDocument] = [
        LegalDocument(id: "privacy", title: "Privacy Policy", url: PlayaConfig.privacyURL),
        LegalDocument(id: "terms", title: "Terms of Use", url: PlayaConfig.termsURL),
        LegalDocument(id: "offer", title: "Публичная оферта", url: PlayaConfig.offerURL),
        LegalDocument(id: "refund", title: "Refund Policy", url: PlayaConfig.refundURL)
    ]
}

enum BackendConnectionStatus: Equatable {
    case unchecked
    case checking
    case online(statusCode: Int)
    case offline(message: String)

    var title: String {
        switch self {
        case .unchecked: return "Не проверено"
        case .checking: return "Проверяем"
        case .online: return "База доступна"
        case .offline: return "Сервер недоступен"
        }
    }

    var detail: String {
        switch self {
        case .unchecked:
            return "Нажмите проверку, чтобы увидеть текущий статус сервера."
        case .checking:
            return "Проверяем auth endpoint."
        case .online(let statusCode):
            return "Сервер отвечает. HTTP \(statusCode)."
        case .offline(let message):
            return message
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var subscriptionTier: SubscriptionTier {
        didSet { defaults.set(subscriptionTier.rawValue, forKey: Keys.subscriptionTier) }
    }

    @Published var chatNotificationsEnabled: Bool {
        didSet { defaults.set(chatNotificationsEnabled, forKey: Keys.chatNotifications) }
    }

    @Published var eventRemindersEnabled: Bool {
        didSet { defaults.set(eventRemindersEnabled, forKey: Keys.eventReminders) }
    }

    @Published var recommendationsEnabled: Bool {
        didSet { defaults.set(recommendationsEnabled, forKey: Keys.recommendations) }
    }

    @Published var backendStatus: BackendConnectionStatus = .unchecked

    let legalDocuments = LegalDocument.standard
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.language = defaults.string(forKey: Keys.language)
            .flatMap(AppLanguage.init(rawValue:)) ?? .russian
        self.subscriptionTier = defaults.string(forKey: Keys.subscriptionTier)
            .flatMap(SubscriptionTier.init(rawValue:)) ?? .free
        self.chatNotificationsEnabled = defaults.object(forKey: Keys.chatNotifications) as? Bool ?? true
        self.eventRemindersEnabled = defaults.object(forKey: Keys.eventReminders) as? Bool ?? true
        self.recommendationsEnabled = defaults.object(forKey: Keys.recommendations) as? Bool ?? true
    }

    private enum Keys {
        static let language = "playa.settings.language"
        static let subscriptionTier = "playa.settings.subscription_tier"
        static let chatNotifications = "playa.settings.notifications.chat"
        static let eventReminders = "playa.settings.notifications.events"
        static let recommendations = "playa.settings.notifications.recommendations"
    }
}
