# Playa Backend Checklist for Build 17

Before submitting build `1.0.0 (17)` to App Store review, the production backend must be live.

## Supabase

- Create or restore the production Supabase project.
- Update `Playa/Services/PlayaConfig.swift` with the production Supabase URL.
- Replace the legacy anon key with the current publishable/anon client key.
- Apply SQL in order:
  1. `supabase/003_playa_core_schema.sql`
  2. `supabase/002_content_reports.sql`
  3. `supabase/004_release_hardening.sql`
- Confirm `delete_own_account()` executes for authenticated users.
- Confirm `content_reports` accepts authenticated reports.
- Confirm public profile reads do not expose `email`.
- Confirm direct/event message inserts require chat/event membership.

## Auth

- Enable Sign in with Apple for bundle `app.playahub`.
- Configure Google OAuth.
- Add redirect URL `playa://auth-callback`.
- Test login, logout, and account deletion on TestFlight.

## App Store Connect

- Select TestFlight build `1.0.0 (17)` after processing completes.
- Fill App Privacy answers from `APP_STORE_PRIVACY_ANSWERS.md`.
- Use review notes from `APP_STORE_SUBMISSION.md`.
- Upload iPhone screenshots only; build 17 is iPhone-only.
