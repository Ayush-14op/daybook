# Daybook — Build Plan

> **Single source of truth for execution.** Update this file as stages complete.
> Product scope lives in [docs/daybook-prd.md](docs/daybook-prd.md); UI intent in
> [docs/daybook-design-brief.md](docs/daybook-design-brief.md). This file is the
> *how and in what order*.

---

## Handoff block — read this first

**Paste this paragraph at the start of any fresh session.**

Daybook is a local-first daily journal app built in Flutter: one page per day,
with today's calendar events and due reminders shown in a "context strip" above
the editor. Targets are Windows desktop and iOS/iPadOS — but **development is
Windows-first because the owner has no Mac**; iOS platform implementations stay
as throwing stubs until Mac access exists. State management is **Riverpod**;
storage is **drift (SQLite)** with a sync-ready schema from day one (UUID
primary keys, `updatedAt`, soft deletes) even though sync itself is v1.1. The
MVP is "for me first, ship later": build for the owner's daily use, but take no
shortcut that blocks a public release later. Read the Decisions section below
before changing any of those choices — they have reasons. Then find the first
stage whose checkbox is unticked and start at its first unticked step.

**Current state (2026-08-05):** **Stages 1 and 2 are complete.** Daybook is a
usable private journal: opens on today, autosaves as you type, survives a cold
restart, moves between days by control or keyboard, lists past entries in a
pane above 900px (its own screen below), and searches them. `flutter analyze` is
clean and 60 tests pass. **Remaining in stage 0:** step 0.2 (OneDrive exclusion
— needs a decision from the owner) and step 0.5 (the encryption spike). Step 0.6
came back positive. **Next up: stage 3** — the context strip and the local task
store.

---

## Progress

- [ ] **Stage 0** — Foundation: app window opens on Windows, CI green
- [x] **Stage 1** — Walking skeleton: write today's entry, it survives restart
      *(done 2026-08-05 — verified by typing into the running app, killing the
      process, and relaunching cold)*
- [x] **Stage 2** — Time travel: navigate days, browse history, search
      *(done 2026-08-05)*
- [ ] **Stage 3** — Tasks: due items in the context strip, complete inline
- [ ] **Stage 4** — Calendar: today's real events above the entry
- [ ] **Stage 5** — Polish: states, accessibility, dark mode, long content
- [ ] **Stage 6** — Ship to self: packaged `.msix`, installed, used daily
- [ ] **Stage 7** — *(gated on Mac access)* iOS enablement

---

## Decisions (and what was rejected)

Each of these was a real fork. Don't relitigate without a new reason.

### D1 — Riverpod, not Bloc

**Chosen:** `flutter_riverpod`.
**Rejected:** Bloc — event/state boilerplate per feature is a poor trade for a
solo project with maybe six screens. Rejected: plain `setState` /
`InheritedWidget` — fine for the editor alone, falls apart once the context
strip, autosave status, and day navigation all read shared state.
**Why it wins here:** provider overrides make swapping the in-memory fake
repositories into widget tests a one-liner, and the PRD already committed to
repository interfaces. The two designs fit together with no glue.

**Pinned to 2.6.1, not 3.x** *(found during step 0.3)*: `flutter_riverpod`
3.4.2 depends on `riverpod` 3.4.2, which depends on `test ^1.0.0`, whose
`analyzer` constraint collides with `drift_dev`'s `analyzer ^13.0.0` under the
`matcher`/`test_api` versions pinned by `flutter_test`. Pub's resolver reports
it plainly: with `drift_dev` and `build_runner` present, Riverpod 3.x has no
solution. Riverpod 2.6.1 is the newest resolvable version and is fully
supported. **Recheck at stage 5** by running `flutter pub outdated` — if
`drift_dev` widens its analyzer range, upgrading is a contained change.

### D2 — Windows-first, iOS stubbed

