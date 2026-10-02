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
| Filler entry | **exact minutes** (absorbs remainder, no rounding) |

The day total (BCS) = nearest **15 min** to the tracker total. Ask the user when the total is within ~7 min of the midpoint between two 15-min slots.
`filler = BCS_total − sum(all other YT entries for the day)`

YT work items already booked for the day with no tracker equivalent count as real work: add their minutes to the tracker total before rounding to BCS.

---

## Rule 4 — Description text in YouTrack

Write complete sentences; roughly one sentence per hour worked. Abrechenbar/Ausweisbar entries must be understandable to the client — use the YouTrack ticket for context if the tracker entry is sparse. Start from the tracker text (minus issue ID and billing hints), improve grammar, and let the user confirm before logging. Expand shorthands using `LOOKUP.md`.

---

## Rule 5 — Abrechnungstyp (billing type)

Types: `Abrechenbar`, `Ausweisbar`, `Unausweisbar`, `Intern`. Defaults per project/ticket are in `LOOKUP.md`.
When unsure: ask. Always confirm client-facing work.

---

## Sync Workflow

```
1. FETCH   → entries for the target date (Toggl: ./fetch-toggl.sh YYYY-MM-DD)
2. CHECK   → existing YouTrack work items for the date (mark ✅ already in YT)
3. PARSE   → extract issue IDs; resolve recurring items via LOOKUP.md
4. GROUP   → consolidate by (issue_id, description_text)
5. ROUND   → per Rule 3
6. REVIEW  → table: Issue | Min | hh:mm | Type | Beschreibung
             (always both min and hh:mm, always the type, always the planned text;
              flag entries with no issue; propose filler; user confirms)
7. LOG     → log each confirmed entry to YouTrack
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
