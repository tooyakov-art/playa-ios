# Playa iOS

Native SwiftUI app for Playa: recommendation feed, events, tickets, bonus stars, chats, profile, settings, and TestFlight/App Store review content.

## Status

- Bundle ID: `app.playahub`
- App Store name: `Playa`
- Version: `1.0.0` build `16`
- Apple Team: `F8LA8PC4U6`
- Stack: Swift 5.9 + SwiftUI, iOS 16+, no external libraries
- Build: GitHub Actions macOS runner -> TestFlight

## Build 16 Scope

- Native SwiftUI `TabView`: Главная, События, Чаты, Профиль.
- Center floating `+` creates a local TestFlight event and opens it in Events.
- Login has Apple and Google entry points plus explicit local TestFlight fallback when Supabase is unavailable.
- Backend diagnostics show whether Supabase auth endpoint is reachable.
- Settings screen includes account edit, logout, delete account, language, subscription, stars, notifications, documents, support, app version, and database status.
- Profile shows editable user data, subscription, stars, tickets, saved events, event gallery, and settings entry.
- Feed has movies, banners, event recommendations, infinite demo posts, working likes, and event saves.
- Events use bonus-star ticket reservation and local saved state for build 12.
- Stars store no longer shows real-money prices; StoreKit purchases are disabled in v1.0 until IAP products are ready.

## Supabase

The old Supabase URL `yteqnagkxbbaqjdgoqeu.supabase.co` is not reachable from DNS, so real registration cannot work until a live project is connected.

Apply SQL in this order to the new production Supabase project:

1. `supabase/003_playa_core_schema.sql`
2. `supabase/002_content_reports.sql` if reports are not already included
3. `supabase/004_release_hardening.sql`
4. `supabase/001_delete_own_account.sql` only as a legacy fallback; `003_playa_core_schema.sql` already recreates `delete_own_account()`

Then update `Playa/Services/PlayaConfig.swift` with the live Supabase URL and anon key, and configure Supabase Auth providers:

- Apple provider for bundle `app.playahub`
- Google OAuth provider
- Redirect URL: `playa://auth-callback`

## Project Layout

```text
ios/
  project.yml
  ExportOptions.plist
  .github/workflows/ios-build.yml
  Playa/
    PlayaApp.swift
    ContentView.swift
    Services/
    Models/
    Views/
    Assets.xcassets/
  PlayaTests/
  supabase/
```
