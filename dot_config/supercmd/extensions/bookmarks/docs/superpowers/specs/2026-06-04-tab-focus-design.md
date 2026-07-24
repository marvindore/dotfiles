# Tab Focus Before Open — Design Spec

**Date:** 2026-06-04
**Status:** Approved

## Problem

The bookmarks extension always opens a new browser tab for a bookmark, even if that URL is already open in Chrome. The desired behavior is to switch to the existing tab instead of duplicating it.

## Scope

- Platform: macOS (SuperCmd is macOS-only)
- Browser: Google Chrome
- File changed: `src/index.tsx` only

## Data Flow

1. User selects a bookmark and activates the action (Enter / click).
2. `focusOrOpenTab(url)` is called.
3. An AppleScript is executed via `execSync` that iterates all Chrome windows and tabs.
4. If a tab whose `URL` exactly matches the bookmark URL is found:
   - That tab is made active within its window.
   - The window is brought to the front (`set index of w to 1`).
   - Chrome is activated (`activate`).
   - The script returns `true`.
5. If no match is found, the script returns `false`.
6. On `false` (or any thrown exception): `open(url)` from `@raycast/api` opens the URL in a new tab — identical to current behavior.

## URL Matching

Exact string equality (`URL of t is "<url>"`). Fuzzy matching is intentionally excluded — bookmarks are canonical URLs and fuzzy matching risks focusing the wrong tab.

## Code Structure

All changes are in `src/index.tsx`.

```
import { execSync } from "child_process";
import { open, ... } from "@raycast/api";

function focusOrOpenTab(url: string): boolean {
  // Escape single quotes: replacement is the 4-char POSIX sequence '\''
  // In a JS double-quoted string literal that is: "'\\''
  const safeUrl = url.replace(/'/g, "'\\''");
  const script = `
    tell application "Google Chrome"
      repeat with w in windows
        set i to 1
        repeat with t in tabs of w
          if URL of t is "${safeUrl}" then
            set active tab index of w to i
            set index of w to 1
            activate
            return true
          end if
          set i to i + 1
        end repeat
      end repeat
      return false
    end tell
  `;
  const result = execSync(`osascript -e '${script}'`).toString().trim();
  return result === "true";
}
```

The `<Action.OpenInBrowser>` is replaced with:

```tsx
<Action
  title="Open in Browser"
  onAction={() => {
    try {
      if (!focusOrOpenTab(bookmark.url)) {
        open(bookmark.url);
      }
    } catch {
      open(bookmark.url);
    }
  }}
/>
```

## Error Handling

| Scenario | Behavior |
|---|---|
| Chrome not running | `execSync` throws → caught → `open(url)` |
| Automation permission denied | `execSync` throws → caught → `open(url)` |
| No matching tab found | Script returns `false` → `open(url)` |
| URL contains single quotes | Escaped with the 4-char POSIX sequence `'\''` before injection |
| URL contains double quotes | RFC 3986 forbids unencoded `"` in URLs; not handled — use `%22` in `bookmarks.json` |
| Multiple tabs with same URL | First match (window order, tab order) is focused |
| Chrome running, no windows | Loop runs 0 times, returns `false` → `open(url)` |
| No matching tab found | Falls back to `open(url)` which opens in the system default browser (may differ from Chrome) |

All fallback paths open the URL in a browser — identical in outcome to current behavior. No toast or error UI is shown.
