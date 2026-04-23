// ~/.scriptkit/kit/main/scripts/_lib/meetings-utils.ts

export type Meeting = {
  startSecs: number;
  endSecs: number;
  title: string;
  joinUrl: string | null;
};

// Regex covers Teams classic, Teams /meet/ short links, Zoom, Google Meet
const JOIN_URL_RE =
  /https:\/\/(teams\.microsoft\.com\/l\/meetup-join|teams\.microsoft\.com\/meet|zoom\.us\/j|meet\.google\.com)\/\S+/i;

/** Convert seconds-since-midnight to "H:MM AM/PM" */
export function secsToTime(secs: number): string {
  secs = Math.max(0, secs);
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const period = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 || 12;
  return `${h12}:${String(m).padStart(2, "0")} ${period}`;
}

/** Extract first Teams/Zoom/Meet URL from text, stripping trailing punctuation */
export function extractJoinUrl(text: string): string | null {
  const match = text.match(JOIN_URL_RE);
  if (!match) return null;
  return match[0].replace(/[.,;:!?)'"\]]+$/, "");
}

/**
 * Parse the raw AppleScript output (field sep: <<<F>>>, record sep: <<<R>>>)
 * into a sorted array of Meeting objects.
 * Records with fewer than 5 fields are silently skipped (malformed).
 */
export function parseRecords(raw: string): Meeting[] {
  return raw
    .split("<<<R>>>")
    .filter(Boolean)
    .flatMap((record) => {
      const parts = record.split("<<<F>>>");
      if (parts.length < 5) return []; // silently skip malformed records
      const [startStr, endStr, title, notes, location] = parts;
      const startSecs = parseInt(startStr, 10);
      const endSecs = parseInt(endStr, 10);
      if (isNaN(startSecs) || isNaN(endSecs)) return [];
      const combinedText = `${notes} ${location}`;
      return [{
        startSecs,
        endSecs,
        title: title ?? "",
        joinUrl: extractJoinUrl(combinedText),
      }];
    })
    .sort((a, b) => a.startSecs - b.startSecs);
}
