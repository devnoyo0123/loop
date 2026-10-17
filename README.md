# Loop ↩

A local-first journaling app built around one idea: **your past self comes back to visit you.**

Write a log now, and "loop" it — Loop returns to you at the moment you chose (notification, or a full alarm), with an empty continuation waiting right where the original log sits in your timeline. Write back, and the chain grows.

## Features

- **⏳ Timeline** — a pure, chronological stream. No folders, no sections. Forks (continuations) nest right where they belong in time
- **↩ Loops** — one-shot reminders or repeating rules (every N minutes/hours, daily, weekdays — skipping Korean public holidays). Missed fires are caught up in their original time slots
- **🔔 or ⏰** — per-loop choice between a gentle notification and a full-screen, keeps-ringing alarm
- **📈 Forgetting curve** — the suggested interval grows each time a loop comes back (10 min → 1 hour → 1 day → 1 week → 1 month)
- **🖼 Photos, place & weather** — auto-captured context per log (coordinates stay on-device; only sent to the Open-Meteo weather API)
- **🔎 Full-text search** — SQLite FTS5 trigram index; Korean substring search included, with BM25 relevance sort
- **📦 Lossless export/import** — one `.looplog` (JSONL) file carries logs, photos and repeat rules; merge-import by globally-unique IDs never duplicates
- **🌍 6 languages** — ko / en / ja / zh / es / vi
- **☁️ Survives phone switches** — Android auto backup & device-to-device transfer enabled, plus manual export/import as the final safety net

## Tech

Flutter · SQLite (sqlite3) · flutter_local_notifications · FTS5 · SAF streaming · Material 3 with a custom Deep Night theme

## Build

```bash
flutter pub get
flutter run
```

Release signing expects `work/key.properties` + a keystore (kept out of the repo — see `.gitignore`). Without them, release builds fall back to the debug key.

## Docs

- [`docs/data-model.md`](docs/data-model.md) — SQLite schema, fork/loop/repeat design decisions
- [`docs/ui-design.md`](docs/ui-design.md) — UI decisions log
- [`docs/store-listing.md`](docs/store-listing.md) — store listing copy (6 languages)
- [`docs/privacy-policy.md`](docs/privacy-policy.md) — privacy policy (ko/en)