**Chosen:** build the entire MVP against Windows plus in-memory fakes;
`CalendarRepository`/`TaskRepository` iOS implementations are stubs that throw
`UnimplementedError`.
**Rejected:** parallel iOS development via GitHub Actions macOS runners — you'd
be writing EventKit code you cannot run, debug, or see. Unverifiable code is
debt, not progress.
**Why:** the repository abstraction the PRD already specifies makes deferring
one platform nearly free. Stage 7 is written and ready for the day a Mac shows
up.

### D3 — Sync-ready schema from Stage 0, sync itself in v1.1

**Chosen:** every table gets a UUID `id`, an `updatedAt` epoch-ms column, and a
nullable `deletedAt` (soft delete). No sync code, no accounts, no network.
**Rejected:** natural keys (`day` as primary key) — cheaper now, but makes
merge conflicts unresolvable when two devices edit the same day offline.
**Why:** this is the one piece of future-proofing that's nearly free today and
expensive as a migration later. The PRD's own risk list calls it out.

### D4 — Plain text editor for MVP

**Chosen:** a plain `TextField` over plain-text storage.
**Rejected:** rich text / Markdown / a Quill-style editor. The design brief's
hero is *comfortable writing*, not formatting toolbars, and rich text drags in a
document model, a serialisation format, and a sync merge problem all at once.
**Why:** you can add Markdown rendering later over the same plain-text column
without a migration. You cannot easily walk back a rich-text document model.

### D5 — Encryption at rest: decided by spike, not by assumption

**Chosen:** encrypted SQLite with the key held in platform secure storage
(DPAPI/Credential Locker on Windows, Keychain on iOS). **The mechanism is
unverified on Flutter Windows desktop** — Step 0.5 is a spike, not an
implementation.

**Correction — the obvious route is closed** *(found during step 0.3)*: both
`sqlcipher_flutter_libs` (0.7.0+eol) and `sqlite3_flutter_libs` (0.6.0+eol) are
now **end-of-life no-op shims**. Their pub.dev notice: they relate to
`package:sqlite3` 2.x and are obsolete after upgrading, and since 0.7.0 /
0.6.0 they "no longer do anything." This project already resolves
`sqlite3` 3.5.0, so those two packages come in transitively via
`drift_flutter` 0.3.1 and are inert. **The spike must therefore target
`package:sqlite3` 3.x's own encryption story, not `sqlcipher_flutter_libs`.**
Start by reading the `package:sqlite3` 3.x upgrade notes for how encrypted
databases are meant to be opened now — do not copy any pre-3.x SQLCipher
tutorial, as it will reference the dead packages.
**Fallback if the spike fails:** ship the MVP on an unencrypted local DB, record
it as a known gap in this file, and treat encryption as a hard prerequisite for
public release (not for personal use). Do **not** burn a week fighting native
build config for a single-user local app.
**Why it's a spike:** SQLCipher's Windows desktop story in Flutter is genuinely
uncertain. Planning confidently here would be planning wrong.

---

## The shape of the build

Stage 0 gets a window on screen. Stage 1 is the walking skeleton and is
**genuinely useful on its own** — if everything after it stalled, you'd still
have a working private journal. Stages 2–4 each add one visible capability to
that loop, ordered by how much they'd hurt to lose. Stage 4 (calendar) is last
of the features because it's the least certain, and its spike runs in Stage 0 so
you learn the bad news early rather than at the end.

---

## Stage 0 — Foundation

**Visible endpoint:** `flutter run -d windows` opens a Daybook window showing
today's date, and a green CI check appears on the commit.

**Step status:** 0.1 done · 0.2 **blocked on owner decision** · 0.3 done ·
0.4 done · 0.5 spike pending · **0.6 spike done — positive, see stage 4 gate** ·
0.7 done · 0.8 done.

### Step 0.1 — Scaffold the Flutter project

- **Goal:** a Flutter app that builds and runs on Windows, living at repo root
  alongside the existing `docs/`.
