import Foundation

struct SupabaseUser: Decodable {
    let id: String
    let email: String?
}

struct SupabaseSession: Decodable {
    let accessToken: String
    let refreshToken: String?
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

final class SupabaseClient {
    private let baseURL = PlayaConfig.supabaseURL
    private let anonKey = PlayaConfig.supabaseAnonKey

    var accessToken: String?
    var refreshToken: String?

    /// Hook for the Auth layer to persist refreshed tokens to UserDefaults.
    var onSessionRefreshed: ((SupabaseSession) -> Void)?

    func signInWithApple(identityToken: String) async throws -> SupabaseSession {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "provider": "apple",
            "id_token": identityToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try ensureOK(response: response, data: data)
        return try JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func refreshSession() async throws -> SupabaseSession {
        guard let refresh = refreshToken else {
            throw SupabaseError.notAuthenticated
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refresh])

        let (data, response) = try await URLSession.shared.data(for: request)
        try ensureOK(response: response, data: data)
        let session = try JSONDecoder().decode(SupabaseSession.self, from: data)
        accessToken = session.accessToken
        refreshToken = session.refreshToken ?? refreshToken
        onSessionRefreshed?(session)
        return session
    }

    func deleteOwnAccount() async throws {
        try await runAuthed { token in
            let url = self.baseURL.appendingPathComponent("rest/v1/rpc/delete_own_account")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(self.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = "{}".data(using: .utf8)
            return request
        }
    }

    // MARK: - REST helpers for domain services

    /// GET /rest/v1/<path>?<query>
    func restGet(path: String, query: [URLQueryItem] = []) async throws -> Data {
        try await runAuthed { token in
            var components = URLComponents(
                url: self.baseURL.appendingPathComponent("rest/v1/\(path)"),
                resolvingAgainstBaseURL: false
            )!
            if !query.isEmpty { components.queryItems = query }
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue(self.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            return request
        }
    }

    /// Anonymous GET (uses anon key only). Used for public reads.
    func restGetAnon(path: String, query: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/\(path)"),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        try ensureOK(response: response, data: data)
        return data
    }

    // MARK: - Auth-aware request runner with auto-refresh on 401

    @discardableResult
    func runAuthed(_ build: @escaping (String) -> URLRequest) async throws -> Data {
        guard let token = accessToken else { throw SupabaseError.notAuthenticated }
        let request = build(token)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401, refreshToken != nil {
            _ = try await refreshSession()
            guard let newToken = accessToken else { throw SupabaseError.notAuthenticated }
            let retryRequest = build(newToken)
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            try ensureOK(response: retryResponse, data: retryData)
            return retryData
        }

        try ensureOK(response: response, data: data)
        return data
    }

    private func ensureOK(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        if !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.serverError(status: http.statusCode, body: body)
        }
    }
}

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case serverError(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let status, let body):
            return "Server error \(status): \(body)"
        }
    }
}
