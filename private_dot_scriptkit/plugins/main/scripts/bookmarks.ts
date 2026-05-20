import "@scriptkit/sdk";
import bookmarks from "./_lib/bookmarks.json";

export const metadata = {
  name: "Bookmarks",
  description: "Search and open bookmarks",
  shortcut: "cmd+b",
};

type Bookmark = { name: string; url: string; keywords: string };

const localFile = Bun.file(import.meta.dir + "/_lib/bookmarks.local.json");
const localBookmarks: Bookmark[] = (await localFile.exists())
  ? await localFile.json()
  : [];

const allBookmarks = [...bookmarks, ...localBookmarks];

const selected = await arg(
  "Open bookmark",
  (input) => {
    const q = input.toLowerCase();
    return allBookmarks
      .filter(
        (b) =>
          !q ||
          b.name.toLowerCase().includes(q) ||
          b.keywords.toLowerCase().includes(q)
      )
      .map((b) => ({ name: b.name, description: b.keywords, value: b.url }));
  }
);

if (!selected) process.exit(0);

const proc = Bun.spawn(["open", selected]);
await proc.exited;