- **Where:** repo root. Run
  `flutter create --project-name daybook --platforms=windows,ios .`
- **Verify:** `flutter run -d windows` opens the default counter app window.
- **Fence:** do not add `--platforms=android,web,macos,linux`. Android is an
  explicit PRD non-goal; extra platform folders are dead weight that break CI
  for no benefit. Do not delete or move `docs/` or `README.md`.

### Step 0.2 — OneDrive exclusion check

- **Goal:** stop OneDrive from syncing build output, which causes file-lock
  build failures and multi-minute rebuilds.
- **Where:** repo is at `OneDrive/Documents/GitHub/daybook`. Mark `build/`,
  `.dart_tool/`, and `windows/flutter/ephemeral/` as "Free up space" / excluded
  in OneDrive, or move the repo outside OneDrive entirely (cleanest).
- **Verify:** run `flutter clean && flutter build windows` twice; the second
  build completes without any "file in use" or access-denied errors.
- **Fence:** don't add build artefacts to `.gitignore` expecting that to help —
  `.gitignore` controls git, not OneDrive. These are different problems.

### Step 0.3 — Dependencies and project structure

- **Goal:** the dependency set and folder layout every later step assumes.
- **Where:** `pubspec.yaml`, `lib/`.
  - Dependencies as actually installed: `flutter_riverpod` ^2.6.1, `drift`
    ^2.34.3, `drift_flutter` ^0.3.1, `uuid` ^4.6.0, `intl` ^0.20.3.
    `sqlite3_flutter_libs` and `path_provider` are **not** direct dependencies —
    `drift_flutter` brings both, and its `driftDatabase(name:)` helper resolves
    the database path itself, so declaring them would be redundant.
  - Dev dependencies: `drift_dev` ^2.34.5, `build_runner` ^2.15.1,
    `flutter_lints` ^6.0.0.
  - Pin the resolved versions — commit `pubspec.lock`.
  - Folders: `lib/data/` (drift database, DAOs), `lib/domain/` (models,
    repository interfaces), `lib/features/entry/`, `lib/features/history/`,
    `lib/ui/` (theme, shared widgets), `lib/platform/windows/`,
    `lib/platform/ios/`.
- **Verify:** `flutter pub get` resolves cleanly and `flutter analyze` reports
  no issues.
- **Fence:** no routing package, no HTTP client, no state-persistence package,
  no icon pack. Add dependencies at the step that actually needs them, with a
  one-line reason in the commit message.

### Step 0.4 — Schema, repository interfaces, in-memory fakes

- **Goal:** the data contract the whole app is written against.
- **Where:** `lib/data/database.dart`, `lib/domain/`.
  - Tables — both with `id TEXT` (UUID) primary key, `createdAt INTEGER`,
    `updatedAt INTEGER`, `deletedAt INTEGER NULL`:
    - `entries`: `day TEXT NOT NULL` (`YYYY-MM-DD`, unique index), `body TEXT`
    - `tasks`: `title TEXT NOT NULL`, `dueAt INTEGER NULL`,
      `completedAt INTEGER NULL`
  - Interfaces per the PRD sketch: `EntryRepository`, `TaskRepository`,
    `CalendarRepository`. Write in-memory fakes for all three.
  - Riverpod providers for each repository, overridable in tests.
- **Verify:** `dart run build_runner build` succeeds, then `flutter test` passes
  a test that writes and reads an entry through the in-memory fake.
  (`--delete-conflicting-outputs` has been removed from build_runner and is
  ignored if passed.)
- **Fence:** no calendar-event cache table yet — Stage 4 decides whether one is
  needed. No FTS5 table yet — Stage 2 decides. Don't implement any real
  platform repository here; fakes only.

### Step 0.5 — SPIKE: SQLCipher on Windows *(timeboxed: one session)*

