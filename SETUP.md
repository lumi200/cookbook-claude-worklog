# YouTrack + BCS Sync — First-Time Setup

*This file is read and executed by Claude Code. Open this repo in Claude Code, then say: **"setup"** or **"run setup"**.*

---

## For Claude: Setup Instructions

When the user asks to run setup (or opens this repo for the first time), follow the steps below in order. This is a one-time wizard that produces a working `CLAUDE.md` and `PATTERNS.md` for this specific user. Both files stay in this repo and grow over time.

Check first: does `PATTERNS.md` already exist with a non-empty `## Personal Patterns` section? If yes, offer to add/update patterns rather than start from scratch.

---

### Step 1 — YouTrack MCP

Call `mcp__youtrack__get_current_user`. If it works, note the user's login name and continue.

If it fails, guide the user to add this to `~/.claude.json` under `mcpServers`:

```json
"youtrack": {
  "type": "http",
  "url": "https://support.schmutterer-partner.at/mcp",
  "headers": { "Authorization": "Bearer <YOUR_YOUTRACK_TOKEN>" }
}
```

Token: YouTrack → Profile → Authentication → Permanent tokens → New token. After adding, restart Claude Code and re-run setup.

---

### Step 2 — Time Tracker (push for automation)

Ask the user: **"Which tool do you use to track your time during the day?"**

Then **actively recommend setting up an automated connection** — explain why:

> "An automated connection means Claude fetches your entries directly — no copy-paste, no manual description. The sync goes from ~20 minutes to under a minute. It's worth the 5-minute setup now."

Work through the options below. Default to the most automated option that exists for their tool. Only fall back to "describe your day" if nothing else is available or they explicitly prefer it.

#### Clockify (MCP available — set it up)

```json
"clockify": {
  "type": "stdio",
  "command": "<path from: which clockify-mcp>",
  "env": {
    "CLOCKIFY_API_KEY": "<key from clockify.me → Profile → Advanced → API key>",
    "CLOCKIFY_POLICY": "read_only",
    "MCP_PROFILE": "local-stdio"
  }
}
```
Install binary: `npm install -g @apet97/clockify-mcp-go-linux-x64`
Verify: `mcp__clockify__clockify_whoami` must return their name.

#### Toggl (REST API — set up a simple fetch)

Toggl has a public REST API. Offer to write a small script that fetches entries for a given date and outputs them as JSON/markdown. Store the script in this repo as `fetch-toggl.sh`. The user needs their Toggl API token (Toggl → Profile → API token).

```bash
# fetch-toggl.sh — fetches entries for $DATE (YYYY-MM-DD)
curl -s -u "<TOGGL_API_TOKEN>:api_token" \
  "https://api.track.toggl.com/api/v9/me/time_entries?start_date=${1}T00:00:00Z&end_date=${1}T23:59:59Z" \
  | jq '[.[] | {description, duration, project_id, start}]'
```

Token goes in `~/.claude.json` as an env var or the user sets `TOGGL_TOKEN` in their shell. The script stays in the repo.

#### Jira worklogs (REST or MCP)

If a Jira MCP is available, use it. Otherwise offer to write a `fetch-jira-worklogs.sh` using the Jira REST API (`/rest/api/3/issue/{issueKey}/worklog`). Needs their Jira base URL and a personal access token.

#### Other tools (any REST API)

If the user's tool has an API, offer to write a fetch script during setup. It only needs to output a list of entries with: description, duration (minutes), and optionally a project or issue reference. Store it in the repo.

#### No tracker / natural language (last resort)

If the user genuinely has no tool or doesn't want to set one up now: note "natural language" in their CLAUDE.md. During each sync, Claude will ask: *"Walk me through your day — what did you work on and roughly how long?"* This works but is slower. Mention they can add automation later by re-running setup.

---

### Step 3 — Interview

Ask these questions conversationally — one topic at a time, natural back-and-forth. You don't need to list them all at once.

1. **Projects**: Which YouTrack project shortnames do you work on? (e.g., MC, SP, RX, SU, ORD, SMI, MAR…). For each: is the default billing type Intern, Abrechenbar, or Ausweisbar?

2. **Recurring meetings**: Any weekly or monthly meetings that always go on the same ticket? Describe them — Claude will find or confirm the ticket ID.

3. **Recurring tasks**: Any regular tasks you log the same way every time? (daily standup, weekly reviews, a specific project you always work on)

4. **Known clients / contacts**: Any client names, external contacts, or companies you log time for regularly? What ticket do they map to?

5. **Daily filler**: Do you have a catch-all ticket for admin/support overhead? What does it cover and what's the ticket pattern?

