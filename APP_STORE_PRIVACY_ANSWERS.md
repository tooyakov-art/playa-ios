# Playa App Store Privacy Answers

Use these answers in App Store Connect for build `1.0.0 (14)`. Keep them aligned with `Playa/PrivacyInfo.xcprivacy`.

## Tracking

- Does the app track users across apps and websites owned by other companies? No.
- Third-party tracking domains: none.

## Data Linked to the User

Declare these as linked to the user and used for app functionality:

- Contact Info: Email Address, when the user signs in.
- Identifiers: User ID, Supabase/auth profile ID.
- User Content: posts, comments, direct chats, event chats, reports, profile text, avatar/event images if uploaded.
- Photos or Videos: avatar and event cover images selected by the user.

## Data Not Collected in Build 14

- Payment Info: not collected; real-money purchases are disabled.
- Purchases: not collected; StoreKit/IAP is disabled.
- Precise Location: not collected.
- Contacts: not collected.
- Browsing History: not collected.
- Search History: not collected.
- Health/Fitness: not collected.
- Financial Info: not collected.
- Sensitive Info: not collected.
- Crash Data / Diagnostics: no custom diagnostics collection is implemented in app code; Apple may process App Store/TestFlight diagnostics separately.

## Data Not Used for Tracking

All declared data is not used for tracking.

## Main Purposes

- App Functionality.
- Account management is handled as part of app functionality.
- Moderation/support uses submitted reports and support email.

## Not in build 14

- Real-money in-app purchases are disabled.
- Subscriptions are disabled.
- Paid tickets are disabled.
- Advertising tracking is not used.
