# Playa App Store Screenshot Plan

Build: `1.0.0 (14)`.

Target: iPhone-only screenshots. Use 6.9-inch portrait where possible.

Recommended export sizes:

- Primary: `1320 x 2868` PNG.
- Accepted alternatives: `1290 x 2796`, `1260 x 2736`.

## Screenshot set

| # | Title | Subtitle | Screen |
|---|---|---|---|
| 1 | Вечер начинается в Playa | События, кино и встречи в одной ленте | Login or Home feed with `Продолжить без входа` path tested |
| 2 | Выбирай по настроению | Кино, музыка, фестивали, еда, travel и не только | Home feed with category rail / expanded categories |
| 3 | Бронируй место за звёзды | Демо-билеты и QR для review-сценария | Event detail with demo ticket reservation |
| 4 | Все планы под рукой | Сохранённые события, демо-билеты и ближайшие активности | Events tab |
| 5 | Чаты с организаторами | Детали, время и быстрые ответы в одном месте | Chats list or chat thread |
| 6 | Твой Playa-профиль | Демо-звёзды, настройки, поддержка и безопасность | Profile/settings |

## Capture checklist

1. Install TestFlight build `1.0.0 (14)` or a local debug build from the same commit `94caacf`.
2. Open the app on a 6.9-inch iPhone simulator/device.
3. Use `Продолжить без входа` for review-mode access.
4. Keep status bar clean; avoid personal data.
5. Save raw screenshots into `app-store/screenshots/raw/`.
6. Save final cropped/exported PNGs into `app-store/screenshots/iphone-6-9/`.

## Current blocker

Local Xcode is installed, but this machine currently lacks a generated `Playa.xcodeproj` and local `xcodegen` binary. CI can build the app and upload to TestFlight. For local screenshot capture, generate the project first with XcodeGen or install from TestFlight on a device.
