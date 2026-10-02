# CLAUDE.md

## User
Andreas Pieber · Europe/Vienna · YouTrack login: `api`

---

## Startup — check before every session

### 1. YouTrack MCP
Verify `~/.claude.json` contains:
```json
"youtrack": {
  "type": "http",
  "url": "https://support.schmutterer-partner.at/mcp",
  "headers": { "Authorization": "Bearer <YOUR_YOUTRACK_TOKEN>" }
}
```
Get token: YouTrack → Profile → Authentication → Permanent tokens → New token.  
Test: `GET https://support.schmutterer-partner.at/api/users/me` with the Bearer token.

### 2. Clockify MCP
Verify `~/.claude.json` contains:
```json
"clockify": {
  "type": "stdio",
  "command": "<path-to-clockify-mcp-binary>",
  "env": {
    "CLOCKIFY_API_KEY": "<YOUR_CLOCKIFY_API_KEY>",
    "CLOCKIFY_POLICY": "read_only",
    "MCP_PROFILE": "local-stdio"
  }
}
```
Install binary: `npm install -g @apet97/clockify-mcp-go-linux-x64`  
Binary path after install: check with `which clockify-mcp` or look in the npm global bin.  
Get API key: clockify.me → Profile settings → Advanced → API key.

### 3. Verify connectivity
Call `clockify_whoami` (Clockify MCP) and `GET /api/users/me` (YouTrack REST) — both must return Andreas Pieber. If either fails, stop and guide the user through fixing the config above.

---

## Behavior

- After every sync: **commit + push** without asking. Commit message summarises the day and any new patterns learned.
- **PATTERNS.md is the source of truth** for all sync rules — read it at the start of every sync. Update it when new patterns are discovered.
- When in doubt about billing type, description, or ticket mapping: ask the user rather than guess.

---

## YouTrack REST API (fallback when MCP is unreachable)

```
Base: https://support.schmutterer-partner.at/api
Token: read from ~/.claude.json → mcpServers.youtrack.headers.Authorization

GET  /api/workItems?fields=id,date,duration(minutes),text,author(login),issue(id,idReadable,summary)
       &startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&author=api&$top=100
POST /api/issues/{issueId}/timeTracking/workItems
       body: {"date":<unix-ms>,"duration":{"minutes":N},"text":"...","type":{"id":"<typeId>","$type":"WorkItemType"}}
POST /api/workItems/{id}   ← update existing work item

Work item type IDs: Abrechenbar=87-3, Ausweisbar=87-4, Unausweisbar=87-6, Intern=87-19
```

---

## Sync rules

All rules are in **`PATTERNS.md`**. Do not duplicate them here.

---

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
