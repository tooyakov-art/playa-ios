# Playa App Store Screenshot Plan

Build: `1.0.0 (16)`.

Target: iPhone-only screenshots. Use 6.9-inch portrait where possible.

Recommended export sizes:

- Primary: `1320 x 2868` PNG.
- Accepted alternatives: `1290 x 2796`, `1260 x 2736`.

## Screenshot set

| # | Title | Subtitle | Screen |
|---|---|---|---|
| 1 | Вечер начинается в Playa | События, кино и встречи в одной ленте | `01-login.png` |
| 2 | Выбирай по настроению | Кино, еда, сторис и события рядом | `02-feed.png` |
| 3 | Открой все категории | Быстрый список настроений на сегодня | `03-categories.png` |
| 4 | Бронируй демо-билет | Бесплатный review-сценарий без оплаты | `04-event-detail.png` |
| 5 | Чаты с организаторами | Детали, время и быстрые ответы в одном месте | `05-chats.png` |
| 6 | Твой Playa-профиль | Демо-звёзды, настройки, поддержка и безопасность | `06-profile.png` |

## Capture checklist

1. Install TestFlight build `1.0.0 (16)` or a local debug build from the same commit `f0e14e1`.
2. Open the app on a 6.9-inch iPhone simulator/device.
3. Use `Продолжить без входа` for review-mode access.
4. Keep status bar clean; avoid personal data.
5. Save raw screenshots into `app-store/screenshots/raw/`.
6. Save final cropped/exported PNGs into `app-store/screenshots/iphone-6-9/`.

## Current status

The final 6.9-inch screenshot set is captured at `1320 x 2868` and saved in `app-store/screenshots/iphone-6-9/`.
