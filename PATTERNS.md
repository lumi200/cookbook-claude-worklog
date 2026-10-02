# Clockify → YouTrack Sync Patterns

---

## Rule 1 — Extract the YouTrack issue ID from the Clockify description

| Format | Example | Extracted issue |
|--------|---------|----------------|
| **Prefix**: `ISSUE-ID <description>` | `MC-2866 Support/Networking Wolke...` | MC-2866 |
| **Suffix**: `<label> - ISSUE-ID` | `code reviews daen - RX-10565` | RX-10565 |

- Issue IDs are **case-insensitive** in Clockify (`rx-10614` = `RX-10614`)
- The issue ID prefix is **stripped** from the description when writing to YouTrack
- Clockify billing hints in descriptions like `(Ausweisbar!)` or `(ich ausweisbar)` → strip from YT text, use as Abrechnungstyp signal

---

## Rule 2 — Consolidate entries with the same (issue ID + description text)

Multiple Clockify start/stop entries for the same task are merged into one YouTrack work item.

**Vibing entries** (Clockify description starts with "Vibing" or "Vibeing" and lists multiple issue IDs):
- Split total time evenly across the listed issues
- Combine vibing share with same-issue explicit entries (e.g. code reviews) before rounding
- Small vibing entries (< 20 min across 3+ tickets) → merge into SP-412 Zeitaufzeichnung instead

---

## Rule 3 — Round each consolidated group based on Abrechnungstyp

| Type | Granularity |
|------|-------------|
| Abrechenbar / Ausweisbar | nearest **15 min** |
| Intern (and all others) | nearest **5 min** |
| Filler entry | **exact minutes** (absorbs remainder, no rounding) |

```
# Abrechenbar/Ausweisbar
rounded = round(raw_minutes / 15) * 15

# Intern
rounded = round(raw_minutes / 5) * 5
```

The day total (target) = BCS Anwesenheit = nearest **15 min** to Clockify total (user chooses round up or down).
Ask user when total is within ~7 min of the midpoint between two 15-min slots.
**The filler entry is NOT rounded** — it absorbs exactly: `filler = BCS_total − sum(all other YT entries for the day)`

---

## Rule 4 — Description text in YouTrack

Write rich, multi-sentence descriptions. **Rule of thumb: at least one sentence per hour worked.**

- For **Abrechenbar/Ausweisbar**: clients must understand what was done — use context from both the Clockify description AND the YouTrack ticket (look it up if the Clockify entry is sparse). Never reduce to a single vague label.
- For **Intern**: colleagues also need to understand what was done — write complete sentences.
- Use markdown formatting (bullet lists) when logging multiple sub-tasks.
- Preserve information; include more rather than less.

Use the Clockify text (stripped of issue ID and billing hints) as the starting point; lightly improve grammar/capitalization; let user confirm or rewrite before logging.

| Clockify shorthand | YouTrack text |
|--------------------|---------------|
| `sms` / `SMS` | **Spaß mit Support** |
| `gf` | **Strategiebesprechung mit der Geschäftsführung.** |
| `statusmeeting hagenberg` | Statusmeeting inkl Vorbereitung und Nachbereitung Hagenberg. |
| `projekt hagenberg` | Projektstatusreview mit dem Team aus Hagenberg. |
| `daen codereview` | Codereview mit Daen. |
| `bap export ...` | Arbeiten am **BAP**-Export. *(BAP always capitalized)* |

---

## Rule 5 — Manual redistribution

A fraction of entries are redistributed to different issues. Present all as proposals; user confirms. Net daily total stays unchanged.

SU ticket investigation that leads to an RX fix → log time on the RX ticket (Intern), not the SU ticket.

---

## Rule 6 — Abrechnungstyp (billing type) per entry

Available types: `Abrechenbar`, `Ausweisbar`, `Unausweisbar`, `Intern`

| Context | Type |
|---------|------|
| MC project (meetings, sms, check-ins, GF meetings, Support/Networking filler) | **Intern** |
| SP project (internal infrastructure, cluster, rollouts, Zeitaufzeichnung) | **Intern** |
| RX project (dev work, code reviews) | **Intern** |
| SU ticket — billable client work | **Abrechenbar** |
| SU ticket — client-visible but not directly billed | **Ausweisbar** |
| SU ticket — OKL / HL7 internal investigation work | **Intern** |
| SU ticket — customer on-site visit (if client already logged Abrechenbar) | **Ausweisbar** |
| ORD — billed client hours / Schulung | **Abrechenbar** |
| ORD — Verkaufsgespräch / Angebot / Ausarbeitung Angebot | **Ausweisbar** |
| ORD — Requirements / planning (not yet contracted) | **Intern** |
| ORD — rollout / release work | varies — always confirm |
| SMI project | **Abrechenbar** (unless otherwise noted) |
| MAR project | **Intern** |
| VPM project | **Intern** |
| PD project | **Intern** |

