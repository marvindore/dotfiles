# Meeting Popup — Design Spec

**Date:** 2026-04-30
**Hotkey:** Ctrl+Shift+M
**Status:** Approved

---

## Overview

A floating webview popup that displays all remaining calendar events for the current day. Triggered by Ctrl+Shift+M, styled to match the existing scratchpad (Catppuccin Mocha, JetBrains Mono). Meetings are listed in an accordion; clicking a meeting expands it to reveal details and a join button. Clicking "Join Meeting" opens the link in the browser and closes the popup.

---

## Module Structure

- **New file:** `calendar.lua` — self-contained module, same pattern as `scratchpad.lua`
- **`init.lua` changes:**
  - Add `local Calendar = require("calendar")`
  - Add `hs.hotkey.bind({"ctrl","shift"}, "m", Calendar.toggle)`
- **No new dependencies** — uses only `hs.osascript`, `hs.webview`, `hs.task`, `hs.timer`

---

## Data Fetching

### Source
AppleScript via `hs.osascript.applescript()` — queries all calendars in Calendar.app (which is synced with Outlook). All calendars are included; no filtering.

### Timing
- **Eager fetch at startup** — called once when the module loads, result cached in a Lua table
- **Refresh timer** — `hs.timer.doEvery(300, ...)` refreshes the cache every 5 minutes in the background
- **On-toggle refresh** — always uses cached data; the background timer is the sole refresh mechanism, so the popup appears immediately with no blocking fetch

### Event filtering & sorting
- Include events whose **end time is after the current time** (remaining meetings)
- Sort ascending by start time
- Include all-day events only if they have a join link

### Cached event schema
Each entry is a Lua table:
```lua
{
  title       = string,
  startTime   = string,   -- "2:00 PM"
  endTime     = string,   -- "2:30 PM"
  calendarName= string,
  organizer   = string,   -- may be empty
  notes       = string,   -- raw description/notes field
  joinUrl     = string|nil,
  linkType    = "teams"|"zoom"|"meet"|"webex"|"goto"|"link"|nil,
  isNow       = bool,     -- start <= now < end
}
```

---

## Meeting Link Detection

Detection runs at fetch time and is stored in `joinUrl` + `linkType`.

**Order of precedence:**
1. Event's `url` field (Outlook/Google Calendar usually populates this directly)
2. Pattern scan of the event's `description`/`notes` field

**Patterns (first match wins):**

| Service      | `linkType` | URL pattern |
|---|---|---|
| Microsoft Teams | `"teams"` | `teams.microsoft.com/l/meetup-join` |
| Zoom            | `"zoom"`  | `*.zoom.us/j/` |
| Google Meet     | `"meet"`  | `meet.google.com/` |
| Webex           | `"webex"` | `*.webex.com/` |
| GoTo Meeting    | `"goto"`  | `gotomeeting.com/join/` |
| Other/unknown   | `"link"`  | any `https://` URL in the event's `url` field only (not notes) |

The notes scan **only** matches recognized service patterns (Teams through GoTo). If a URL in notes doesn't match any recognized pattern it is ignored. The `"link"` catch-all only fires when the event's `url` field is populated but doesn't match a recognized service.

If no URL is found anywhere, `joinUrl` and `linkType` are `nil` — the meeting row still appears but without a badge or join button.

---

## Window Behaviour

Follows the same AeroSpace-compatible pattern as `scratchpad.lua`:

- Window created once at module load (off-screen, `alpha(0)`) — never `hide()`/`show()` after that
- Toggle: `alpha(0)` → `alpha(1)` to avoid triggering AeroSpace re-detection
- Before reveal: `aeroMoveAndFloat()` async-moves the window to the currently focused workspace and sets `layout floating`; 300ms fallback timer guarantees reveal even if AeroSpace is down
- Window title: `"meetings"` — requires an `on-window-detected` rule in `aerospace.toml` (same as the existing `scratchpad` rule)
- Size: ~40% of screen width, ~40% of screen height, centered on the monitor containing the cursor
- `prevWindow` is captured on show and restored on hide; if `prevWindow` is `nil` or no longer visible when hiding, focus restoration is silently skipped

---

## UI

### Chrome
- Title bar (dark strip): `◆ meetings · today` on the left, `N remaining` count on the right
- Catppuccin Mocha palette, JetBrains Mono font, 13px base size
- Thin scrollbar if meeting list overflows

### Meeting Row (collapsed)
```
[start]    Title of Meeting      [badge] [now?]   ›
[end  ]    Calendar Name
```
- `start` / `end` in 12-hour format, right-aligned in a fixed-width column
- `›` chevron on the right; rotates 90° when expanded
- Hovering the row highlights it with a subtle accent tint

### Badges
| Badge | Style |
|---|---|
| `Teams` | Purple tinted pill |
| `Zoom`  | Blue tinted pill |
| `Meet`  | Green tinted pill |
| `Webex` | Teal tinted pill |
| `GoTo`  | Grey tinted pill |
| `Link`  | Grey tinted pill |
| `● now` | Green tinted pill, shown when `isNow = true` |

### Expanded Detail Panel
Appears below the row header, indented to align with the text column:
```
Organizer   Alex Chen
Calendar    Work
Link        teams.microsoft.com/l/meetup-join/…  (truncated)
[Join Meeting ↗]
```
- Only one row can be expanded at a time (clicking another row collapses the open one)
- "Join Meeting ↗" button: accent-colored, opens `joinUrl` in the default browser via `hs.urlevent.openURL()`, then calls `Calendar.hide()`

### Empty State
When no meetings remain:
```
    ✓
You're done for today
No more meetings remaining
```
Centered, muted text.

### Keyboard
- `Escape` — hides the popup, restores focus to `prevWindow`
- Ctrl+Shift+M — toggle (hide if visible, show if hidden)

---

## AeroSpace Integration

Add to `aerospace.toml` alongside the existing scratchpad rule:
```toml
[[on-window-detected]]
if.app-name-regex-substring = 'Hammerspoon'
if.window-title-regex-substring = 'meetings'
run = 'layout floating'
```

---

## Out of Scope

- Declining / accepting meeting invites
- Creating new events
- Notifications / reminders
- Showing past meetings
- Per-calendar colour coding
