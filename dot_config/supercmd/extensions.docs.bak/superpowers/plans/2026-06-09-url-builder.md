# URL Builder Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SuperCmd extension that shows a list of URL templates from a runtime-read JSON file, collects labeled parameters, substitutes `{0}`, `{1}`, etc. into the URL, and opens it in Chrome — replacing the non-functional `splunk-search.py` script command.

**Architecture:** TypeScript/React extension using the proven bookmarks pattern: `process.env.HOME`-based path for runtime JSON reads, `useState` for List→Form navigation (no `useNavigation` dependency), and `execSync('open ...')` for URL launching. SuperCmd builds extensions into `.sc-build/` — a launchd watcher invalidates the cache whenever `src/` changes.

**Tech Stack:** TypeScript, React, `@raycast/api` (SuperCmd's Raycast-compatible shim), Node.js `fs`/`child_process`/`path` built-ins, launchd for file watching, chezmoi for dotfile management.

**Spec:** `docs/superpowers/specs/2026-06-09-url-builder-design.md`

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `extensions/url-builder/package.json` | Extension manifest |
| Create | `extensions/url-builder/tsconfig.json` | TypeScript config (identical to bookmarks) |
| Create | `extensions/url-builder/src/index.tsx` | Full extension: List, Form, openUrl, URL builder |
| Create | `extensions/url-builder/url-templates.json` | Machine-specific templates (not versioned) |
| Create | `extensions/url-builder/url-templates.example.json` | Versioned schema reference |
| Create | `~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist` | launchd watcher |
| Create | `~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist.tmpl` | chezmoi template for plist |
| Modify | `~/Library/Application Support/SuperCmd/settings.json` | Add extension, fix hotkeys, remove stale IDs |
| Modify | `~/.local/share/chezmoi/run_once_load_launchagents.sh` | Add url-builder plist load pair |
| Delete | `/Users/marvin.dore/Library/Application Support/SuperCmd/script-commands/splunk-search.py` | Replaced by extension |

**Note:** `extensions/` is NOT a git repository. All git operations are in `~/.local/share/chezmoi`. Do not run `git` commands from within `extensions/url-builder/`.

---

## Task 1: Scaffold the extension directory

**Files:**
- Create: `extensions/url-builder/package.json`
- Create: `extensions/url-builder/tsconfig.json`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/src"
```

- [ ] **Step 2: Create package.json**

Create `/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/package.json`:

```json
{
  "$schema": "https://www.raycast.com/schemas/extension.json",
  "name": "url-builder",
  "title": "URL Builder",
  "description": "Build and open URLs from templates with variable parameters",
  "icon": "link.png",
  "author": "marvin.dore",
  "categories": ["Productivity"],
  "license": "MIT",
  "commands": [
    {
      "name": "index",
      "title": "Build Url",
      "subtitle": "URL Builder",
      "description": "Select a URL template, fill in parameters, and open it",
      "mode": "view"
    }
  ],
  "dependencies": {
    "@raycast/api": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.4.5"
  },
  "scripts": {
    "build": "ray build -e dist -o dist && rm -f .sc-build/index.js",
    "typecheck": "tsc --noEmit"
  }
}
```

- [ ] **Step 3: Create tsconfig.json (identical to bookmarks)**

Create `/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/tsconfig.json`:

```json
{
  "$schema": "http://json.schemastore.org/tsconfig",
  "include": ["src"],
  "compilerOptions": {
    "lib": ["ES2020"],
    "module": "CommonJS",
    "target": "ES2020",
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

- [ ] **Step 4: Install dependencies**

```bash
cd "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder" && npm install
```

Expected: `added 80 packages` (same as bookmarks — same deps).

---

## Task 2: Create template data files

**Files:**
- Create: `extensions/url-builder/url-templates.example.json`
- Create: `extensions/url-builder/url-templates.json`

- [ ] **Step 1: Create url-templates.example.json**

Create `/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/url-templates.example.json`:

```json
[
  {
    "name": "GitHub Repository Search",
    "description": "Search for a repository on GitHub",
    "url": "https://github.com/search?q={0}&type=repositories",
    "params": [
      { "label": "Search Query", "placeholder": "e.g. raycast extension" }
    ]
  },
  {
    "name": "Google Maps Directions",
    "description": "Get directions between two locations",
    "url": "https://www.google.com/maps/dir/{0}/{1}",
    "params": [
      { "label": "From", "placeholder": "e.g. New York, NY" },
      { "label": "To", "placeholder": "e.g. Boston, MA" }
    ]
  }
]
```

- [ ] **Step 2: Create url-templates.json with two Splunk entries**

The spec requires two entries to cover the with-namespace and without-namespace cases from the old `splunk-search.py`. Create `/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/url-templates.json`:

```json
[
  {
    "name": "Agent Session Logs",
    "description": "Find CreateAgentSessionAction logs for a specific agent",
    "url": "https://ukg.splunkcloud.com/en-GB/app/search/search?q=search%20index%3D%22ukg_suitex-search_app%22%20service_name%3D%22suitex-search-conversation-assistant%22%20log%3D%22*CreateAgentSessionAction*%22%20log%3D%22*{0}*%22&display.page.search.mode=smart&dispatch.sample_ratio=1&workload_pool=standard_perf&earliest=-4m&latest=now",
    "params": [
      { "label": "Agent Name", "placeholder": "e.g. PayrollChecksAgent" }
    ]
  },
  {
    "name": "Agent Session Logs (with namespace)",
    "description": "Find CreateAgentSessionAction logs scoped to a namespace",
    "url": "https://ukg.splunkcloud.com/en-GB/app/search/search?q=search%20namespace%3D%22{1}%22%20index%3D%22ukg_suitex-search_app%22%20service_name%3D%22suitex-search-conversation-assistant%22%20log%3D%22*CreateAgentSessionAction*%22%20log%3D%22*{0}*%22&display.page.search.mode=smart&dispatch.sample_ratio=1&workload_pool=standard_perf&earliest=-4m&latest=now",
    "params": [
      { "label": "Agent Name", "placeholder": "e.g. PayrollChecksAgent" },
      { "label": "Namespace", "placeholder": "e.g. payroll" }
    ]
  }
]
```

Note: `url-templates.json` is machine-specific and will NOT be added to chezmoi.

---

## Task 3: Implement the extension

**Files:**
- Create: `extensions/url-builder/src/index.tsx`

- [ ] **Step 1: Create src/index.tsx**

Create `/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/src/index.tsx`:

```tsx
import { execSync } from "child_process";
import { readFileSync } from "fs";
import { join } from "path";
import { Action, ActionPanel, Form, List } from "@raycast/api";
import { useState } from "react";

type Param = { label: string; placeholder: string };
type Template = { name: string; description: string; url: string; params: Param[] };

function openUrl(url: string): void {
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
  try {
    const focused = execSync(`osascript -e '${script}'`, { timeout: 5000 }).toString().trim() === "true";
    if (!focused) {
      execSync(`open "${safeUrl}"`);
    }
  } catch {
    execSync(`open "${url.replace(/"/g, '\\"')}"`);
  }
}