- **Goal:** find out whether encryption-at-rest is achievable on Flutter Windows
  desktop before the schema has data in it. Answer the question; don't ship the
  feature.
- **Where:** a throwaway branch. Per the D5 correction, work from
  `package:sqlite3` 3.x's documented encryption support (**not**
  `sqlcipher_flutter_libs`, which is a dead no-op), plus `flutter_secure_storage`
  for the key. Open the drift database with a key pulled from secure storage.
- **Verify:** the app writes an entry, and opening the resulting `.sqlite` file
  with a plain SQLite tool fails or shows ciphertext — not readable prose. If it
  reads as plain text, encryption is not actually on.
- **Fence:** **stop after one session regardless of outcome.** If it works,
  record how in this file and schedule the real implementation into Stage 6. If
  it doesn't, take the D5 fallback, write the gap into this file's Known Gaps
  section, and move on. Do not let this block Stage 1.

### Step 0.6 — SPIKE: Windows calendar access *(timeboxed: one session)*

- **Goal:** learn now whether an unpackaged Flutter Windows app can read the
  user's calendar. This determines whether the product's headline feature exists
  on its primary platform.
- **Where:** throwaway branch or a minimal C++/WinRT probe. Target
  `Windows.ApplicationModel.Appointments.AppointmentStore`. The known risk: the
  `appointmentsSystem` capability is typically only grantable to packaged (MSIX)
  apps, so an unpackaged debug build may be refused outright.
- **Verify:** print the titles of today's appointments to the console from a
  Windows build. Anything less than real event data is a negative result.
- **Fence:** don't build UI, don't build the platform channel properly, don't
  attempt CalDAV or Google Calendar OAuth. This step answers exactly one
  question: *can we read the calendar at all, and does it require MSIX
  packaging?* Record the answer in this file under Stage 4.

### Step 0.7 — CI

- **Goal:** every push is checked automatically.
- **Where:** `.github/workflows/ci.yml`, running on `windows-latest`:
  `flutter pub get` → `flutter analyze` → `flutter test` →
  `flutter build windows`.
- **Verify:** push a commit; a green check appears on it in GitHub.
- **Fence:** no macOS job, no iOS build, no release/signing steps, no store
  upload. Those arrive in Stages 6 and 7.

### Step 0.8 — CLAUDE.md

- **Goal:** the conventions a fresh session needs, so it doesn't invent its own.
- **Where:** `CLAUDE.md` at repo root. Cover: Riverpod over Bloc, repository
  interfaces are the only route to platform code, `dart run build_runner build`
  after any drift schema change, `flutter test` before every commit, Windows-only
  builds for now, and a pointer to this plan.
- **Verify:** the file exists and states each of those; a new session reading
  only `CLAUDE.md` and this plan's handoff block could start work.
- **Fence:** keep it short. A CLAUDE.md nobody reads is worse than none.

---

## Stage 1 — Walking skeleton

**Visible endpoint:** open the app, type into today's page, close it, reopen it
— your words are still there, and you never pressed Save.

This stage alone is a usable private journal. Treat it as the real milestone.

### Step 1.1 — Theme and typography foundation

- **Goal:** the "paper and ink" feel established *before* any screen is built,
  so nothing needs re-skinning later.
- **Where:** `lib/ui/theme.dart`. Light and dark `ThemeData`; warm off-white
  paper light theme, low-glare dark theme; a serif or humanist family for the
  editor surface and a clean sans for UI chrome; one restrained accent colour;
  generous line height in the editor text style.
- **Verify:** run the app and toggle the Windows system theme between light and
  dark — the app follows, and text stays readable in both.
- **Fence:** no user-facing theme picker (post-MVP per the design brief), no
  custom font downloads unless bundled and licensed. Design tokens only — no
  screen work in this step.

### Step 1.2 — Daily entry screen with autosave