6. **BCS target**: Do you work a fixed daily schedule (e.g., always 8h) or does it vary? This affects how the BCS total is calculated.

7. **Anything unusual**: Any quirky rules from your work — tickets that get split across multiple issues, billing type exceptions, description shorthands you use?

---

### Step 4 — Generate PATTERNS.md

Create `PATTERNS.md` using the **Universal Rules** section below (copy verbatim), then append a `## Personal Patterns` section populated from the interview answers.

Structure:

```
# [UserName] → YouTrack Sync Patterns

## Universal Rules
[copy Rules 1–6, Sync Workflow, and Setup from below — verbatim]

## Personal Patterns

### My Projects & Default Billing Types
[table from interview Q1]

### Known Recurring Tickets
[table from interview Q2–Q5]

### Personal Edge Cases
[anything from interview Q7]
```

---

### Step 5 — Generate CLAUDE.md

Create `CLAUDE.md` with:

```markdown
# CLAUDE.md

## User
[Name from YouTrack] · Europe/Vienna · YouTrack login: `[login]`

---

## Startup — check before every session

### 1. YouTrack MCP
Verify `~/.claude.json` contains the YouTrack MCP entry.
Test: call `mcp__youtrack__get_current_user` — must return [Name].

### 2. Time Tracker
[Their tool]. [MCP check or "no MCP needed — user will describe their day".]

### 3. Verify connectivity
If either check fails, stop and guide the user through fixing the config.

---

## Behavior

- After every sync: **commit + push** without asking. Commit message summarises the day.
- **PATTERNS.md is the source of truth** — read it at the start of every sync.
- When in doubt about billing type, description, or ticket mapping: ask rather than guess.

---

## YouTrack REST API (fallback when MCP is unreachable)

```
Base: https://support.schmutterer-partner.at/api
Token: read from ~/.claude.json → mcpServers.youtrack.headers.Authorization

GET  /api/workItems?fields=id,date,duration(minutes),text,author(login),issue(id,idReadable,summary)
       &startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&author=[login]&$top=100
POST /api/issues/{issueId}/timeTracking/workItems
       body: {"date":<unix-ms>,"duration":{"minutes":N},"text":"...","type":{"id":"<typeId>","$type":"WorkItemType"}}
POST /api/workItems/{id}   ← update existing work item

Work item type IDs: Abrechenbar=87-3, Ausweisbar=87-4, Unausweisbar=87-6, Intern=87-19
```

---

## Sync rules

All rules are in **`PATTERNS.md`**.
```

---

### Step 6 — Commit

```bash
git add CLAUDE.md PATTERNS.md
git commit -m "Setup: initial config for [name]"
git push
```

Tell the user: **Setup complete. Next time: open this repo in Claude Code and say "sync today" or "sync [day]".**

---

---

# Universal Rules
*(Included here so SETUP.md is self-contained. These are copied verbatim into PATTERNS.md during setup.)*

---

## Rule 1 — Extract the YouTrack issue ID from the time entry description

| Format | Example | Extracted issue |
|--------|---------|----------------|
| **Prefix**: `ISSUE-ID <description>` | `MC-2866 Support call...` | MC-2866 |
| **Suffix**: `<label> - ISSUE-ID` | `code reviews daen - RX-10565` | RX-10565 |

- Issue IDs are **case-insensitive** (`rx-10614` = `RX-10614`)
- The issue ID is **stripped** from the description when writing to YouTrack
- Billing hints in descriptions like `(Ausweisbar!)` or `(ich ausweisbar)` → strip from YT text, use as Abrechnungstyp signal

---

## Rule 2 — Consolidate entries with the same (issue ID + description text)

Multiple start/stop entries for the same task are merged into one YouTrack work item.

**Split entries** (description lists multiple issue IDs with a "Vibing"/"split" signal):
- Split total time evenly across listed issues
- Combine each share with same-issue explicit entries before rounding
- Very small splits (< 20 min across 3+ tickets) → merge into a Zeitaufzeichnung/admin ticket instead

---

## Rule 3 — Round each consolidated group based on Abrechnungstyp

| Type | Granularity |
|------|-------------|
| Abrechenbar / Ausweisbar | nearest **15 min** |
| Intern (and all others) | nearest **5 min** |
| Filler entry | **exact minutes** (absorbs remainder, no rounding) |

```
rounded_billable = round(raw_minutes / 15) * 15
rounded_intern   = round(raw_minutes / 5) * 5
```

BCS target = nearest **15 min** to total tracked time (user chooses up/down when close to midpoint).
**Filler is not rounded** — it absorbs exactly: `filler = BCS_total − sum(all other YT entries for the day)`.

