#!/usr/bin/env bash
# fetch-toggl.sh — fetch Toggl time entries for a date or date range in ONE API call
# Usage: TOGGL_TOKEN=... ./fetch-toggl.sh [START YYYY-MM-DD] [END YYYY-MM-DD, inclusive]
#        (defaults: START = today, END = START)
# Output: JSON array of {date, description, minutes, project_id, start}
# Note: Toggl rate-limits per hour (HTTP 402/429). Fetch a range once; never loop per day.
set -euo pipefail

: "${TOGGL_TOKEN:?Set TOGGL_TOKEN (Toggl -> Profile settings -> API token)}"
START="${1:-$(date +%F)}"
END="${2:-$START}"
NEXT="$(date -d "$END + 1 day" +%F)"

# end_date is exclusive, hence END + 1 day
curl -sf -u "${TOGGL_TOKEN}:api_token" \
  "https://api.track.toggl.com/api/v9/me/time_entries?start_date=${START}&end_date=${NEXT}" \
  | jq '[.[] | select(.duration >= 0)
         | {date: (.start[0:10]), description, minutes: (.duration/60 | round), project_id, start}]'
