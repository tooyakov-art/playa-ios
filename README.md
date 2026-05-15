# Playa iOS

Native SwiftUI app for Playa — events, tickets, communities. Single target, zero third-party dependencies.

Built on the **X5 template** (already approved by Apple) — same SupabaseClient, Auth flow, Privacy Manifest, GitHub Actions pipeline.

## Status

- **Bundle ID:** `com.playastudio.app`
- **App Store name:** `Playa`
- **Version:** 1.0.0 (build 1)
- **Apple Team:** F8LA8PC4U6
- **Stack:** Swift 5.9 + SwiftUI, iOS 16+, no external libraries
- **Backend:** Supabase project `yteqnagkxbbaqjdgoqeu` (shared with web Playa)
- **Build:** GitHub Actions macOS-26 runner → TestFlight

## What's inside V1 (submit-ready)

- `LoginScreen` — Apple Sign-In + Demo guest mode
- `MainTabView` — 5 tabs: События, Категории, Лента, Чаты, Профиль
- `EventsScreen` — read-only events feed from `public.events`
- `CategoriesScreen` — 6 hard-coded categories
- `FeedScreen`, `MatchesListView` — placeholders, real content in V2
- `ProfileScreen` — sign out + two-step delete account (calls `public.delete_own_account()`)
- Privacy Manifest: 4 standard API reasons; no tracking; no third-party SDKs
- Camera + Photo Library usage descriptions ready for V2 features (QR scanner, image picker)

## Project layout

```
playa-ios/
├─ project.yml                    XcodeGen spec
├─ ExportOptions.plist            archive export config
├─ .github/workflows/
│  └─ ios-build.yml               macos-26 runner → TestFlight
├─ supabase/
│  └─ 001_delete_own_account.sql  apply once via Supabase SQL Editor
├─ scripts/
│  └─ gen-icon.mjs                regenerates AppIcon-1024.png
└─ Playa/
   ├─ PlayaApp.swift              @main entry
   ├─ ContentView.swift           auth gate
   ├─ Playa.entitlements          Sign in with Apple
   ├─ Services/                   PlayaConfig, SupabaseClient, Auth, AppState, EventsService
   ├─ Models/                     Event, Category
   ├─ Views/                      LoginScreen, MainTabView, EventsScreen, CategoriesScreen,
   │                              FeedScreen, MatchesListView, ProfileScreen
   └─ Assets.xcassets/            AppIcon + brand color sets
```

## Build it

You don't need a Mac. Push to `main`, GitHub Actions builds and uploads to TestFlight.

See [`SUBMIT.md`](./SUBMIT.md) for the full submission walkthrough — bundle ID registration, App Store Connect entry, certificate + provisioning profile generation, GitHub Secrets configuration.

## Updating the icon

```bash
node scripts/gen-icon.mjs
```

Outputs `Playa/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`.

## Roadmap

- **V1.0** — Login + Events + Categories + Profile (this branch)
- **V2.0** — Feed posts, comments, Create Event (UGC + Report/Block)
- **V2.1** — Realtime chats (event chats, DMs)
- **V2.2** — AI chats via Gemini proxy + admin panel
## CI note

The active TestFlight workflow is `.github/workflows/ios-build.yml` in this iOS repository.

## Social MVP scope

V1.0 now targets Login + Events + Feed + Comments + DMs + Event chats + Profile.
V1.1 can add image upload, push notifications, and a full block list.
