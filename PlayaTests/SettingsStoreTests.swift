import XCTest
@testable import Playa

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testSettingsPersistLanguageSubscriptionAndNotificationToggles() {
        let suiteName = "playa.tests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.language = .kazakh
        store.subscriptionTier = .organizer
        store.chatNotificationsEnabled = false
        store.eventRemindersEnabled = false
        store.recommendationsEnabled = false

        let restored = SettingsStore(defaults: defaults)
        XCTAssertEqual(restored.language, .kazakh)
        XCTAssertEqual(restored.subscriptionTier, .organizer)
        XCTAssertFalse(restored.chatNotificationsEnabled)
        XCTAssertFalse(restored.eventRemindersEnabled)
        XCTAssertFalse(restored.recommendationsEnabled)
    }

    func testDefaultSettingsAreReleaseSafe() {
        let suiteName = "playa.tests.settings.defaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.language, .russian)
        XCTAssertEqual(store.subscriptionTier, .free)
        XCTAssertTrue(store.chatNotificationsEnabled)
        XCTAssertTrue(store.eventRemindersEnabled)
        XCTAssertTrue(store.recommendationsEnabled)
        XCTAssertEqual(AppLanguage.allCases.map(\.id), ["ru", "kk", "en"])
    }
}
