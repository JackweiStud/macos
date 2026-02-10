#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)/scripts"
source "$SCRIPT_DIR/_common.sh"

ES_UID="B293196B-3510-4B3E-BBAA-82301A20F53E"
NEW_TIME="18:30"
IFS=':' read -r H MIN <<< "$NEW_TIME"

UPDATE_AS=""
UPDATE_AS+=$'\n'"set origDuration to (|end date| of targetEvent) - (|start date| of targetEvent)"
UPDATE_AS+=$'\n'"set eventDate to |start date| of targetEvent"
UPDATE_AS+=$'\n'"set day of eventDate to 1"
UPDATE_AS+=$'\n'"set hours of eventDate to $((10#$H))"
UPDATE_AS+=$'\n'"set minutes of eventDate to $((10#$MIN))"
UPDATE_AS+=$'\n'"set seconds of eventDate to 0"
UPDATE_AS+=$'\n'"set |start date| of targetEvent to eventDate"
UPDATE_AS+=$'\n'"set |end date| of targetEvent to eventDate + origDuration"

result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Calendar"
    set targetUID to "$ES_UID"
    repeat with cal in calendars
        try
            set matched to (every event of cal whose uid = targetUID)
            if (count of matched) > 0 then
                set targetEvent to item 1 of matched
                set calName to name of cal
$UPDATE_AS
                return my eventLine(targetEvent, calName)
            end if
        end try
    end repeat
end tell
EOF
)

echo "=== Raw AppleScript Output ==="
echo "$result"
echo ""
echo "=== Parsed JSON ==="
echo "$result" | event_to_json "update"
