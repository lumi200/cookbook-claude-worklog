#!/usr/bin/env bash
# fetch-toggl.sh — fetch Toggl time entries for a date or range, quota-friendly
# Usage: TOGGL_TOKEN=... ./fetch-toggl.sh [START YYYY-MM-DD] [END YYYY-MM-DD, inclusive] [--refresh]
#        (defaults: START = today, END = START; --refresh re-downloads the project name cache)
# Output: JSON array of {date, description, minutes, project, project_id, start}
#
# Toggl allows only ~30 requests/hour. This script uses:
#   1 request  per run for the entries (any date range, never loop per day)
#   +1 request only when the project cache (.toggl-cache/projects.json) is missing or --refresh
# Remaining quota is printed to stderr. On a quota error the reset time is shown.
set -euo pipefail

: "${TOGGL_TOKEN:?Set TOGGL_TOKEN (Toggl -> Profile settings -> API token)}"

REFRESH=0; ARGS=()
for a in "$@"; do [[ "$a" == "--refresh" ]] && REFRESH=1 || ARGS+=("$a"); done
START="${ARGS[0]:-$(date +%F)}"
END="${ARGS[1]:-$START}"
NEXT="$(date -d "$END + 1 day" +%F)"   # end_date is exclusive

API="https://api.track.toggl.com/api/v9"
CACHE_DIR="$(dirname "$0")/.toggl-cache"
HDR="$(mktemp)"; trap 'rm -f "$HDR"' EXIT

# toggl_get <url> — GET with auth, report quota, fail loudly on HTTP errors
toggl_get() {
  local body code
  body="$(curl -s -D "$HDR" -w '\n%{http_code}' -u "${TOGGL_TOKEN}:api_token" "$1")"
  code="${body##*$'\n'}"; body="${body%$'\n'*}"
  echo "toggl quota remaining: $(grep -i '^x-toggl-quota-remaining' "$HDR" | tr -d '\r' | cut -d' ' -f2 || true)" >&2
  if [[ "$code" != 2* ]]; then
    echo "Toggl HTTP $code — quota resets in $(grep -i '^x-toggl-quota-resets-in' "$HDR" | tr -d '\r' | cut -d' ' -f2 || echo '?') s. $body" >&2
    exit 1
  fi
  printf '%s' "$body"
}

# project id -> name map, cached on disk (projects rarely change)
mkdir -p "$CACHE_DIR"
if [[ $REFRESH -eq 1 || ! -s "$CACHE_DIR/projects.json" ]]; then
  toggl_get "$API/me?with_related_data=true" \
    | jq '[(.projects // [])[] | {key: (.id|tostring), value: .name}] | from_entries' > "$CACHE_DIR/projects.json.tmp"
  mv "$CACHE_DIR/projects.json.tmp" "$CACHE_DIR/projects.json"
fi

toggl_get "$API/me/time_entries?start_date=${START}&end_date=${NEXT}" \
  | jq --slurpfile p "$CACHE_DIR/projects.json" '
      [.[] | select(.duration >= 0)
       | {date: (.start[0:10]), description,
          minutes: (.duration/60 | round),
          project: (if .project_id then ($p[0][.project_id|tostring] // null) else null end),
          project_id, start}]'
