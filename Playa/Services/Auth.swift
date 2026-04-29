import Foundation
import AuthenticationServices

@MainActor
final class Auth: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var userEmail: String?
    @Published private(set) var userId: String?
    @Published private(set) var isGuest: Bool = false

    let supabase = SupabaseClient()

    private let tokenKey = "playa.session.access_token"
    private let refreshKey = "playa.session.refresh_token"
    private let userIdKey = "playa.session.user_id"
    private let emailKey = "playa.session.email"
    private let guestKey = "playa.session.guest"

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

        let session = try await supabase.signInWithApple(identityToken: identityToken)
        store(session: session)
    }

    /// Demo / guest flow — local-only, no Supabase session. Lets users browse
    /// the app before committing to Apple Sign-In. All write actions are
    /// blocked behind an `auth.isGuest` check at the call site.
    func enterGuestMode() {
        clearStorage()
        UserDefaults.standard.set(true, forKey: guestKey)
        isGuest = true
        isAuthenticated = true
        userId = "guest"
        userEmail = nil
    }

    func signOut() async {
        clearStorage()
        supabase.accessToken = nil
        supabase.refreshToken = nil
        isAuthenticated = false
        isGuest = false
        userEmail = nil
        userId = nil
    }

    func deleteAccount() async throws {
        if isGuest {
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
            isGuest = true
            isAuthenticated = true
            userId = "guest"
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
    }

    private func store(session: SupabaseSession) {
        let defaults = UserDefaults.standard
        defaults.set(session.accessToken, forKey: tokenKey)
        defaults.set(session.refreshToken, forKey: refreshKey)
        defaults.set(session.user.id, forKey: userIdKey)
        defaults.set(session.user.email, forKey: emailKey)
        defaults.removeObject(forKey: guestKey)

        supabase.accessToken = session.accessToken
        supabase.refreshToken = session.refreshToken
        userId = session.user.id
        userEmail = session.user.email
        isAuthenticated = true
        isGuest = false
    }

    private func clearStorage() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: guestKey)
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