When in doubt: default to **Intern** for internal/dev/meeting work; always confirm SU/ORD/SMI entries.

---

## Rule 7 — Special MC issue naming conventions

| Pattern | Format / notes |
|---------|---------------|
| Daily support bucket (filler) | Title: `Spaß mit Support YYYY-M-D`; work item text always: **`Support/Networking Wolke (Telefon, Slack, Email, Tickets, ...)`** |
| "Spaß mit Support" as Clockify *description* | Separate meeting entry on the same MC ticket — do NOT merge with filler |
| Weekly strategy / GF meetings | `Strategie & GF Meetings KWxx` — also used for Vorstellungsgespräche and executive intros |
| Monthly 1:1s | `Mitarbeitergespräche YYYY-M` (MC-2850 or equivalent) |
| Bewerbungsgespräch / Aufnahmegespräch | Separate MC ticket, Type=Bewerbungsgespräche (NOT merged into GF Meetings KWxx) |
| rX/WEB customer meetings | `rX/WEBMeeting <Customer> YYYY-MM-DD`, Type=Videokonferenz |
| STGKK weekly status (Roswitha Truchses) | Ticket MC-2839 or equivalent, Type=Statusmeeting; participants: Roswitha + Andreas + Christoph; **Abrechenbar** |
| KAV training (Mauritz Gstättner) | New MC ticket `KAV Schulung YYYY-MM-DD` per session; **Abrechenbar** |
| Spaß mit Leichen | **MC-2937** (recurring, Intern) |

**GF signal words**: `martin`, `gf`, Vorstellungsgespräch → map to current week's `Strategie & GF Meetings KWxx`.

---

## Sync Workflow

```
1. FETCH   → get all Clockify entries for the target date
2. CHECK   → get existing YouTrack work items for the date (show as ✅ already in YT)
3. PARSE   → extract issue ID from each entry (prefix or suffix pattern)
           → for recurring tickets with no ID (gf meeting, monthly review, etc.) search YT automatically
             using known patterns (KWxx → Strategie & GF Meetings KWxx; YYYY-M → Mitarbeitergespräche YYYY-M)
4. GROUP   → consolidate by (issue_id, description_text), sum durations
           → vibing entries: split evenly across listed issues, merge with same-issue entries
5. ROUND   → round each group to nearest 15 minutes
6. REVIEW  → present consolidated list as a table:
             Issue | Min | hh:mm | Type | Beschreibung
             - ALWAYS show both minutes AND hh:mm
             - ALWAYS include Abrechnungstyp column
             - ALWAYS include planned description text in the table (not just after it)
             - mark already-logged YT entries as ✅ with their minutes
             - flag entries with no issue ID (but try to resolve recurring ones automatically first)
             - propose filler (BCS_total − already_logged − all other new entries)
             - let user confirm/adjust before logging
7. LOG     → call mcp__youtrack__log_work for each confirmed entry
8. VERIFY  → sum(logged) = BCS_total
9. BCS     → remind user: https://bcs.schmutterer-partner.at → Tagesbuchen (neu) → Dauer
             (Playwright automation hits server-side 500; manual entry only)
10. COMMIT → add new patterns to PATTERNS.md, commit, push
```

---

## Known Recurring Tickets & Contacts

