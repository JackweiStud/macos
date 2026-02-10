#!/bin/bash
# ============================================
# macOS Calendar - Delete Event (by UID)
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

UID_VAL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --uid) UID_VAL="$2"; shift 2 ;;
        *) json_error "delete" "Unknown option: $1" ;;
    esac
done

[ -z "$UID_VAL" ] && json_error "delete" "Missing required: --uid"
ES_UID=$(escape_as "$UID_VAL")

result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Calendar"
    set targetUID to "$ES_UID"
    repeat with cal in calendars
        try
            set matched to (every event of cal whose uid = targetUID)
            if (count of matched) > 0 then
                set targetEvent to item 1 of matched
                set info to my eventLine(targetEvent, name of cal)
                delete targetEvent
                return info
            end if
        end try
    end repeat
    error "Event not found with UID: " & targetUID
end tell
EOF
)

[ $? -ne 0 ] && json_error "delete" "$result"
event_to_json "delete" "$result"
