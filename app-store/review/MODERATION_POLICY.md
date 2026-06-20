# Playa Moderation Policy for App Review

Build: Playa `1.0.0 (17)`.

## UGC surfaces

Playa has these user-generated-content surfaces:

- Feed posts.
- Post comments.
- Direct chats.
- Event chats.
- Profile text and avatars.

## User controls in build 17

- Users can report posts from the feed.
- Users can report comments from the comments sheet.
- Users can report direct chat messages.
- Users can report event chat messages.
- Users can block users from comments and chat message menus.
- Blocked users are hidden locally from comment/message views.
- Support contact is published as support@playahub.app.

## Moderation workflow

- Authenticated reports are sent to `content_reports`.
- Local review/demo reports show visible confirmation and are treated as review-mode moderation checks.
- The production Supabase release should apply `003_playa_core_schema.sql`, `002_content_reports.sql`, and `004_release_hardening.sql` before App Store submission.
- Moderation/support requests should be reviewed through Supabase `content_reports` and support@playahub.app.

## Objectionable content handling

Content that is abusive, hateful, explicit, illegal, spam, impersonation, or unsafe can be reported and removed. Accounts creating safety risks can be restricted or disabled.

## Real-money note

Build 17 does not sell real-money digital goods, paid tickets, paid stars, or subscriptions. Demo stars have no cash value.
