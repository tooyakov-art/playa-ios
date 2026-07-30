# Playa iOS — UX audit

Date: 2026-07-29  
Source: 38.6-second TestFlight screen recording, build 18  
User goal: quickly find where to go in Almaty, commit to an event, get a ticket, and keep the event details and conversation in one place.

## Verdict

Playa already has a recognizable visual identity: bold editorial typography, a dark city-night palette, a strong pink accent, and image-led event cards. The app should not be visually redesigned from scratch.

The main gap is product truth. The interface presents a live city platform, while key actions still expose demo behavior: demo tickets, demo stars, a guest profile with populated metrics, and a create-event flow that contradicts itself about publishing versus saving a draft.

Recommended core loop:

`Discover → Interested / Going → Ticket / QR → Event chat → Attend`

## Captured flow

Stable evidence frames were reviewed at approximately 5.5, 9.4, 11.2, 14.3, 17.4, 19.4, 22.2, 25.3, 26.5, 29.4, 33.0, and 36.7 seconds.

### 1. Launch — critical

- The first visible launch stays on a black screen with a spinner for at least seven seconds.
- There is no product name, progress explanation, timeout, error, or retry action.
- After leaving and reopening Playa through TestFlight, the app becomes usable in about 0.6 seconds.

### 2. Home — strong identity, unclear priority

- “Куда пойдём?” immediately communicates the product promise.
- Movies, categories, a promotional banner, events, and creation compete for attention above the fold.
- The bottom bar and central add button overlap upcoming content.

### 3. Social feed — lively but competing

- Organizer posts and event imagery make the city feel active.
- The screen shifts between two mental models: choosing an event and reading a social feed.
- Similar events repeat across multiple sections without a clear hierarchy.

### 4. Categories — visible but structurally mixed

- The expanded state is easy to notice and the tiles have comfortable touch areas.
- Event types, moods, and social scenarios are mixed together: “Кино”, “Вечер”, “Для двоих”, `Travel`, and “Требуется”.
- Russian and English labels are mixed.
- After selecting “Кино”, the chip changes immediately, but the visible content barely changes and there is no result count or explanation.

### 5. Events — the strongest current screen

- Date, time, venue, price, category, chat, and save actions are visible on the card.
- “Открыть демо-билет” skips the user’s decision. Prefer `Интересно → Иду → Билет`.
- The number `10` in the top-right corner is not labeled.
- The central add button overlaps the next card.

### 6. Chat list — easy to scan, mixed entities

- Dialog rows are readable and message previews help recognition.
- Conversations and brand/company pages are mixed in one stream even though they lead to different actions.
- “19 активно” is ambiguous.

### 7. Direct chat — readable, missing context

- Incoming and outgoing messages are visually distinct.
- There is no visible back or close button; the recording exits with a gesture.
- Event, ticket, timestamps, delivery/read state, and organizer context are missing.
- Repeated message menus add visual noise.

### 8. Event details — clear base, weak trust

- The hero image, date, time, and location create a clear hierarchy.
- “Демо-билет добавлен” has weak contrast and does not lead to a visible QR ticket.
- “Добавить демо-звёзды” exposes internal demo behavior in the primary flow.
- No visible back button is shown.
- The field labeled “Город” contains the venue `Almaty Arena`.
- Organizer identity, map/address, attendees, ticket rules, and refund information are missing.

### 9. Event chat — right idea, insufficient anchors

- The event name makes the conversation context clear.
- There is no visible back button, participant count, pinned details, moderation entry, or shortcut to the event and ticket.

### 10. Profile — visually coherent, untrustworthy data

- Profile hierarchy and section grouping are strong.
- A user labeled “Гость” already has followers, follows, ten events, four tickets, and 190 demo stars.
- “Организ...” is truncated at the default text size.
- The central add button overlaps the recent-events area.

### 11. Settings — familiar structure, unclear account state

- Account and language sections are familiar.
- A guest user is shown the synthetic address `google@playa.local`, which looks like a connected account.
- Sign out and delete account compete visually with normal account information.
- It is unclear when the language change is applied.

### 12. Create event — critical product gap

- The form is visually simple and approachable.
- The screen says “Черновик события”, the CTA says “Опубликовать”, and the helper text says the event will be saved as a draft and immediately appear in Events.
- A real publishing flow needs date, time, cover image, description, exact address, capacity, ticket rules, preview, validation, and a separate publish action.

## Step health

| Step | Surface | Health |
| ---: | --- | --- |
| 1 | Launch | Red — unreliable start with no recovery |
| 2 | Home | Yellow — strong presentation, too many competing entry points |
| 3 | Social feed | Yellow — lively, but dilutes event discovery |
| 4 | Categories | Yellow — visible, but structurally inconsistent |
| 5 | Events | Green/yellow — strongest foundation, incorrect CTA logic |
| 6 | Chat list | Yellow — scannable, mixed information architecture |
| 7 | Direct chat | Yellow — readable, missing navigation and event context |
| 8 | Event details | Red — the key decision depends on demo behavior |
| 9 | Event chat | Yellow — right concept, insufficient context and trust |
| 10 | Profile | Red — synthetic data undermines trust |
| 11 | Settings | Yellow — familiar structure, ambiguous state |
| 12 | Create event | Red — draft and publish states contradict each other |

## Priorities

### P0 — make the core flow truthful

1. Fix the launch hang and provide a bounded loading state, error, and retry.
2. Clearly separate demo mode from a real account and remove synthetic profile metrics from empty states.
3. Replace “Open demo ticket” with `Interested → Going → real ticket / QR`.
4. Either complete event publishing or keep an honest “Save draft” action.
5. Connect live data and run behavioral tests in CI before the next public build.

### P1 — create one complete product loop

1. Focus Home on “what to do today” with time, distance, price, and a small set of personalized events.
2. Move movies, promotions, and social posts below the primary event-discovery path or into secondary modes.
3. Add organizer identity, map, attendees/friends, reminders, and calendar actions to event details.
4. Separate event chats, direct messages, and brand pages.
5. Pin the ticket and event details inside the event chat.
6. Complete the event form with date/time, image, description, capacity, price, preview, validation, and publishing.

### P2 — retention and polish

1. Add a “city pulse” map for now, tonight, and the weekend.
2. Show friends who are going and support invitations.
3. Add post-event albums and safe mutual connections.
4. Fix mixed localization, clipped labels, and content covered by the central add button.
5. Validate Dynamic Type, VoiceOver, contrast, reduced motion, focus order, and alternatives to gesture-only navigation.

## Accessibility evidence limits

The recording indicates likely risks from small letter-spaced labels, gray text on gradients, color-only selection states, clipped text, content overlap, and gesture-only dismissal. It does not prove full accessibility behavior.

A separate device pass is required for VoiceOver labels and reading order, Dynamic Type, Bold Text, Display Zoom, exact contrast ratios, touch target sizes, Switch Control, Reduce Motion, network errors, validation, and the real QR flow.