function buildUrl(template: Template, values: Record<string, string>): string {
  return template.url.replace(/\{(\d+)\}/g, (_, i) => encodeURIComponent(values[`param_${i}`] ?? ""));
}

function TemplateForm({ template, onBack }: { template: Template; onBack: () => void }) {
  const [errors, setErrors] = useState<Record<string, string>>({});

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm
            title="Open URL"
            onSubmit={(values) => {
              const newErrors: Record<string, string> = {};
              template.params.forEach((_, i) => {
                if (!values[`param_${i}`]) newErrors[`param_${i}`] = "Required";
              });
              if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors);
                return;
              }
              openUrl(buildUrl(template, values as Record<string, string>));
            }}
          />
          <Action title="Back" onAction={onBack} />
        </ActionPanel>
      }
    >
      <Form.Description title={template.name} text={template.description} />
      {template.params.map((param, i) => (
        <Form.TextField
          key={i}
          id={`param_${i}`}
          title={param.label}
          placeholder={param.placeholder}
          error={errors[`param_${i}`]}
          onChange={() => {
            if (errors[`param_${i}`]) {
              setErrors((prev) => {
                const next = { ...prev };
                delete next[`param_${i}`];
                return next;
              });
            }
          }}
        />
      ))}
    </Form>
  );
}

