import { execSync } from "child_process";
import { readFileSync } from "fs";
import { join } from "path";
import { Action, ActionPanel, List, closeMainWindow } from "@raycast/api";

type Bookmark = { name: string; url: string; keywords: string };

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

export default function Command() {
  const bookmarksPath = join(
    process.env.HOME!,
    "Library/Application Support/SuperCmd/extensions/bookmarks/bookmarks.json"
  );
  const bookmarksData: Bookmark[] = JSON.parse(readFileSync(bookmarksPath, "utf-8"));
  return (
    <List searchBarPlaceholder="Search bookmarks...">
      {bookmarksData.map((bookmark) => (
        <List.Item
          key={bookmark.url}
          title={bookmark.name}
          subtitle={bookmark.keywords}
          keywords={bookmark.keywords.split(" ")}
          actions={
            <ActionPanel>
              <Action
                title="Open in Browser"
                onAction={async () => { await closeMainWindow(); openUrl(bookmark.url); }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
