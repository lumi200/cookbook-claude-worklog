#!/usr/bin/env bash
# fetch-toggl.sh — fetch Toggl time entries for a date (default: today)
# Usage: TOGGL_TOKEN=... ./fetch-toggl.sh [YYYY-MM-DD]
# Output: JSON array of {description, minutes, project_id, start}
set -euo pipefail

: "${TOGGL_TOKEN:?Set TOGGL_TOKEN (Toggl -> Profile settings -> API token)}"
DATE="${1:-$(date +%F)}"
NEXT="$(date -d "$DATE + 1 day" +%F)"

# Toggl's start_date/end_date are an exclusive-end range; local-day boundaries in Europe/Vienna
curl -sf -u "${TOGGL_TOKEN}:api_token" \
  "https://api.track.toggl.com/api/v9/me/time_entries?start_date=${DATE}&end_date=${NEXT}" \
  | jq '[.[] | select(.duration >= 0) | {description, minutes: (.duration/60 | round), project_id, start}]'
