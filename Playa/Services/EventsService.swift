import Foundation

@MainActor
final class EventsService: ObservableObject {
    @Published private(set) var events: [PlayaEvent] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    func reload(category: String? = nil) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            var query: [URLQueryItem] = [
                URLQueryItem(name: "select", value: "id,title,description,category,location,image_url,starts_at,price_value"),
                URLQueryItem(name: "order", value: "starts_at.asc"),
                URLQueryItem(name: "limit", value: "100")
            ]
            if let category, !category.isEmpty {
                query.append(URLQueryItem(name: "category", value: "eq.\(category)"))
            }

            let data = try await supabase.restGetAnon(path: "events", query: query)
            let rows = try JSONDecoder().decode([PlayaEvent.Row].self, from: data)
            self.events = rows.map(PlayaEvent.init(row:))
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}
