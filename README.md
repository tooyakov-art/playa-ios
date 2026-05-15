# Playa iOS

Native SwiftUI app for Playa: events, tickets, posts, chats, and city recommendations.

## Status

- **Bundle ID:** `app.playahub`
- **App Store name:** `Playa`
- **Version:** 1.0.0 (build 4)
- **Apple Team:** F8LA8PC4U6
- **Stack:** Swift 5.9 + SwiftUI, iOS 16+, no external libraries
- **Build:** GitHub Actions macOS runner -> TestFlight

## Current TestFlight Demo

- `LoginScreen` - Apple Sign-In and Google OAuth only, no guest preview.
- `MainTabView` - Telegram-style bottom controls: 4 tabs plus a solo create button.
- `FeedScreen` - recommendation feed with movies, banners, event cards, 100+ generated demo posts, working likes and event saves.
- `EventsScreen` - demo events from Kazakhstani company-style accounts with ticket, chat, save actions, and star-only ticket payment.
- `MatchesListView` - demo chats and company accounts.
- `ProfileScreen` - editable user profile with hero, stats, bio, city, username, event gallery, and star balance.
- `StarsStoreSheet` - Telegram-style star purchase screen with local demo balance top-up.
- `DemoContent` - local demo data so TestFlight never opens empty.

## Project Layout

```text
playa-ios/
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
```

## Next

- Persist create-event flow to Supabase.
- Store profile edits, saved events, star balance, and ticket purchases in Supabase.
- Add push notifications and real image uploads.
