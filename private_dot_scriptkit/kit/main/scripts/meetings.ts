// Script Kit entry point for the Meetings script.
//
// Overall flow:
//   1. Run an inline Swift script to query today's meetings via EventKit
//   2. Parse the output into Meeting objects (see _lib/meetings-utils.ts)
//   3. Show a picker with all remaining/in-progress meetings for today
//   4. On select: open the join URL if one was found, otherwise open Outlook
//
// Pure functions (secsToTime, extractJoinUrl, parseRecords) live in
// _lib/meetings-utils.ts so they can be unit-tested without the SDK.
// Files in _lib/ are invisible to Script Kit's flat glob (scripts/*.ts),
// so they won't appear as runnable scripts in the launcher.

import "@scriptkit/sdk";
import { secsToTime, parseRecords, type Meeting } from "./_lib/meetings-utils";

export const metadata = {
  name: "Meetings",
  description: "View today's remaining meetings and join with one click",
};

// SK_VERIFY=1 is set by the Script Kit harness when it syntax-checks scripts
// on startup. We must exit immediately with {"ok":true} — no UI, no Calendar
// access — so the harness can verify the script without side effects.
const isVerify = process.env.SK_VERIFY === "1";

if (isVerify) {
  console.log(JSON.stringify({ ok: true }));
  process.exit(0);
}

// ─── EventKit via Swift ───────────────────────────────────────────────────────
//
// Why EventKit instead of AppleScript?
//
// The original implementation used AppleScript ("tell application Calendar /
// set theEvents to every event of cal"). This works but is fatally slow for
// Exchange calendars: AppleScript has no indexed date-range query, so it must
// enumerate every event instance — including all historical and future
// expansions of recurring meetings — before filtering. A typical corporate
// Exchange account has thousands of such instances, causing the script to hang
// indefinitely.
//
// Apple's EventKit framework (used by Calendar.app itself) exposes
// predicateForEvents(withStart:end:) which hits the underlying calendar
// database index directly and returns only events in the given window. It's
// orders of magnitude faster.
//
// We ship the EventKit logic as an inline Swift script and pipe it into
// `swift -` via stdin. swift is always available on macOS at /usr/bin/swift
// (ships with Xcode Command Line Tools). No compilation step or temp files are
// needed; swift compiles and runs the snippet on the fly.
//
// Data protocol between Swift and TypeScript:
//   - Each event is one record: startSecs<<<F>>>endSecs<<<F>>>title<<<F>>>notes<<<F>>>location<<<R>>>
//   - startSecs / endSecs = seconds since midnight (locale-independent integers)
//   - <<<F>>> = field separator, <<<R>>> = record separator
//   - These multi-char sentinels are stripped from event text before output
//     so they can never appear in the data and corrupt the parse.
//   - If Calendar access is denied, the Swift script prints NOT_AUTHORIZED
//     and exits 0; the TypeScript wrapper re-throws it as an Error so the
//     caller's catch block can show a human-readable message.

const SWIFT_SCRIPT = `
import Foundation
import EventKit

let store = EKEventStore()
let sema = DispatchSemaphore(value: 0)

store.requestFullAccessToEvents { granted, _ in
    guard granted else { print("NOT_AUTHORIZED"); sema.signal(); return }
    let now = Date()
    let cal = Calendar.current
    let startOfDay = cal.startOfDay(for: now)
    var comps = DateComponents()
    comps.hour = 23; comps.minute = 59; comps.second = 59
    let endOfDay = cal.date(byAdding: comps, to: startOfDay)!
    let pred = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
    // Strip separators from field values so they can never corrupt the parse.
    let clean: (String?) -> String = { s in
        (s ?? "").replacingOccurrences(of: "<<<F>>>", with: "").replacingOccurrences(of: "<<<R>>>", with: "")
    }
    let events = store.events(matching: pred)
        .filter { !$0.isAllDay && $0.endDate > now && $0.endDate <= endOfDay }
        .sorted { $0.startDate < $1.startDate }
    for e in events {
        // timeIntervalSince(startOfDay) gives seconds since midnight — a
        // plain integer that's locale-independent and easy to format in TS.
        let s  = Int(e.startDate.timeIntervalSince(startOfDay))
        let en = Int(e.endDate.timeIntervalSince(startOfDay))
        print("\\(s)<<<F>>>\\(en)<<<F>>>\\(clean(e.title))<<<F>>>\\(clean(e.notes))<<<F>>>\\(clean(e.location))<<<R>>>", terminator: "")
    }
    sema.signal()
}
sema.wait()
`;

async function fetchTodaysMeetings(): Promise<Meeting[]> {
  const proc = Bun.spawn(["swift", "-"], {
    stdin: new TextEncoder().encode(SWIFT_SCRIPT),
    stdout: "pipe",
    stderr: "pipe",
  });

  const [raw, errText] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(errText.trim() || `swift exited with ${exitCode}`);
  }

  if (raw.startsWith("NOT_AUTHORIZED")) {
    throw new Error("Not authorized to send Apple events to Calendar");
  }

  return parseRecords(raw);
}

// ─── Main flow ────────────────────────────────────────────────────────────────

// Try Outlook first; fall back to macOS Calendar.app if Outlook isn't installed.
async function openOutlookOrCalendar(): Promise<void> {
  try {
    const proc = Bun.spawn(["open", "-a", "Microsoft Outlook"]);
    const exitCode = await proc.exited;
    if (exitCode !== 0) throw new Error("Outlook not installed");
  } catch {
    const calProc = Bun.spawn(["open", "-a", "Calendar"]);
    const calExitCode = await calProc.exited;
    if (calExitCode !== 0) {
      await notify("Could not open Outlook or Calendar");
    }
  }
}

let meetings: Meeting[];

try {
  meetings = await fetchTodaysMeetings();
} catch (err: unknown) {
  // Surface Calendar permission errors with actionable guidance;
  // show the raw message for any other failure.
  const msg = err instanceof Error ? err.message : String(err);
  const isPermissionError = msg.includes("Not authorized to send Apple events to Calendar");
  const displayMsg = isPermissionError
    ? "Calendar access denied. Grant access in System Settings → Privacy &amp; Security → Calendars."
    : msg;
  // Escape before interpolating into HTML to prevent XSS from event content.
  const escapeHtml = (s: string) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

  const escapedMsg = escapeHtml(displayMsg);
  await div(`
    <div class="p-8">
      <p class="text-red-400 font-semibold mb-2">Could not load meetings</p>
      <p class="text-gray-300 text-sm">${escapedMsg}</p>
    </div>
  `);
  process.exit(1);
}

if (meetings.length === 0) {
  await div(`
    <div class="p-8 text-center">
      <p class="text-gray-300 text-lg">No more meetings today</p>
    </div>
  `);
  process.exit(0);
}

// Build picker choices. Each choice value is the full Meeting object so the
// handler below has everything it needs without a second lookup.
const choices = meetings.map((m) => {
  const displayTitle = m.title.trim() || "(no title)";
  return {
    name: `${secsToTime(m.startSecs)} – ${secsToTime(m.endSecs)}  ${displayTitle}`,
    description: m.joinUrl ? "Join link available" : "No join link — will open Outlook",
    value: m,
  };
});

const selected = await arg("Select a meeting", choices);

// extractJoinUrl (in meetings-utils.ts) checked notes + location for a
// Teams/Zoom/Meet URL. If found, open it directly; otherwise fall back to
// Outlook so the user can find the call from there.
if (selected.joinUrl) {
  await open(selected.joinUrl);
} else {
  await openOutlookOrCalendar();
}
