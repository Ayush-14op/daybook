# PRD: Daybook (working title)

> **Status:** Draft · **Owner:** Ayush · **Last updated:** 2026-07-22
>
> A private daily journal app for iPhone, iPad, and Windows that combines
> journal entries with calendar events and reminders in one view. Inspired by
> Parchment, built cross-platform with Flutter.

---

## 1. Summary

Daybook is a local-first daily journaling app. Each day gets a single page that
puts your writing in context: today's calendar events and due reminders appear
inline, above the entry. One codebase (Flutter) targets iPhone, iPad, and
Windows desktop, with platform-specific OS integrations isolated behind clean
repository interfaces. No ads, no third-party analytics; storage is local by
default with optional cloud sync on the user's own backend (not iCloud-locked).

## 2. Goals

- Single codebase, native feel on iOS/iPadOS and Windows desktop.
- Daily journal entries with calendar/reminders context shown inline.
- Local-first storage with optional cloud sync (own backend, not iCloud-locked).
- No ads, no third-party analytics.

### Non-goals (v1)

- Android support.
- Real-time collaboration.
- Siri/Shortcuts integration (deferred to a later version).

## 3. Platforms

| Platform | Minimum version | Notes |
| --- | --- | --- |
| iPhone | iOS 16+ | EventKit for calendar + reminders |
| iPad | iPadOS 16+ | Same as iPhone; Apple Pencil is a stretch goal |
| Windows desktop | Windows 10/11 | Windows Calendar API for events; in-app task store for reminders |

**Framework:** Flutter (single Dart codebase). Platform channels bridge to
OS-specific integrations (EventKit on iOS, Windows Calendar API on Windows).

## 4. Core Features (MVP)

1. **Daily entry view** — one journal page per date; text editor with autosave.
2. **Calendar integration** — show today's events above the entry.
   - iOS: EventKit via platform channel.
   - Windows: Windows Calendar API via platform channel.
3. **Reminders / tasks integration** — show due/overdue items; mark complete
   inline.
   - iOS: EventKit reminders.
   - Windows: local task store (no native Windows Reminders API — build a simple
     in-app task list instead).
4. **Entry list / history** — scrollable list of past entries, searchable by
   date/keyword.
5. **Local storage** — SQLite (via `drift`) for entries, tasks, and cache.
6. **Sync (v1.1, not MVP)** — Supabase or Firebase backend, account-optional.

### MVP acceptance criteria

- Opening the app lands on today's entry; typing autosaves within ~1s of the
  last keystroke with no explicit "save" action.
- Today's calendar events (read-only in MVP) render above the entry when the
  OS grants permission; the entry view degrades gracefully when permission is
  denied or no events exist.
- Due and overdue reminders/tasks render and can be toggled complete from the
  entry view; the change persists across relaunch.
- History list shows past entries newest-first and filters by date and keyword
  substring.
- All entry, task, and cache data persists locally in SQLite and survives app
  restart with no network connection.

## 5. Stretch Features (post-MVP)

- Apple Pencil handwriting support on iPad (native only; no Windows equivalent).
- Widgets (iOS) / Windows Widgets Board.
- Export to PDF / Markdown.
- Custom themes / fonts.
- Spotlight indexing (iOS only).

## 6. Technical Notes

- **State management:** Riverpod or Bloc.
- **Storage:** `drift` (SQLite) for structured data, encrypted at rest.
- **Platform isolation:** platform-specific code lives behind repository
  interfaces (`CalendarRepository`, `TaskRepository`) so core UI never touches
  platform channels directly.
- **CI:** GitHub Actions with build targets for both iOS (Xcode) and Windows
  (MSBuild).

### Repository interface sketch

The core UI depends only on these interfaces; each platform provides a concrete
implementation, and there is an in-memory fake for tests.

```dart
abstract class CalendarRepository {
  /// Events occurring on [day], sorted by start time. Read-only in MVP.
  Future<List<CalendarEvent>> eventsOn(DateTime day);
  Future<PermissionStatus> ensurePermission();
}

abstract class TaskRepository {
  /// Tasks due or overdue as of [day].
  Future<List<Task>> dueBy(DateTime day);
  Future<void> setComplete(String taskId, {required bool complete});
}
```

| Interface | iOS impl | Windows impl |
| --- | --- | --- |
| `CalendarRepository` | EventKit (platform channel) | Windows Calendar API (platform channel) |
| `TaskRepository` | EventKit reminders | Local SQLite task store |

## 7. Open Questions & Recommendations

These remain business/product decisions for the owner; recommendations below are
starting positions, not final calls.

| # | Question | Recommendation (for discussion) |
| --- | --- | --- |
| 1 | Paid app, one-time purchase, or subscription? | One-time purchase for MVP (matches a private, no-analytics, local-first product); revisit subscription only if cloud sync incurs ongoing server cost. |
| 2 | Sync: build now or ship local-only MVP first? | Ship local-only MVP first. Sync (v1.1) is explicitly out of MVP scope; validate the core daily-journal loop before taking on backend + auth complexity. |
| 3 | Windows distribution: Microsoft Store vs. direct `.exe`/`.msix`? | Ship `.msix` (signed) for direct download early; add Microsoft Store once the app is stable, since Store review adds latency to each release. |

## 8. Suggested Phased Roadmap

- **Phase 0 — Foundation:** Flutter project scaffold, `drift` schema (entries,
  tasks), repository interfaces + in-memory fakes, CI green on both targets.
- **Phase 1 — MVP:** daily entry view + autosave, history list + search, local
  task store with inline complete, read-only calendar via platform channels.
- **Phase 2 — v1.1:** optional account + cloud sync (Supabase/Firebase),
  conflict handling, encrypted-at-rest verification.
- **Phase 3 — Stretch:** export (PDF/Markdown), themes/fonts, iOS widgets,
  Apple Pencil, Spotlight indexing.

## 9. Success Metrics (early)

- Daily entry completion rate among installs.
- Retention at day 7 / day 30.
- Crash-free session rate > 99%.

## 10. Risks & Open Concerns

- **Platform-channel surface area** — EventKit and Windows Calendar behave
  differently (permissions, recurrence, all-day events); the repository
  abstraction must not leak platform quirks into the UI.
- **Encryption-at-rest key management** — deciding where the key lives (Keychain
  on iOS, DPAPI/Credential Locker on Windows) is a design task, not a checkbox.
- **Windows reminders gap** — no native Reminders API means the in-app task
  store is the source of truth on Windows and will not sync with any OS task
  system; set user expectations accordingly.
- **Sync data model** — building sync later is cheaper if the local schema is
  designed with sync (stable IDs, updated-at timestamps, soft deletes) from
  Phase 0, even though sync ships in v1.1.
