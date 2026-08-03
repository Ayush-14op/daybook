# Daybook — working conventions

A local-first daily journal in Flutter. **Read [PLAN.md](PLAN.md) first** — its
handoff block says what's done and what's next. [docs/daybook-prd.md](docs/daybook-prd.md)
holds product scope; [docs/daybook-design-brief.md](docs/daybook-design-brief.md) holds UI intent.

## Rules that matter

- **Windows only, for now.** There is no Mac on this project. Never fill in the
  iOS stubs in `lib/platform/ios/` — they throw `UnimplementedError` on purpose
  (PLAN.md decision D2). Code that has never been compiled is not progress.
- **Riverpod, not Bloc** (D1). Pinned to 2.x — 3.x currently cannot resolve
  alongside `drift_dev`; see PLAN.md D1 for the constraint chain.
- **The UI never touches storage or platform code directly.** Everything goes
  through the interfaces in `lib/domain/repositories.dart`. If a widget needs
  `Platform.isWindows` to interpret what a repository returned, the abstraction
  has leaked — fix the interface, not the widget.
- **Every table keeps `id` (UUID), `updatedAt`, `deletedAt`** (D3). Sync is
  v1.1, but these three columns are free now and a migration later.
- **Plain text entries** (D4). No rich text, no Markdown editor, no formatting
  toolbar.
- **No analytics, no telemetry, no crash reporting SDK.** "No third-party
  analytics" is a product promise, not a default.

## Commands

```bash
flutter run -d windows          # run the app
dart run build_runner build     # after ANY change to lib/data/database.dart
flutter analyze                 # must be clean before commit
flutter test                    # must pass before commit
```

`--delete-conflicting-outputs` was removed in the current build_runner and is
ignored if passed.

## Layout

```
lib/
├── domain/       models, repository interfaces, in-memory fakes
├── data/         drift database + generated code + drift repositories
├── features/     entry/, history/ — screens and their state
├── ui/           theme and shared widgets
├── platform/     windows/ (real), ios/ (throwing stubs, gated on Mac)
└── providers.dart
```

## Adding dependencies

Add one at the step that needs it, with a one-line reason in the commit
message. The project is deliberately thin: no routing package, no HTTP client,
no icon pack until something actually requires it.

## Scope discipline

Each PLAN.md step carries a **fence** listing what it must not touch. When a
good idea arrives mid-step, add it to the PRD's stretch list and carry on —
don't widen the step.
