# Daily Ticker — Flutter Mobile App

Native iOS/Android port of the Daily Ticker web app. Same data model, features, and kid-friendly UI.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.19+)

## First-time setup

If this folder was created without platform files, generate them from the repo root:

```bash
cd mobile
flutter create . --project-name daily_ticker --org com.dailyticker
flutter pub get
```

## Run

```bash
cd mobile
flutter run
```

## Features (parity with web)

- **Profiles** — create, switch, avatars
- **Today** — weather/mood, mission picker, star completion, celebration banner
- **My Missions** — CRUD, reorder, emoji icons, colors, weekly goals (1–7)
- **My Wins** — week/month/year stats, top missions chart, calendar, day recap, achievements

## Storage

Uses `shared_preferences` with key `daily_ticker_data` — same JSON shape as the web app for future migration.

## Project structure

```
lib/
  models/       Data types
  data/         Defaults + persistence
  utils/        Date, stats, achievements, colors
  providers/    App state (mirrors web AppProvider)
  screens/      Today, Missions, Wins
  widgets/      Profile picker, bottom nav
  theme/        Colors and shared UI
```
