#!/bin/bash
# ============================================
# macOS Calendar - List Calendars
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

result=$(osascript 2>&1 -e 'tell application "Calendar" to get name of every calendar')

if [ $? -ne 0 ]; then
    json_error "calendars" "Failed to list calendars: $result"
fi

# Result is comma-separated: "Home, Work, learn, ..."
echo "$result" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' \
| jq -R '{name:.}' \
| jq -s '{status:"success",action:"calendars",count:length,calendars:.}'