| Name / signal | Ticket | Typ | Notes |
|---------------|--------|-----|-------|
| Spaß mit Leichen | MC-2937 | Intern | Recurring meeting |
| Spaß mit Support (daily filler) | MC-xxxx (new per day) | Intern | Title: `Spaß mit Support YYYY-M-D` |
| STGKK / Roswitha Truchses | MC-2839 (reused) | Abrechenbar | Weekly status |
| Schmidhuber / Tatjana / Victor (Commitly) | SMI-3 | Abrechenbar | |
| Daen | MC-2850 (1:1) | Intern | Code reviews → RX ticket directly |
| Daniel | MC-2850 (1:1) | Intern | Daniel ≠ Daen — different people |
| Christian | RX tickets (code review) | Intern | |
| Leonie | RX-10443 (Arbeitsliste/Warteliste) | Intern | |
| Gerson | ORD-160 Cardiomed | Abrechenbar | queries/billing work |
| Luca (Praktikum) | SP-630 | Intern | Andreas is Luca's Betreuer |
| Prof. Sareban / IPAS Leistungserfassung | ORD-166 | Ausweisbar | Statistik/Leistungsgrundmeeting; "Leistungserfassung IPAS" in Clockify → ORD-166 |
| Fr. Holzheu / VAMB Meidling U4 | MC-2951 | mixed | Statistikbesprechung=Ausweisbar, Schulung=Abrechenbar |
| Philipp | MC-2951 | — | Student of Viktoria, VAMB Meidling context |
| Elias | KWxx GF ticket | Intern | External video marketing contact |
| Future Talks YYYY-MM-DD | MC-2978 (or new per date) | Intern | FutureTalks type; Besprechung Ziele/Tasks/Patientenportal |
| MAR-12 | rX/con 2026 | Intern | Conference + prep |
| LECTURE-xx | rX/lecture dev tickets | Intern | Reported by cha (Christian); code reviews → split evenly across listed LECTURE-xx tickets |
| SP-412 | Zeitaufzeichnung & BCS Management | Intern | Recurring admin |
| SP-423 | Rollout (VAMB, TWG, cl4/5/6…) | Intern | Sometimes missed by Clockify fetch — cross-check |
| SP-619 | Superset (Apache BI) | Intern | |
| SP-620 | MCP Interface / Figma | Intern | |
| SP-630 | Betreuung Praktikum Luca | Intern | |
| ORD-80 | TZR Ferlach (Schulung) | Abrechenbar | |
| ORD-157 | BAP-Export / HIT data export | Abrechenbar | BAP always capitalized |
| ORD-160 | Cardiomed (Max / Gerson) | Abrechenbar/Ausweisbar | Varies by work type |
| ORD-163 | Steyr | Ausweisbar (Verkaufsgespräch) / Intern (Requirements) | |
| VPM-8/9/10 | Infrastruktur Check / Vulnerability | Intern | Split time evenly across tickets |
| ELDA | RX-10526 | Intern | |
| PD project | NÖGKK rollout etc. | Intern | |

---

## Edge Cases & Overrides

- **User duration override**: "mach X min draus" → use user's value, ignore rounding rule
- **Auto-logged calls** (< 5 min, description "auto-logged call"): log as-is, Intern; do not round up
- **Old MC filler ticket in Clockify** → correct to current day's MC ticket in YouTrack
- **Clockify entry has no issue ID** → flag for user; do not guess
- **YT work items already booked for the day without a Clockify equivalent** → they represent real work done and tracked directly in YT (e.g. SU tickets booked from the support queue). Add their minutes to the Clockify raw total before rounding to BCS. BCS = nearest 15 to (Clockify raw + pre-booked minutes). Filler = BCS − all YT entries (including pre-booked).
- **Conference days** (rX/con etc.) not tracked in Clockify → log to MAR ticket, BCS = conference duration
- **"chrisi/gf notfalls bcs"** signals in Clockify → map to current week's GF ticket

---

## Setup

### Prerequisites check (run at start of every session)

```
1. YouTrack MCP  → mcp__youtrack__get_current_user should return Andreas Pieber
2. Clockify MCP  → mcp__clockify__clockify_whoami should return Andreas Pieber
3. If Clockify fails: check CLOCKIFY_API_KEY in ~/.claude.json
```

### YouTrack REST API (direct fallback for fetching existing work items)
```
GET https://support.schmutterer-partner.at/api/workItems
  ?fields=id,date,duration(minutes),text,author(login),issue(id,idReadable,summary,project(shortName))
  &startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&author=api&$top=100
  Authorization: Bearer <token from MCP config>
```

### Work item type (Abrechnungstyp)
Set via `type` field, not `attributes`. POST body: `{"type":{"id":"<id>","$type":"WorkItemType"}}`

Known type IDs (from GET /api/admin/timeTrackingSettings/workItemTypes):
| Name | ID |
|------|----|
| Abrechenbar | 87-3 |
| Ausweisbar | 87-4 |
| Unausweisbar | 87-6 |
| Intern | 87-19 |

To update an existing work item: `POST /api/workItems/{id}` with the type body.

### YouTrack
- URL: `https://support.schmutterer-partner.at`
- User: `api` (Andreas Pieber, Europe/Vienna)
