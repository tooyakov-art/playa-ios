# Playa App Store Submission Pack

Current review candidate: Playa `1.0.0 (16)`.

TestFlight evidence:

- Git commit: `f0e14e1` (`Make review mode primary for build 16`)
- GitHub Actions run: https://github.com/tooyakov-art/playa-ios/actions/runs/27882234806
- Required release step: `Upload to TestFlight = success`

## App Information

- App name: Playa
- Subtitle: Афиша и встречи города
- Bundle ID: `app.playahub`
- SKU: `playa-ios`
- Primary language: Russian
- Primary category: Social Networking
- Secondary category: Entertainment
- Copyright: 2026 Playa
- License agreement: Apple Standard EULA
- Content rights: The app does not contain, show, or access third-party content unless users create or share it inside the app.
- Age rating suggestion: 12+ because the app contains user-generated social content and event/chat features.
- Version release setting: Manual release after approval.
- Pricing: Free.
- Availability: confirm target countries/regions in App Store Connect.
- DSA status: owner must confirm trader/non-trader status in App Store Connect.

## Version Information

### Promotional Text

Открывайте события, фильмы, встречи и городские активности в Playa. Лента подбирает рекомендации, а чаты помогают быстро обсудить планы.

### Description

Playa is a city discovery app for events, cinema nights, travel talks, parties, and local communities.

Users can browse a curated feed, save events, open event details, join event chats, manage a profile, and test ticket flows with free demo stars in version 1.0.

Version 1.0 does not sell real-money digital goods, subscriptions, or paid tickets. Demo stars are free review/TestFlight credits used only to preview ticket reservation flows until StoreKit products are ready.

### Keywords

события, билеты, афиша, кино, концерты, Алматы, встречи, чат, рекомендации, Playa

### What’s New

Build 16 prepares Playa for App Store review: primary guest review mode, polished Russian category rail, iPhone-only release target, privacy manifest, review legal documents, clearer demo-star ticket flow, visible UGC report/block controls, and hardened TestFlight upload workflow.

### Support URL

https://github.com/tooyakov-art/playa-ios/blob/main/SUPPORT.md

### Marketing URL

https://playahub.app

### Privacy Policy URL

https://github.com/tooyakov-art/playa-ios/blob/main/PRIVACY.md

## App Review Information

### Contact

- Email: support@playahub.app
- Name: Add owner/review contact name in App Store Connect.
- Phone: Add a reachable review phone number in App Store Connect.

### Demo Access

No username or password is required.

Tap `Продолжить без входа` on the login screen to open the app in local review mode without Apple Sign-In.

### Review Notes

Please use `Продолжить без входа` to access the app if Apple/Google authentication is unavailable during review.

The app includes a curated event feed, event details, demo ticket reservation, profile/settings, chats, post reporting, backend diagnostics, and account deletion flow.

Real-money star purchases, subscriptions, paid digital goods, and paid tickets are disabled in version 1.0. Stars shown in this build are free demo/review credits and have no cash value. StoreKit products will be added in a later app version and submitted separately for review.

UGC/moderation: users can report posts inside the app; moderation and support requests go to support@playahub.app. Account deletion is available from Settings.

Backend note: connect the production Supabase project and apply `supabase/003_playa_core_schema.sql` plus `supabase/002_content_reports.sql` before final App Store submission.
Production hardening note: also apply `supabase/004_release_hardening.sql`.

## Screenshot Set Needed

Build 16 is iPhone-only. Upload iPhone screenshots only.

Required practical set:

1. Login screen with `Продолжить без входа` visible.
2. Home feed with top category rail.
3. Expanded category tray.
4. Event detail / demo ticket reservation.
5. Chats screen.
6. Profile/settings screen.

Final screenshot files are in `app-store/screenshots/iphone-6-9/`.
