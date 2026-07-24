# URL Builder Extension — Design Spec
**Date:** 2026-06-09

## Overview

A SuperCmd extension that opens a list of URL templates, prompts for labeled variable parameters, builds the final URL by substituting values, and opens it in the browser. Replaces the non-functional `splunk-search.py` script command. Generic — not Splunk-specific.

## Data Model

Templates are stored in `url-templates.json` alongside the extension, read at runtime (not bundled). This means adding or editing templates requires no rebuild.

### Schema

```json
[
  {
    "name": "string — display name shown in the list",
    "description": "string — subtitle shown in the list",
    "url": "string — URL with {0}, {1}, {2}... placeholders",
    "params": [
      { "label": "string — field label in the form", "placeholder": "string — hint text" }
    ]
  }
]
```

`{0}` maps to `params[0]`, `{1}` to `params[1]`, and so on. Values are substituted with `encodeURIComponent` before insertion. `params` may be an empty array (see Zero-param templates below).

### Versioned Files

- `url-templates.json` — machine-specific, not version controlled
- `url-templates.example.json` — versioned, contains two generic entries demonstrating the schema:
  1. A single-param example (e.g. a GitHub repo search URL with `{0}` as the search term)
  2. A two-param example (e.g. a generic query URL with `{0}` and `{1}`)
  No real work-specific URLs.

## UI Flow

1. User triggers the command via hotkey or SuperCmd search
2. **List view** — shows all templates from `url-templates.json` with name as title and description as subtitle
3. User selects a template:
   - **Zero params** — URL opened immediately, no Form shown
   - **One or more params** — Form view shown
4. **Form view** — one `Form.TextField` per entry in `params`, with `title` and `placeholder` set from the template. Inline `error` prop used for validation feedback.
5. User fills in values and submits
6. Validation: any empty field sets an inline error on that field and blocks submission
7. URL is built: each `{N}` placeholder replaced with `encodeURIComponent(value)`
8. URL opened in browser via a shell-safe `openUrl` helper (see below)
9. View navigation is state-based (`useState`) — no `useNavigation` dependency

## openUrl Helper

All URL opening goes through a single `openUrl(url: string): void` function that:
1. Tries `osascript` to focus an existing Chrome tab with that URL
2. Falls back to `execSync(\`open "${url.replace(/"/g, '\\"')}"\`)` if no tab found or osascript fails

The double-quote escaping in the fallback prevents command injection from user-entered values. This is identical to the pattern in the bookmarks extension.

## File Structure

```
extensions/url-builder/
  src/
    index.tsx             — main extension (List + Form, state-based navigation)
  package.json            — manifest: name "url-builder", command name "index", title "Build Url"
  tsconfig.json           — TypeScript config (identical to bookmarks extension)
  url-templates.json      — runtime templates, machine-specific, not versioned
  url-templates.example.json  — versioned schema reference, two generic examples
```

The command `name` slug is `"index"` (matching `src/index.tsx`), producing the settings key `ext-url-builder-index` and `extensionCommandArguments` key `"url-builder/index"`.

## SuperCmd Integration

- `"url-builder"` added to `installedExtensions` in `settings.json`
- A direct hotkey assigned in `commandHotkeys` for `ext-url-builder-index`
- A new separate LaunchD plist `com.supercmd.url-builder-watcher.plist` created (parallel to `com.supercmd.bookmarks-watcher.plist`) — watches `extensions/url-builder/src` and runs `rm -f "{{ .chezmoi.homeDir }}/Library/Application Support/SuperCmd/extensions/url-builder/.sc-build/index.js"`. `ProgramArguments` uses the `/bin/sh -c` wrapper pattern identical to the bookmarks plist. Added to chezmoi with `{{ .chezmoi.homeDir }}` templating.
- `run_once_load_launchagents.sh` updated to add an `unload`/`load` pair for `com.supercmd.url-builder-watcher.plist` alongside the existing bookmarks entry. Both entries must be present — changing the file content triggers chezmoi to re-run the script on next `chezmoi apply`.
- Hotkey for `ext-url-builder-index`: `Command+Shift+U`

## Cleanup

- Delete `script-commands/splunk-search.py`
- Remove both stale script IDs from `recentCommands` and `recentCommandLaunchCounts` in `settings.json`: `script-f56493bd41afafda` (Splunk Search) and `script-7604413c267868d8` (unknown orphan)
- Migrate the existing Splunk query into `url-templates.json` as **two entries**: one with namespace (params: SPL query + namespace) and one without (params: SPL query only), since `{N}` substitution cannot conditionally include a URL segment. Time-range dropdown is intentionally dropped — hardcode a sensible default directly in the URL template.

## Implementation Notes

- **chezmoi settings.json drift**: the chezmoi source at `~/.local/share/chezmoi/.../settings.json` is missing `"ext-bookmarks-index": "Command+Shift+B"` in `commandHotkeys` (pre-existing drift). When writing the url-builder hotkey, treat the **live** `settings.json` as authoritative and ensure both hotkeys are present in the chezmoi copy.

## Error Handling

- Missing or malformed `url-templates.json` → show empty list, no crash
- Empty form field on submit → set inline `error` on the offending field(s), block submission
- Zero-param template → skip Form, open URL immediately
