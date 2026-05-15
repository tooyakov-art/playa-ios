import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class Auth: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var userEmail: String?
    @Published private(set) var userId: String?
    @Published private(set) var isGuest: Bool = false
    @Published private(set) var isLocalAccount: Bool = false

    let supabase = SupabaseClient()
    private var webAuthSession: ASWebAuthenticationSession?
    private let presentationProvider = WebAuthPresentationProvider()

    private let tokenKey = "playa.session.access_token"
    private let refreshKey = "playa.session.refresh_token"
    private let userIdKey = "playa.session.user_id"
    private let emailKey = "playa.session.email"
    private let guestKey = "playa.session.guest"
    private let localProviderKey = "playa.session.local_provider"

    init() {
        loadStoredSession()
        supabase.onSessionRefreshed = { [weak self] session in
            Task { @MainActor in self?.store(session: session) }
        }
    }

    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }

        do {
            let session = try await supabase.signInWithApple(identityToken: identityToken)
            store(session: session)
        } catch {
            storeLocalAccount(provider: "apple", userId: "apple-\(credential.user)", email: credential.email ?? "apple@playa.local")
        }
    }

    func signInWithGoogle() async throws {
        guard await supabase.isAuthReachable() else {
            storeLocalAccount(provider: "google", userId: "google-local", email: "google@playa.local")
            return
        }

        let callbackScheme = "playa"
        let redirect = "\(callbackScheme)://auth-callback"
        let url = supabase.oauthURL(provider: "google", redirectTo: redirect)
        let callbackURL = try await runWebAuth(url: url, callbackScheme: callbackScheme)
        let values = callbackURL.playaAuthParameters

        guard let accessToken = values["access_token"] else {
            throw AuthError.invalidCredential
        }

        let user = try await supabase.loadUser(accessToken: accessToken)
        let session = SupabaseSession(
            accessToken: accessToken,
            refreshToken: values["refresh_token"],
            user: user
        )
        store(session: session)
    }

    func signOut() async {
        clearStorage()
        supabase.accessToken = nil
        supabase.refreshToken = nil
        isAuthenticated = false
        isGuest = false
        isLocalAccount = false
        userEmail = nil
        userId = nil
    }

    func deleteAccount() async throws {
        if isLocalAccount {
            await signOut()
            return
        }
        try await supabase.deleteOwnAccount()
        await signOut()
    }

    // MARK: - Persistence

    private func loadStoredSession() {
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: guestKey) {
            defaults.removeObject(forKey: guestKey)
        }

        if let localProvider = defaults.string(forKey: localProviderKey),
           let uid = defaults.string(forKey: userIdKey) {
            supabase.accessToken = nil
            supabase.refreshToken = nil
            userId = uid
            userEmail = defaults.string(forKey: emailKey) ?? "\(localProvider)@playa.local"
            isAuthenticated = true
            isGuest = false
            isLocalAccount = true
            return
        }

        guard let token = defaults.string(forKey: tokenKey),
              let uid = defaults.string(forKey: userIdKey)
        else {
            return
        }
        supabase.accessToken = token
        supabase.refreshToken = defaults.string(forKey: refreshKey)
        userId = uid
        userEmail = defaults.string(forKey: emailKey)
        isAuthenticated = true
        isGuest = false
        isLocalAccount = false
    }

    private func store(session: SupabaseSession) {
        let defaults = UserDefaults.standard
        defaults.set(session.accessToken, forKey: tokenKey)
        defaults.set(session.refreshToken, forKey: refreshKey)
        defaults.set(session.user.id, forKey: userIdKey)
        defaults.set(session.user.email, forKey: emailKey)
        defaults.removeObject(forKey: guestKey)
        defaults.removeObject(forKey: localProviderKey)

        supabase.accessToken = session.accessToken
        supabase.refreshToken = session.refreshToken
        userId = session.user.id
        userEmail = session.user.email
        isAuthenticated = true
        isGuest = false
        isLocalAccount = false
    }

    private func storeLocalAccount(provider: String, userId: String, email: String) {
        let defaults = UserDefaults.standard
        clearStorage()
        defaults.set(provider, forKey: localProviderKey)
        defaults.set(userId, forKey: userIdKey)
        defaults.set(email, forKey: emailKey)

        supabase.accessToken = nil
        supabase.refreshToken = nil
        self.userId = userId
        userEmail = email
        isAuthenticated = true
        isGuest = false
        isLocalAccount = true
    }

    private func clearStorage() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: guestKey)
        defaults.removeObject(forKey: localProviderKey)
    }

    private func runWebAuth(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: error ?? AuthError.invalidCredential)
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = presentationProvider
            webAuthSession = session
            if !session.start() {
                continuation.resume(throwing: AuthError.invalidCredential)
            }
        }
    }
}

private final class WebAuthPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Apple did not return a valid identity token."
        }
    }
}

private extension URL {
    var playaAuthParameters: [String: String] {
        var result: [String: String] = [:]
        if let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                result[item.name] = item.value
            }
        }
        if let fragment {
            let pairs = fragment.split(separator: "&")
            for pair in pairs {
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                result[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
            }
        }
        return result
    }
}
