// ~/.scriptkit/kit/main/scripts/_lib/meetings.test.ts
import { test, expect, describe } from "bun:test";
import { secsToTime, extractJoinUrl, parseRecords } from "./meetings-utils";

// ─── secsToTime ────────────────────────────────────────────────────────────

describe("secsToTime", () => {
  test("midnight (0) → 12:00 AM", () => {
    expect(secsToTime(0)).toBe("12:00 AM");
  });

  test("1 AM (3600)", () => {
    expect(secsToTime(3600)).toBe("1:00 AM");
  });

  test("10:00 AM (36000)", () => {
    expect(secsToTime(36000)).toBe("10:00 AM");
  });

  test("noon (43200) → 12:00 PM", () => {
    expect(secsToTime(43200)).toBe("12:00 PM");
  });

  test("12:45 PM (45900)", () => {
    expect(secsToTime(45900)).toBe("12:45 PM");
  });

  test("11:59 PM (86399)", () => {
    expect(secsToTime(86399)).toBe("11:59 PM");
  });

  test("1:01 AM (3660) — minutes are not just hours", () => {
    expect(secsToTime(3660)).toBe("1:01 AM");
  });

  test("1:00 PM (46800)", () => {
    expect(secsToTime(46800)).toBe("1:00 PM");
  });
});

// ─── extractJoinUrl ─────────────────────────────────────────────────────────

describe("extractJoinUrl", () => {
  test("returns null for plain text", () => {
    expect(extractJoinUrl("No meeting link here")).toBeNull();
  });

  test("extracts Teams classic join link", () => {
    const url = "https://teams.microsoft.com/l/meetup-join/19%3A/abc";
    expect(extractJoinUrl(`Join the meeting: ${url}`)).toBe(url);
  });

  test("extracts Teams short link (/meet/)", () => {
    const url = "https://teams.microsoft.com/meet/abc123";
    expect(extractJoinUrl(url)).toBe(url);
  });

  test("extracts Zoom link", () => {
    const url = "https://zoom.us/j/123456789";
    expect(extractJoinUrl(`Click to join: ${url}`)).toBe(url);
  });

  test("extracts Google Meet link", () => {
    const url = "https://meet.google.com/abc-def-ghi";
    expect(extractJoinUrl(url)).toBe(url);
  });

  test("strips trailing period", () => {
    expect(extractJoinUrl("Join: https://zoom.us/j/123456789.")).toBe(
      "https://zoom.us/j/123456789"
    );
  });

  test("strips trailing closing paren", () => {
    expect(extractJoinUrl("(https://zoom.us/j/123456789)")).toBe(
      "https://zoom.us/j/123456789"
    );
  });

  test("rejects http (not https)", () => {
    expect(extractJoinUrl("http://zoom.us/j/123456789")).toBeNull();
  });

  test("strips trailing closing bracket", () => {
    expect(extractJoinUrl("https://zoom.us/j/123456789]")).toBe(
      "https://zoom.us/j/123456789"
    );
  });

  test("strips trailing comma", () => {
    expect(extractJoinUrl("https://zoom.us/j/123456789,")).toBe(
      "https://zoom.us/j/123456789"
    );
  });
});

// ─── parseRecords ───────────────────────────────────────────────────────────

describe("parseRecords", () => {
  test("returns empty array for empty string", () => {
    expect(parseRecords("")).toEqual([]);
  });

  test("parses a single record without join link", () => {
    const raw = "36000<<<F>>>39600<<<F>>>Daily Standup<<<F>>>No link here<<<F>>>Room 101<<<R>>>";
    const result = parseRecords(raw);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      startSecs: 36000,
      endSecs: 39600,
      title: "Daily Standup",
      joinUrl: null,
    });
  });

  test("parses a record with a Zoom join link in notes", () => {
    const raw = "50400<<<F>>>54000<<<F>>>Team Sync<<<F>>>Join: https://zoom.us/j/999<<<F>>><<<R>>>";
    const result = parseRecords(raw);
    expect(result[0].joinUrl).toBe("https://zoom.us/j/999");
  });

  test("parses a record with a join link in location field", () => {
    const raw = "50400<<<F>>>54000<<<F>>>Team Sync<<<F>>><<<F>>>https://meet.google.com/abc-def-ghi<<<R>>>";
    const result = parseRecords(raw);
    expect(result[0].joinUrl).toBe("https://meet.google.com/abc-def-ghi");
  });

  test("sorts multiple records by startSecs ascending", () => {
    const raw =
      "54000<<<F>>>57600<<<F>>>Later Meeting<<<F>>><<<F>>><<<R>>>" +
      "36000<<<F>>>39600<<<F>>>Early Meeting<<<F>>><<<F>>><<<R>>>";
    const result = parseRecords(raw);
    expect(result[0].title).toBe("Early Meeting");
    expect(result[1].title).toBe("Later Meeting");
  });

  test("prefers URL in notes field over URL in location field", () => {
    const notesUrl = "https://zoom.us/j/111";
    const locationUrl = "https://zoom.us/j/222";
    const raw = `36000<<<F>>>39600<<<F>>>Meeting<<<F>>>${notesUrl}<<<F>>>${locationUrl}<<<R>>>`;
    const result = parseRecords(raw);
    // notes comes first in the combined string, so its URL wins
    expect(result[0].joinUrl).toBe(notesUrl);
  });

  test("skips malformed records with fewer than 5 fields", () => {
    // 3 fields only — truncated record
    const raw = "36000<<<F>>>39600<<<F>>>Truncated<<<R>>>";
    const result = parseRecords(raw);
    // Malformed records are silently skipped
    expect(result).toHaveLength(0);
  });
});
