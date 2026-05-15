# Playa iOS

Native SwiftUI app for Playa: events, tickets, posts, chats, and city recommendations.

## Status

- **Bundle ID:** `app.playahub`
- **App Store name:** `Playa`
- **Version:** 1.0.0 (build 3)
- **Apple Team:** F8LA8PC4U6
- **Stack:** Swift 5.9 + SwiftUI, iOS 16+, no external libraries
- **Build:** GitHub Actions macOS runner -> TestFlight

## Current TestFlight Demo

- `LoginScreen` - Apple Sign-In, Google demo entry, guest preview.
- `MainTabView` - 4 tabs: Home, Events, Chats, Profile, plus a floating create button.
- `FeedScreen` - recommendation feed with movies, banners, event cards, and 100+ generated demo posts.
- `EventsScreen` - demo events from Kazakhstani company-style accounts with ticket and chat actions.
- `MatchesListView` - demo chats and company accounts.
- `ProfileScreen` - rich user profile with hero, stats, bio, and event gallery.
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
- Wire real Google OAuth callback.
- Add push notifications and real image uploads.
