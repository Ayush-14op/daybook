# Daybook

> A private, local-first daily journal app for iPhone, iPad, and Windows —
> built with Flutter. Journal entries with today's calendar events and
> reminders shown inline. Inspired by Parchment.

**Status:** Planning / PRD stage.

## What it is

One journal page per day that puts your writing in context: today's calendar
events and due reminders appear above the entry. A single Flutter codebase
targets iPhone, iPad, and Windows desktop, with OS-specific integrations
(EventKit, Windows Calendar) isolated behind clean repository interfaces.

- Local-first storage (SQLite via `drift`), encrypted at rest
- Optional cloud sync on your own backend (v1.1) — not iCloud-locked
- No ads, no third-party analytics

## Documentation

- **[Product Requirements (PRD)](docs/daybook-prd.md)** — goals, platforms,
  MVP scope + acceptance criteria, repository-interface sketch, roadmap, and
  open questions.
- **[UI/UX Design Brief](docs/daybook-design-brief.md)** — screens, component
  system, core flows, visual direction, states, and open design questions.

## Platforms

| Platform | Minimum | Calendar | Reminders |
| --- | --- | --- | --- |
| iPhone / iPad | iOS/iPadOS 16+ | EventKit | EventKit reminders |
| Windows desktop | Windows 10/11 | Windows Calendar API | In-app task store |

## Tech stack

Flutter (Dart) · `drift` (SQLite) · Riverpod or Bloc · platform channels for
OS integrations · GitHub Actions CI (iOS + Windows build targets).

## Repository layout

```
daybook/
├── README.md
└── docs/
    ├── daybook-prd.md            # product requirements
    └── daybook-design-brief.md   # UI/UX design brief
```