Pre-booked YT entries without a tracker equivalent (e.g. tickets booked directly from a support queue) count as real work: add their minutes to the raw total before rounding to BCS.

---

## Rule 4 — Description text in YouTrack

Write rich, multi-sentence descriptions. **At least one sentence per hour worked.**

- **Abrechenbar/Ausweisbar**: clients must understand what was done — use context from both the entry description and the YouTrack ticket. Never reduce to a single vague label.
- **Intern**: colleagues also need to understand what was done — complete sentences.
- Use markdown bullet lists for multiple sub-tasks.
- Preserve information; include more rather than less.

Use the tracked entry text (stripped of issue ID and billing hints) as the starting point; lightly improve grammar/capitalization; let the user confirm or rewrite before logging.

---

## Rule 5 — Manual redistribution

Some entries are redistributed to different issues than originally tracked. Present all as proposals; user confirms. Net daily total stays unchanged.

---

## Rule 6 — Abrechnungstyp (billing type) per entry

Available types: `Abrechenbar`, `Ausweisbar`, `Unausweisbar`, `Intern`

General defaults (always confirm SU/ORD/SMI entries):

| Context | Default type |
|---------|-------------|
| Internal dev, meetings, infra | **Intern** |
| Billable client work (SU tickets) | **Abrechenbar** |
| Client-visible but not directly billed | **Ausweisbar** |
| Internal client investigation | **Intern** |
| Sales / proposals / pre-contract work | **Ausweisbar** |

When in doubt: default to **Intern** and ask.

---

## Sync Workflow

```
1. FETCH   → get all time entries for the target date from the user's tracker
             (or ask user to describe their day if no tracker MCP)
2. CHECK   → get existing YouTrack work items for the date (mark as ✅ already logged)
3. PARSE   → extract issue ID from each entry (prefix or suffix pattern)
             → for recurring tickets with no ID, search YT automatically
4. GROUP   → consolidate by (issue_id, description_text), sum durations
             → split entries: divide evenly across listed issues
5. ROUND   → round each group per Rule 3
6. REVIEW  → present consolidated list as a table:
             Issue | Min | hh:mm | Type | Beschreibung
             - ALWAYS show both minutes AND hh:mm
             - ALWAYS include Abrechnungstyp column
             - ALWAYS include planned description text in the table
             - mark already-logged YT entries as ✅ with their minutes
             - flag entries with no issue ID
             - propose filler (BCS_total − already_logged − all new entries)
             - let user confirm/adjust before logging
7. LOG     → POST to YouTrack for each confirmed entry (MCP or REST fallback)
             → set Abrechnungstyp via type field: {"type":{"id":"<id>","$type":"WorkItemType"}}
8. VERIFY  → sum(logged) = BCS_total
9. BCS     → remind user: https://bcs.schmutterer-partner.at → Tagesbuchen (neu) → Dauer
10. COMMIT → add new patterns to PATTERNS.md, commit, push
```

---

## Setup Reference

### YouTrack
- URL: `https://support.schmutterer-partner.at`
- Work item type IDs:

| Name | ID |
|------|----|
| Abrechenbar | 87-3 |
| Ausweisbar | 87-4 |
| Unausweisbar | 87-6 |
| Intern | 87-19 |

### REST API endpoints
```
GET  /api/workItems
       ?fields=id,date,duration(minutes),text,author(login),issue(id,idReadable,summary,project(shortName))
       &startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&author=<login>&$top=100
       Authorization: Bearer <token>

POST /api/issues/{issueId}/timeTracking/workItems
       {"date":<unix-ms>,"duration":{"minutes":N},"text":"...","type":{"id":"87-19","$type":"WorkItemType"}}

POST /api/workItems/{id}
       {"type":{"id":"87-19","$type":"WorkItemType"}}   ← update type on existing item
```

### Edge Cases (universal)
- **User duration override**: "mach X min draus" → use user's value, skip rounding
- **Auto-logged calls** (< 5 min, description "auto-logged call"): log as-is, Intern, no rounding
- **Entry has no issue ID**: flag for user, do not guess
- **Pre-booked YT entries without tracker equivalent**: add their minutes to raw total before BCS rounding

---

## Personal Patterns

*(Empty — filled in during setup. Updated automatically after each sync when new patterns are discovered.)*

### My Projects & Default Billing Types

| Project | Default type | Notes |
|---------|-------------|-------|
| *(fill in during setup)* | | |

### Known Recurring Tickets

| Signal / name | Ticket | Type | Notes |
|---------------|--------|------|-------|
| *(fill in during setup)* | | | |

### Personal Edge Cases

*(fill in during setup and over time)*