- **Goal:** the hero screen. Lands on today, full-height editor, autosaves.
- **Where:** `lib/features/entry/`. Date header at top (display only for now),
  `TextField` with `maxLines: null` filling the remaining space, autosave
  debounced ~800ms after the last keystroke via the `EntryRepository`, and a
  quiet "Saved" indicator that fades.
- **Verify:** run the app, type a sentence, wait two seconds, close the window,
  reopen — the sentence is there. Check the entry's `updatedAt` changed.
- **Fence:** no day navigation yet (Stage 2), no context strip yet (Stages 3–4),
  no formatting toolbar ever (D4), no word count. One screen, one job.

### Step 1.3 — Real drift repository behind the interface

- **Goal:** replace the in-memory fake with the SQLite-backed implementation, in
  the app only — tests keep using the fake.
- **Where:** `lib/data/`, plus the Riverpod provider override at app startup.
  Database file goes in the platform app-support directory via `path_provider`.
- **Verify:** `flutter test` still passes (fakes unaffected), and the manual
  restart check from Step 1.2 still works. Confirm the `.sqlite` file exists in
  the app-support directory.
- **Found while doing this — `drift_flutter` puts the database in the wrong
  place by default.** `driftDatabase(name:)` falls back to
  `getApplicationDocumentsDirectory()`, which on Windows is the user's Documents
  folder — frequently redirected into OneDrive, as it is on this machine. The
  journal was therefore being written to a cloud-synced folder, which breaks the
  local-first promise and risks SQLite corruption over a sync client. Fixed by
  passing `DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory)`;
  `path_provider` became a direct dependency as a result. **Check this again on
  iOS in stage 7** — the same default applies there, where Documents is
  user-visible in the Files app and backed up to iCloud.
- **Fence:** don't touch the repository *interface* in this step. If the
  interface needs to change to fit SQLite, that's a signal the Step 0.4 contract
  was wrong — fix it deliberately and note why here, don't quietly widen it.

---

## Stage 2 — Time travel

**Visible endpoint:** move between days with the keyboard, scroll a list of past
entries, and find one by typing a word from it.

### Step 2.1 — Day navigation

- **Goal:** prev/next day plus a jump-to-Today action.
- **Where:** the date header in `lib/features/entry/`. Arrow affordances,
  keyboard shortcuts (Ctrl+Left / Ctrl+Right / Ctrl+T), and loading or creating
  the entry for the target day.
- **Verify:** run the app; navigate back three days, type something, jump to
  Today, navigate back again — the text is on the right day, not smeared across
  days.
