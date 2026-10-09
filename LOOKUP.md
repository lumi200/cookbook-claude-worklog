# LOOKUP.md — Luca's personal lookup (meetings, abbreviations, contacts, defaults)

Claude reads this during every sync to resolve tracker entries that have no issue ID, expand shorthands and pick billing types.
Add new rows whenever a sync teaches something new.

---

## 1. Projects & default billing type
Same as the previous user's defaults (confirmed by Luca). When in doubt: ask.

| Project | What it is | Default type |
|---------|-----------|--------------|
| MC | Meetings, check-ins, daily "Spaß mit Jause" bucket | Intern |
| SP | Internal infrastructure, cluster, rollouts, Zeitaufzeichnung | Intern |
| RX | Dev work, code reviews | Intern |
| SU | Billable client work → Abrechenbar; client-visible but not billed → Ausweisbar; OKL / HL7 internal investigation → Intern; on-site visit when client already logged Abrechenbar → Ausweisbar | **always confirm** |
| ORD | Billed client hours / Schulung → Abrechenbar; Verkaufsgespräch / Angebot → Ausweisbar; Requirements / planning (not contracted) → Intern; rollout / release → varies | **always confirm** |
| SMI | Client project | Abrechenbar (unless noted) |
| MAR | Marketing / conference | Intern |
| VPM | Infrastructure check / vulnerability | Intern |
| PD | Project rollouts | Intern |

Rule of thumb: SU / ORD / SMI entries are always confirmed with Luca before logging; everything else defaults to Intern.

## 2. Recurring meetings (same ticket every time)
| Signal in tracker | Ticket | Type | Description text in YT | Notes |
|---|---|---|---|---|
| Spaß mit Jause / SMJ (block starts ~09:00 with a prework phase; the meeting itself starts 09:15–09:30; the whole block is logged on this ticket) | The day's MC ticket titled `Spaß mit JAUSE YYYY-M-D` — search YouTrack (read-only) for that date, e.g. 2026-9-13 = MC-3484 | Intern | Spaß mit Jause (no trailing period; always on Jause tickets) | Daily; replaces the old "Spaß mit Support" (SMS). One new MC ticket per day (also weekends) |

## 3. Abbreviations & synonyms
| You write | Means / YT text | Ticket |
|---|---|---|
| SMJ | Spaß mit Jause | MC group (see §2) |
| SMS (old) | Spaß mit Support — legacy name, now Spaß mit Jause | MC group |

| Toggl "Onboarding" | SP-705 "Luca Onboarding" | Intern | Onboarding | Confirmed 2026-10-01 |
| Toggl "Superset Workflow Docs" / work that wasn't needed | MC-3142 "Arbeitsticket Luca Nachbar" | Intern | Superset-Dokumentation group, Luca's own wording | Confirmed 2026-10-01; MC-3142 is Luca's catch-all work ticket for work without a real ticket |

## 4. People, clients, contacts
None. Names are not used in Luca's tickets/entries — no name → ticket mapping needed.

## 5. Daily filler / catch-all
There is **no** daily catch-all ticket. Remaining minutes are not auto-assigned to a filler; if the day total doesn't match BCS, ask Luca.

## 6. Naming conventions for tickets created per day/week/month
| Pattern | Example | Used for |
|---|---|---|
| `Spaß mit JAUSE YYYY-M-D` (no zero padding) | `Spaß mit JAUSE 2026-8-10` (MC-3367), 2026-10-1 = MC-3605 | Daily Jause meeting, one MC ticket per day |

## 7. Billing exceptions & oddities
- Praktikum-supervision ticket (SP-630) is no longer needed.

## 7b. One-off day exceptions
| Date | Exception | Effect |
|---|---|---|
| 2026-10-01 | First workday; ordered to come in at 9:30 | No 7.7 h minimum check. Jause meeting still took place (started 9:30), only the 9:00 prework phase was skipped. Short total (336 min seen in Toggl) is expected, don't ask for re-verification |

## 8. Work schedule (BCS target)
- Typical day: starts 07:00–07:30, ends 15:10–16:00.
- **Minimum 7.7 h (462 min) per day.**
- Below target: if the day is **15 min or more under** 7.7 h → ask Luca to re-verify the times before proceeding. Smaller shortfalls are fine.
- Above target: fine, no questions.
