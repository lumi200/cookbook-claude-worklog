# cookbook-claude-clockify

A Claude-powered assistant that syncs your tracked time into **YouTrack** work items — day by day, with correct billing types, rich descriptions, and BCS verification.

## What it does

At the end of each working day, ask Claude to sync a specific date. Claude will:

1. Fetch your time entries for the target date (from your tracker, or you describe your day)
2. Consolidate multiple start/stop entries for the same task
3. Round each group (15 min for billable, 5 min for intern)
4. Present the full list for review with proposed descriptions
5. Log a work item in YouTrack for each confirmed entry
6. Verify the day total matches BCS
7. Commit any new patterns to `PATTERNS.md`

## Usage

Open this repository in Claude Code and ask:

```
sync today
```
or
```
mach montag
```

Claude checks prerequisites first and guides you through any missing setup.

## Setup (new machine)

**YouTrack MCP is required.** Your time tracker is flexible — any tool works, and so does describing your day in plain text. An automated connection to your tracker (MCP or API) gives the best experience but is optional.

| Tool | Required? | How to get |
|------|-----------|-----------|
| **YouTrack MCP** | Yes | Permanent token from YouTrack → Profile → Authentication |
| **Time tracker MCP** | Recommended | Clockify: `npm install -g @apet97/clockify-mcp-go-linux-x64`; Toggl, Jira, etc.: see SETUP.md |

Configured in `~/.claude.json` (machine-local, never committed). See `CLAUDE.md` for the exact JSON structure.

## Sharing with colleagues

All engineers at Schmutterer can use this tool. Fork or clone this repo, open it in Claude Code, and say **"setup"** — Claude walks you through the rest.

Requirements: Claude Code + YouTrack MCP token (same YouTrack instance). Your time tracker is flexible — Clockify, Toggl, Jira, or just describing your day in natural language.

## Repository files

| File | Purpose |
|------|---------|
| `README.md` | This file |
| `SETUP.md` | First-time setup wizard — Claude interviews you and generates your personal config |
| `CLAUDE.md` | Instructions for Claude: startup check, config structure, behavior rules |
| `PATTERNS.md` | Universal sync rules + your personal ticket mappings — updated after every sync |
| `ground_truth/` | Reference sync outputs for regression testing |
