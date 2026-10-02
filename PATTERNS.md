# Time Tracker → YouTrack Sync Patterns (Luca Nachbar)

Personal lookups (meetings, abbreviations, contacts, billing defaults) live in **`LOOKUP.md`**. Read both at the start of every sync.
Rules below marked *(confirm)* were inherited from a previous user and have not yet been confirmed for Luca.

---

## Rule 1 — Extract the YouTrack issue ID from the tracker description

| Format | Example | Extracted issue |
|--------|---------|----------------|
| **Prefix**: `ISSUE-ID <description>` | `MC-2866 Support/Networking ...` | MC-2866 |
| **Suffix**: `<label> - ISSUE-ID` | `code reviews - RX-10565` | RX-10565 |

- Issue IDs are case-insensitive (`rx-10614` = `RX-10614`)
- The issue ID is **stripped** from the description when writing to YouTrack
- Billing hints in descriptions like `(Ausweisbar!)` → strip from YT text, use as Abrechnungstyp signal
- No issue ID → look up in `LOOKUP.md`; if still unknown, flag for the user. Never guess.

---

## Rule 2 — Consolidate entries with the same (issue ID + description text)

Multiple start/stop entries for the same task are merged into one YouTrack work item.
If one entry lists several issue IDs, split its time evenly across them *(confirm)*.

---

## Rule 3 — Round each consolidated group based on Abrechnungstyp *(confirm)*

| Type | Granularity |
|------|-------------|
| Abrechenbar / Ausweisbar | nearest **15 min** |
| Intern (and all others) | nearest **5 min** |

There is no filler ticket. The day total (BCS) = nearest **15 min** to the tracker total; ask the user when it is within ~7 min of the midpoint between two 15-min slots. If rounded entries don't add up to BCS, ask which entry should absorb the difference.

YT work items already booked for the day with no tracker equivalent count as real work: add their minutes to the tracker total before rounding to BCS.

---

## Rule 4 — Description text in YouTrack

Descriptions are written **by Luca in a fixed schema**; Claude only drafts stubs, groups and renders.

**Luca's input schema** (one line per ticket):
```
RX-0001: sentence about this specific feature; another related point, e.g. a bugfix - a different feature on the same ticket; e.g. database migration
RX-0002: same schema
```
- `-` (space-dash-space) separates **groups** inside a ticket line. (Not the hyphen in the ticket ID.)
- `;` separates the **points** inside a group.

**Claude's job:**
1. Per sync, list every ticket in a table with a **stub description** Claude came up with (from tracker text and the YouTrack ticket). Luca replies with his lines in the schema above.
2. For each group, invent a **logical group name**. Render each ticket as markdown: bold group name, one bullet per `;`-point.
3. Show the full rendered markdown overview (ticket, minutes, type, rendered text) for Luca to check. Fix wording on request.
4. Do not rewrite Luca's content beyond light grammar fixes; expand shorthands from `LOOKUP.md`.

---

## Rule 4b — Read-only until explicit approval

**Everything before the approval is READ-ONLY.** No POST/PUT/DELETE, no `log_work`, nothing that writes to YouTrack.
Write calls are allowed **only after** Luca sends exactly: **`OK, an youtrack senden!!`**
Any other "ok"/"yes" does not count. Approval covers only the overview that was shown; if anything changes afterwards, re-render and wait for approval again.

---

## Rule 5 — Abrechnungstyp (billing type)

Types: `Abrechenbar`, `Ausweisbar`, `Unausweisbar`, `Intern`. Defaults per project/ticket are in `LOOKUP.md`.
When unsure: ask. Always confirm client-facing work.

---

## Sync Workflow

```
1. FETCH   → entries for the target date(s): ONE call ./fetch-toggl.sh START [END]
             (Toggl limit: 30 requests/hour — never loop per day, never re-fetch the same range;
              reuse the output already in the conversation; project names come from a local cache)
2. CHECK   → existing YouTrack work items for the date (mark ✅ already in YT)
3. PARSE   → extract issue IDs; resolve recurring items via LOOKUP.md
4. GROUP   → consolidate by (issue_id, description_text)
5. ROUND   → per Rule 3
6. REVIEW  → (read-only) table of tickets with stub descriptions: Issue | Min | hh:mm | Type | Stub
             → Luca answers in his schema (Rule 4) → Claude renders grouped markdown overview
             (always both min and hh:mm, always the type; flag entries with no issue;
              check day total vs. 7.7 h minimum per LOOKUP.md §8; no filler ticket exists)
7. LOG     → ONLY after Luca writes "OK, an youtrack senden!!" (Rule 4b): log each entry to YouTrack
8. VERIFY  → sum(logged) = BCS_total
9. BCS     → remind user: https://bcs.schmutterer-partner.at → Tagesbuchen (neu) → Dauer
10. COMMIT → add new patterns to PATTERNS.md / LOOKUP.md, commit, push
```

---

## Setup

### Prerequisites check (start of every session)
```
1. YouTrack: GET /api/users/me          → Luca Nachbar (lna)
2. Toggl:    GET /api/v9/me (TOGGL_TOKEN) → Luca Nachbar
```

### YouTrack REST API
```
GET https://support.schmutterer-partner.at/api/workItems
  ?fields=id,date,duration(minutes),text,author(login),issue(id,idReadable,summary,project(shortName))
  &startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&author=lna&$top=100
  Authorization: Bearer <token>
```

### Work item type
Set via `type`, not `attributes`: `{"type":{"id":"<id>","$type":"WorkItemType"}}`

| Name | ID |
|------|----|
| Abrechenbar | 87-3 |
| Ausweisbar | 87-4 |
| Unausweisbar | 87-6 |
| Intern | 87-19 |

Update an existing work item: `POST /api/workItems/{id}` with the type body.

### YouTrack
- URL: `https://support.schmutterer-partner.at`
- User: `lna` (Luca Nachbar, Europe/Vienna)
