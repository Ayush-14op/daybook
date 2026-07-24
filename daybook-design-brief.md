# Daybook — UI/UX Design Brief

A design-focused summary of the Daybook project, for driving UI work. For full
product scope see the PRD (`docs/daybook-prd.md`).

---

## 1. In one line

A private, calm daily journal where each day is one page — your writing, with
today's calendar events and due reminders shown inline above it. Cross-platform
(iPhone, iPad, Windows), local-first, no ads, no analytics. Inspired by
Parchment.

## 2. Who it's for / the feeling

- A personal, quiet space — closer to a paper journal than a productivity app.
- **Design mood:** calm, warm, distraction-free, typography-forward. The writing
  is the hero; chrome recedes. Think "paper and ink," not "dashboard."
- Emotional goal: opening the app should feel inviting and low-pressure, not
  like a task list nagging you.

## 3. Platforms & form factors (design adaptively, not one-size)

| Surface | Layout intent |
| --- | --- |
| **iPhone** | Single-column, thumb-reachable. Bottom nav or minimal top bar. |
| **iPad** | Two-pane: entry list / history on the left, day page on the right. Takes advantage of width. |
| **Windows desktop** | Two- or three-pane desktop layout; keyboard-first (shortcuts for new day, search, navigate days). Mouse + trackpad. |

Design the **iPhone (compact)** and **iPad/desktop (expanded)** layouts as the
two anchor breakpoints; the same components reflow between them.

## 4. Screens to design (MVP)

Priority order — #1 is where users live.

1. **Daily entry (the hero screen)**
   - Date header with prev/next day navigation ("Today" as home).
   - **Context strip** above the editor: today's calendar events + due/overdue
     reminders. Compact, glanceable, collapsible.
   - **Editor:** large, comfortable writing area. Autosave — show a subtle
     "saved" state, no Save button.
2. **History / entry list** — reverse-chronological list of past days; each row
   shows date + a preview snippet. Entry point to search.
3. **Search** — by date and keyword; results as entry rows with matched-text
   preview.
4. **Onboarding / permissions** — first-run request for calendar + reminders
   access, with a graceful "not now / denied" path (app must be fully usable
   without granting).
5. **Settings** — intentionally minimal (theme, text size, about, later: sync).

## 5. Key components (build these as a small system)

- **Date header** — current date, prev/next affordance, quick jump to Today.
- **Event card** — time, title, maybe calendar-color dot. Read-only in MVP.
- **Reminder/task row** — checkbox + title + due indicator; tapping the checkbox
  marks complete inline (needs a satisfying done state). Overdue styled
  distinctly.
- **Context strip container** — groups events + reminders above the editor;
  handles empty state ("No events today") and collapse/expand.
- **Editor surface** — generous line height, comfortable measure, calm caret.
- **Entry list row** — date + preview snippet + (optional) has-content indicator.
- **Search bar** + result row.
- **Autosave indicator** — quiet, non-modal.

## 6. Core flows to storyboard

1. **Open → land on Today** → skim events/reminders → start writing → autosave.
2. **Navigate days** — swipe (touch) / arrows or shortcuts (desktop) between days.
3. **Complete a reminder** from the context strip without leaving the page.
4. **Find a past entry** — open history → search keyword → open result.
5. **First run** — permission request → land on Today (works even if denied).

## 7. Visual direction (starting points — yours to finalize)

- **Light + dark** both required. Lean warm/paper for light; soft, low-glare for
  dark (journaling often happens at night).
- **Typography:** a readable serif or humanist type for the writing area sells
  the "journal" feel; keep UI labels in a clean sans for legibility. Respect
  Dynamic Type (iOS) and system text scaling (Windows).
- **Color:** restrained. One quiet accent; let calendar-color dots be the main
  pops of color. Avoid heavy saturated UI.
- **Density:** generous whitespace, especially around the editor. Context strip
  is compact but not cramped.

## 8. States to not forget

- **Empty:** no events, no reminders, blank entry (invite to write), no history
  yet, no search results.
- **Permission denied:** calendar/reminders unavailable — hide the strip
  gracefully or show a subtle "connect calendar" prompt, never a broken area.
- **Overdue** reminders vs due-today.
- **Loading / just-saved** micro-states.
- **Long content** — very long entries, many events in a day.

## 9. Accessibility

- Dynamic Type / system text scaling; layouts must survive large text.
- Sufficient contrast in both themes (checkbox states especially).
- Full keyboard navigation + shortcuts on desktop.
- Screen-reader labels for event cards, reminder checkboxes, date nav.

## 10. Out of scope for v1 UI (don't design yet)

Handwriting/Apple Pencil, widgets, PDF/Markdown export, custom themes/fonts,
Spotlight — all post-MVP. Cloud sync UI (accounts) is v1.1, not MVP; you can
leave a placeholder in Settings but don't build the flow now.

## 11. Open design questions

- Day navigation: swipe between days, a mini calendar picker, or both?
- Should the context strip be pinned, collapsible, or auto-hide while typing?
- iPad/desktop: is history a persistent sidebar or a toggle?
- How prominent should reminders be vs. calendar events — equal weight, or
  reminders subordinate?
- Where does "new/older entry" navigation live on desktop — top bar, sidebar, or
  keyboard-only?
