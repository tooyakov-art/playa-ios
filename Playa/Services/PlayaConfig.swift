import Foundation

enum PlayaConfig {
    static let supabaseURL = URL(string: "https://yteqnagkxbbaqjdgoqeu.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0ZXFuYWdreGJiYXFqZGdvcWV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjcwOTYsImV4cCI6MjA5MTMwMzA5Nn0.K3Ld9IvmNOQ2UzzthZgw7bFl8BarZVf7qtoIZ3WM5ug"
    static let geminiProxyURL = URL(string: "https://playahub.app/api/gemini-proxy")!
    static let webAppURL = URL(string: "https://playahub.app")!
    static let privacyURL = URL(string: "https://playahub.app/privacy")!
    static let termsURL = URL(string: "https://playahub.app/terms")!
    static let supportEmail = "support@playahub.app"
    static let appVersion = "1.0.0"
}
