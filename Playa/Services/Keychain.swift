import Foundation
import Security

/// Thin wrapper around the iOS Keychain — used for tokens we must keep out of
/// UserDefaults (which is plaintext and included in iCloud backups).
///
/// Items are stored with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`,
/// which makes them readable after the first unlock and excluded from backups.
/// That's the standard recommendation for refresh tokens on iOS.
enum Keychain {
    private static let service = "app.playahub.session"

    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        if updateStatus == errSecItemNotFound {
            var insert = query
            for (k, v) in attributes { insert[k] = v }
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return false
    }

    static func get(_ key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return value
    }

    @discardableResult
    static func remove(_ key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