- **Fence:** no mini calendar picker yet — that's an open design question in the
  brief. No swipe gestures (that's a touch concern, deferred to Stage 7). Don't
  pre-create empty entry rows for days that were merely visited.

### Step 2.2 — History list

- **Goal:** reverse-chronological list of days that have content.
- **Where:** `lib/features/history/`. Rows show the date plus a preview snippet;
  tapping a row opens that day. On a desktop-width window this is a persistent
  left pane; below the breakpoint it's a separate screen.
- **Verify:** create entries on three different days, open history — all three
  appear newest-first with correct previews, and clicking one opens the right
  day.
- **Fence:** no infinite-scroll pagination until the list is actually slow. No
  grouping by month, no streak counters, no calendar heat map.

### Step 2.3 — Search

- **Goal:** find an entry by keyword or date.
- **Where:** a search field above the history list; a `LIKE`-based query on
  `body` in the entries DAO, with matched-text preview in results.
- **Verify:** create an entry containing a distinctive word, search that word —
  the entry appears with the match visible in the preview. Search a word that
  appears nowhere — an empty state renders, not a blank screen.
- **Fence:** `LIKE` is correct until proven slow. Do **not** add an FTS5 table
  before you have hundreds of entries and a measured delay. Note the upgrade
  path here and move on.

---

## Stage 3 — Tasks in the context strip

**Visible endpoint:** due and overdue tasks appear above today's entry, and
ticking one off stays ticked after restart.

### Step 3.1 — Context strip container

- **Goal:** the collapsible container that sits between the date header and the
  editor, and behaves well when it has nothing in it.
- **Where:** `lib/features/entry/`, shared widget in `lib/ui/`. Handles the
  empty state and collapse/expand; collapse state persists.
- **Verify:** run the app with no tasks — the strip is unobtrusive or shows a
  quiet empty state, and the editor doesn't jump when it collapses.
- **Fence:** container and empty state only. No event cards yet (Stage 4).
  Resolve the brief's "pinned vs auto-hide while typing" question by shipping
  *collapsible, defaults to open* — revisit after living with it.

### Step 3.2 — Local task store and inline completion

- **Goal:** the Windows `TaskRepository` implementation, and task rows that
  complete in place.
- **Where:** `lib/platform/windows/` (SQLite-backed `TaskRepository`),
  `lib/features/entry/` for the row widget. Rows show checkbox + title + due
  indicator; overdue styled distinctly from due-today.
- **Verify:** add a task due today and one dated yesterday — both appear, the
  overdue one looks different. Tick one, close the app, reopen — it's still
  ticked.
- **Fence:** no subtasks, no priorities, no tags, no recurring tasks, no
  reminders/notifications. The PRD scopes this as *due items visible and
  completable*, nothing more. Note in `TaskRepository`'s doc comment that on
  Windows this store is the source of truth and syncs with no OS task system.

### Step 3.3 — Task creation

- **Goal:** somewhere to actually add a task, since Windows has no OS task
  source to import from.
- **Where:** an inline "add task" affordance at the bottom of the strip.
- **Verify:** type a title, press Enter, the task appears in the strip and
  survives restart.
- **Fence:** one text field and an optional due date. No separate task-management
  screen — Daybook is a journal that shows tasks, not a to-do app.

---

## Stage 4 — Calendar

**Visible endpoint:** today's real calendar events render above the entry.

> **Gate:** this stage's shape is decided by the Step 0.6 spike result. Record
> the outcome here before starting:
>
> **Spike outcome (2026-08-03): POSITIVE, with one unresolved caveat.**
>
> Probed from an **unpackaged** process (PowerShell, no package identity — the
> same condition as a `flutter run` debug build) on Windows 11 25H2:
>
> - `AppointmentManager.RequestStoreAsync(AllCalendarsReadOnly)` **succeeded**.
>   No package-identity error, no blocking consent dialog, no capability
>   rejection. **This was the feared blocker and it did not materialise — MSIX
>   packaging is not a prerequisite for read access.**
> - `FindAppointmentCalendarsAsync()` returned **1 calendar**: display name
>   "Calendar", source "Microsoft account", with `OtherAppReadAccess = Full`.
> - `FindAppointmentsAsync()` executed without error but returned **0
>   appointments** across a ±30-day window — that calendar simply has no events
>   in range.
>
> **Caveat — event content is unproven.** Reading zero events from an empty
> calendar does not prove events would flow if they existed. The machine has
> both `microsoft.windowscommunicationsapps` (the legacy Mail & Calendar stack,
> which is what registered the calendar above) and `Microsoft.OutlookForWindows`
> (the new Outlook) installed. The new Outlook is not known to publish into the
> legacy WinRT `AppointmentStore`, so a user whose real calendar lives in new
> Outlook — or in Google Calendar — may see an empty strip even though the API
> works perfectly.
>
> **Close the caveat before step 4.1** by adding one test event to the Windows
> Calendar that appears under the "Microsoft account" source, then re-running
> the probe. If the event is returned, proceed with 4.1 as written. If it is
> not, the real risk is *data source coverage*, not API access — and the
> fallback becomes an explicit calendar-account setup step in onboarding rather
> than dropping the feature.

### Step 4.1 — Windows calendar platform channel

- **Goal:** a real `CalendarRepository` for Windows returning today's events.
- **Where:** `windows/runner/` (C++/WinRT), `lib/platform/windows/`. Permission
  handling via `ensurePermission()`; the app must stay fully usable when access
  is denied.
- **Verify:** with a real event in the Windows Calendar app, run Daybook — the
  event appears with the correct time and title. Then deny/revoke access — the
  strip degrades gracefully with no error dialog and no broken area.
- **Fence:** read-only, today only, no recurrence expansion beyond what the API
  hands back, no event creation or editing. If this requires MSIX packaging,
  stop and reorder — do Stage 6 first, then return.
- **If the spike came back negative:** skip 4.1 entirely. Reframe the context
  strip around tasks alone, update the PRD to say calendar is iOS-only in v1,
  and record that decision here. This is a legitimate outcome, not a failure —
  Stages 1–3 still deliver a working product.

### Step 4.2 — Event cards

- **Goal:** events rendered in the context strip alongside tasks.
- **Where:** `lib/ui/` event card widget — time, title, calendar-colour dot.
- **Verify:** a day with several events renders them in start-time order,
  all-day events included and visually distinguished.
- **Fence:** no event detail view, no tapping through to the calendar app, no
  editing. Read-only per the PRD.

---

## Stage 5 — Polish

**Visible endpoint:** the app handles every awkward case without looking broken,
and works at 200% text scaling.

### Step 5.1 — States sweep

- **Goal:** close out the design brief's "states to not forget" list.
- **Where:** across all features. Empty entry (an inviting prompt, not a void),
  no history yet, no search results, permission denied, loading, just-saved,
  very long entries, a day with fifteen events.
- **Verify:** walk each state manually against the brief's Section 8 list and
  tick them off here. Screenshot the awkward ones.
- **Fence:** no new features. If a state reveals a missing capability, note it
  as post-MVP rather than building it now.

### Step 5.2 — Accessibility and text scaling

- **Goal:** the layouts survive large text and a keyboard-only user.
- **Where:** across all screens. Semantic labels on event cards, task
  checkboxes, and date navigation; full keyboard traversal; contrast checked in
  both themes, especially checkbox states.
- **Verify:** set Windows text scaling to 200% — nothing overflows or clips.
  Navigate the whole app with Tab and arrow keys only, no mouse.
- **Fence:** don't refactor widget structure for elegance while you're in here.
  Fix accessibility defects only.

---

## Stage 6 — Ship to self

**Visible endpoint:** Daybook is installed on your machine like a real app, and
you're journaling in it daily.

### Step 6.1 — MSIX packaging

- **Goal:** an installable Windows package rather than a `flutter run` session.
- **Where:** `msix` package configuration, app icon, display name, version.
  Self-signed is fine for personal install; keep the config ready for a real
  certificate later.
- **Verify:** build the package, install it, launch from the Start menu, write
  an entry, restart the machine, reopen — data intact.
- **Fence:** no Microsoft Store submission (PRD Q3 defers it), no auto-update
  mechanism, no telemetry — "no third-party analytics" is a product promise.

### Step 6.2 — Encryption at rest *(if Step 0.5 succeeded)*

- **Goal:** land the encryption the spike proved viable.
- **Where:** `lib/data/`, plus key generation and storage on first run.
- **Verify:** the database file is not readable as plain text, and an existing
  unencrypted database migrates without data loss.
- **Fence:** if Step 0.5 failed, skip this and confirm the Known Gap below stays
  recorded. Do not attempt a second unbounded encryption effort.

### Step 6.3 — Dogfood for two weeks

- **Goal:** find out what's actually wrong with it by using it.
- **Where:** real life.
- **Verify:** you've written entries on most days for two weeks. Keep a list at
  the bottom of this file of every friction point you hit.
- **Fence:** don't fix things as you notice them — write them down and batch the
  decision. Two weeks of notes is data; two weeks of reactive patches is churn.

---

## Stage 7 — iOS enablement *(gated on Mac access)*

**Gate:** do not start any step in this stage without a Mac (physical or cloud)
you can build and debug on. Writing iOS code you cannot run is the failure mode
this whole plan is arranged to avoid.

- **7.1** — Build the existing codebase for iOS; fix what breaks. *Verify:* the
  app runs in the simulator and the Stage 1 restart check passes on device.
- **7.2** — EventKit `CalendarRepository` via platform channel, with permission
  flow. *Verify:* a real iPhone calendar event renders in the context strip.
- **7.3** — EventKit reminders as the iOS `TaskRepository`. *Verify:* a Reminders
  app item appears and completing it in Daybook reflects back in Reminders.
- **7.4** — iPad two-pane layout at the expanded breakpoint; touch day-swipe
  navigation. *Verify:* rotate an iPad between orientations and split-view sizes
  without layout breakage.
- **7.5** — Add a macOS CI job building the iOS target. *Verify:* green check.

---

## Risks and tripwires

| Risk | Early warning | Fallback |
| --- | --- | --- |
| ~~**Windows calendar access is blocked for unpackaged apps**~~ — **retired 2026-08-03**: the 0.6 spike showed an unpackaged process gets the store and read access with no MSIX requirement | — | — |
| **Windows calendar has no usable data source** — the surviving half of the risk above: API works, but the user's real calendar may live in new Outlook or Google and never reach the WinRT store | Add one test event under the "Microsoft account" calendar and re-run the 0.6 probe, before starting step 4.1 | Treat it as onboarding, not architecture: prompt the user to connect a calendar the store can see. Only drop the feature if no data source can be made to work |
| **SQLCipher doesn't work on Flutter Windows desktop** | Step 0.5 spike, timeboxed to one session | Unencrypted local DB for personal use; encryption becomes a hard gate for public release, recorded as a Known Gap |
| **OneDrive corrupts or locks build output** | Step 0.2 — mysterious "file in use" or access-denied build failures | Move the repo outside OneDrive; it's the clean fix |
| **iOS code rots unverified** | Any commit adding real logic under `lib/platform/ios/` before Stage 7 | Keep iOS implementations as `UnimplementedError` stubs. A stub is honest; speculative EventKit code is a lie about your test coverage |
| **Scope creep into rich text, sync, or themes** | A step touching files outside its stated "Where" | The fence line on every step exists for this. Add the idea to the PRD's stretch list and carry on |
| **The repository abstraction leaks platform quirks** (PRD's own top risk) | A `CalendarEvent` or `Task` field that only one platform can populate | Fix it at the interface, not in the UI. If the UI needs `if (Platform.isWindows)`, the abstraction has already failed |

---

## Known gaps

*Record anything shipped deliberately incomplete, so it isn't rediscovered as a
surprise later.*

- **Encryption at rest is not implemented.** The database is plain SQLite. The
  route assumed in D5 turned out to be dead (see the D5 correction), so the
  spike hasn't run yet. Acceptable for personal use; a hard gate before any
  public release.
- **Riverpod held at 2.6.1** because 3.x cannot resolve alongside `drift_dev`.
  Not a defect, but recheck at stage 5.
- **Calendar event content is unproven on Windows** — API access is confirmed
  working, but no real event has ever been read. See the stage 4 gate for the
  30-second check that closes this.
- **`build/` and `.dart_tool/` still sync to OneDrive** — step 0.2 is unresolved
  pending the owner's call on moving the repo.
- **A stray `C:\Users\aayus\OneDrive\Documents\daybook.sqlite` exists** from
  before the database-location fix. It was created by early dev runs and holds
  no entries. Safe to delete; left in place because it is outside the repo.

---

## Dogfood friction log

*Stage 6.3. One line per annoyance. Don't fix on sight — batch them.*

- _(none yet)_