export default function Command() {
  const [selected, setSelected] = useState<Template | null>(null);

  const templatesPath = join(
    process.env.HOME!,
    "Library/Application Support/SuperCmd/extensions/url-builder/url-templates.json"
  );

  let templates: Template[] = [];
  try {
    templates = JSON.parse(readFileSync(templatesPath, "utf-8"));
  } catch {
    // missing or malformed file — show empty list
  }

  if (selected) {
    return <TemplateForm template={selected} onBack={() => setSelected(null)} />;
  }

  return (
    <List searchBarPlaceholder="Search URL templates...">
      {templates.map((template) => (
        <List.Item
          key={template.name}
          title={template.name}
          subtitle={template.description}
          actions={
            <ActionPanel>
              <Action
                title={template.params.length === 0 ? "Open URL" : "Fill Parameters"}
                onAction={() => {
                  if (template.params.length === 0) {
                    openUrl(template.url);
                  } else {
                    setSelected(template);
                  }
                }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
```

- [ ] **Step 2: Typecheck**

```bash
cd "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder" && npm run typecheck
```

Expected: no errors. Fix any TypeScript errors before proceeding.

---

## Task 4: Configure SuperCmd settings

**Files:**
- Modify: `/Users/marvin.dore/Library/Application Support/SuperCmd/settings.json`
- Delete: `/Users/marvin.dore/Library/Application Support/SuperCmd/script-commands/splunk-search.py`

Edit the live `settings.json` directly. It will be synced to chezmoi in Task 6.

- [ ] **Step 1: Add url-builder to installedExtensions**

Change:
```json
"installedExtensions": ["bookmarks"]
```
to:
```json
"installedExtensions": ["bookmarks", "url-builder"]
```

- [ ] **Step 2: Add both hotkeys to commandHotkeys (fixing pre-existing drift)**

Ensure both of these keys are present in `commandHotkeys`:
```json
"ext-bookmarks-index": "Command+Shift+B",
"ext-url-builder-index": "Command+Shift+U",
```

The bookmarks hotkey already exists in the live file but is missing from the chezmoi copy — adding it explicitly here ensures it survives the chezmoi re-add in Task 6.

- [ ] **Step 3: Add extensionCommandArguments entry**

In `extensionCommandArguments`, add:
```json
"url-builder/index": {}
```

- [ ] **Step 4: Remove stale script IDs**

Remove the following from both `recentCommands` (array) and `recentCommandLaunchCounts` (object keys):
- `"script-f56493bd41afafda"` — old Splunk Search command
- `"script-7604413c267868d8"` — orphaned script command

- [ ] **Step 5: Delete the old Splunk script**

```bash
rm "/Users/marvin.dore/Library/Application Support/SuperCmd/script-commands/splunk-search.py"
```

- [ ] **Step 6: Restart SuperCmd and verify the extension loads**

Quit and relaunch SuperCmd. Press `Command+Shift+U`. The list should open showing "Agent Session Logs" and "Agent Session Logs (with namespace)". If the list is empty, check that `url-templates.json` is valid JSON.

- [ ] **Step 7: Verify the parameter form works**

Select "Agent Session Logs", press Enter. A form should appear with a single "Agent Name" field. Type `PayrollProcessingAgent` and submit. Verify the Splunk URL that opens contains `PayrollProcessingAgent` (not `PayrollChecksAgent`).

- [ ] **Step 8: Verify empty field validation**

Open the form again, leave "Agent Name" blank, submit. The field should show a "Required" inline error and no URL should open.

---

## Task 5: Set up launchd watcher

**Files:**
- Create: `~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist`

- [ ] **Step 1: Create the plist**

Create `/Users/marvin.dore/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.supercmd.url-builder-watcher</string>
    <key>WatchPaths</key>
    <array>
        <string>/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/src</string>
    </array>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>rm -f "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/.sc-build/index.js"</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 2: Load the watcher**

```bash
launchctl load ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist
```

- [ ] **Step 3: Verify it loaded**

```bash
launchctl list | grep url-builder
```

Expected: a line containing `com.supercmd.url-builder-watcher` with exit code `0`.

---

## Task 6: Chezmoi integration

**Files:**
- Modify: `~/.local/share/chezmoi/run_once_load_launchagents.sh`
- Create: `~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist.tmpl`
- Re-add: live `settings.json` and bookmarks drift files

- [ ] **Step 1: Add the plist to chezmoi**

```bash
chezmoi add ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist
```

- [ ] **Step 2: Rename to .tmpl**

```bash
mv ~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist \
   ~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist.tmpl
```

- [ ] **Step 3: Replace hardcoded username with chezmoi template variable**

Open `~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist.tmpl` and replace both occurrences of `/Users/marvin.dore/` with `{{ .chezmoi.homeDir }}/`. The result should look like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.supercmd.url-builder-watcher</string>
    <key>WatchPaths</key>
    <array>
        <string>{{ .chezmoi.homeDir }}/Library/Application Support/SuperCmd/extensions/url-builder/src</string>
    </array>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>rm -f "{{ .chezmoi.homeDir }}/Library/Application Support/SuperCmd/extensions/url-builder/.sc-build/index.js"</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 4: Verify template renders correctly**

```bash
chezmoi execute-template < ~/.local/share/chezmoi/private_Library/private_LaunchAgents/com.supercmd.url-builder-watcher.plist.tmpl
```

Expected: rendered plist with `/Users/marvin.dore/` paths (no `{{ }}` tags in output).

- [ ] **Step 5: Update run_once_load_launchagents.sh with both plist pairs**

Replace the full contents of `~/.local/share/chezmoi/run_once_load_launchagents.sh` with:

```bash
#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.supercmd.bookmarks-watcher.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.supercmd.bookmarks-watcher.plist
launchctl unload ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist
```

The content change causes chezmoi to re-run this `run_once_` script on next `chezmoi apply` on any machine.

- [ ] **Step 6: Add url-builder source files to chezmoi**

```bash
chezmoi add \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/src/index.tsx" \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/package.json" \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/package-lock.json" \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/tsconfig.json" \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/url-templates.example.json"
```

Do NOT add `url-templates.json` (machine-specific) or `node_modules/` or `.sc-build/`.

- [ ] **Step 7: Sync drifted bookmarks files to chezmoi**

The bookmarks extension source was updated earlier in this project but not re-added to chezmoi. Fix that now:

```bash
chezmoi re-add \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/bookmarks/src/index.tsx" \
  "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/bookmarks/package.json"
```

- [ ] **Step 8: Sync updated settings.json to chezmoi**

```bash
chezmoi re-add "/Users/marvin.dore/Library/Application Support/SuperCmd/settings.json"
```

Verify the chezmoi copy now contains both `"ext-bookmarks-index": "Command+Shift+B"` and `"ext-url-builder-index": "Command+Shift+U"` in `commandHotkeys`.

- [ ] **Step 9: Verify chezmoi status is clean**

```bash
chezmoi status
```

Expected: no `M` (modified) or `D` (deleted) entries for any managed SuperCmd files. If any remain, re-add them.

- [ ] **Step 10: Commit to chezmoi git**

```bash
cd ~/.local/share/chezmoi && git add -A && git commit -m "feat: add url-builder extension, watcher, and sync bookmarks drift"
```

---

## Task 7: End-to-end verification

- [ ] **Step 1: Verify Command+Shift+U opens URL Builder**

Press `Command+Shift+U`. Should open the "Build Url" list with "Agent Session Logs" and "Agent Session Logs (with namespace)" visible.

- [ ] **Step 2: Verify single-param substitution**

Select "Agent Session Logs" and press Enter. Fill in `PayrollProcessingAgent`, submit. Confirm the browser opens a URL containing `*PayrollProcessingAgent*` (not `*PayrollChecksAgent*`).

- [ ] **Step 3: Verify two-param substitution**

Select "Agent Session Logs (with namespace)", fill in `PayrollChecksAgent` and `payroll`, submit. Confirm the URL contains `namespace%3D%22payroll%22` and `*PayrollChecksAgent*`.

- [ ] **Step 4: Verify empty field validation**

Open any template form, leave a field blank, submit. The blank field should show a "Required" inline error. The URL should not open.

- [ ] **Step 5: Verify launchd watcher**

Edit `src/index.tsx` (add a space and save). Wait 2 seconds. Check:

```bash
ls "/Users/marvin.dore/Library/Application Support/SuperCmd/extensions/url-builder/.sc-build/" 2>&1
```

Expected: `ls: .../sc-build/: No such file or directory` or empty directory. If gone, the watcher is working.

- [ ] **Step 6: Verify bookmarks still works**

Press `Command+Shift+B`. The bookmarks list should still open normally.
