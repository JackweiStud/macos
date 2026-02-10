#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)/scripts"
source "$SCRIPT_DIR/_common.sh"

TITLE="测试"
DATE="2026-02-15"
TIME="10:00"
CALENDAR="Home"
ALARM=0
DURATION=30

ES_TITLE=$(escape_as "$TITLE")
ES_CAL=$(escape_as "$CALENDAR")
ES_LOC=""
ES_NOTES=""
ALL_DAY=false
DATE_BLOCK=$(build_date_as "eventDate" "$DATE" "$TIME")

# Save to file for inspection
SCRIPT_CONTENT=$(cat << EOF
$(applescript_helpers)

tell application "Calendar"
$DATE_BLOCK
    set endDate to eventDate + ($DURATION * 60)

    tell calendar "$ES_CAL"
        set newEvent to make new event with properties {summary:"$ES_TITLE", start date:eventDate, end date:endDate, allday event:$ALL_DAY}
        return my eventLine(newEvent, "$ES_CAL")
    end tell
end tell
EOF
)

echo "$SCRIPT_CONTENT" > /tmp/test_applescript.txt
echo "=== Saved AppleScript to /tmp/test_applescript.txt ==="
echo "=== Executing... ==="
echo "$SCRIPT_CONTENT" | osascript
