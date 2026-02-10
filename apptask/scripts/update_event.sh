#!/bin/bash
# ============================================
# macOS Calendar - Update Event (by UID)
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

UID_VAL="" NEW_TITLE="" NEW_DATE="" NEW_TIME=""
NEW_DURATION="" NEW_LOCATION="" NEW_NOTES="" NEW_ALARM=""
SET_LOCATION=false SET_NOTES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --uid)      UID_VAL="$2"; shift 2 ;;
        --title)    NEW_TITLE="$2"; shift 2 ;;
        --date)     NEW_DATE="$2"; shift 2 ;;
        --time)     NEW_TIME="$2"; shift 2 ;;
        --duration) NEW_DURATION="$2"; shift 2 ;;
        --location) NEW_LOCATION="$2"; SET_LOCATION=true; shift 2 ;;
        --notes)    NEW_NOTES="$2"; SET_NOTES=true; shift 2 ;;
        --alarm)    NEW_ALARM="$2"; shift 2 ;;
        *) json_error "update" "Unknown option: $1" ;;
    esac
done

[ -z "$UID_VAL" ] && json_error "update" "Missing required: --uid"
[ -n "$NEW_DATE" ] && { validate_date "$NEW_DATE" || json_error "update" "Invalid date: $NEW_DATE"; }
[ -n "$NEW_TIME" ] && { validate_time "$NEW_TIME" || json_error "update" "Invalid time: $NEW_TIME"; }

ES_UID=$(escape_as "$UID_VAL")

# --- Build dynamic AppleScript update commands ---
UPDATE_AS=""

if [ -n "$NEW_TITLE" ]; then
    ES_T=$(escape_as "$NEW_TITLE")
    UPDATE_AS+=$'\n'"set summary of targetEvent to \"$ES_T\""
fi

if [ -n "$NEW_DATE" ] || [ -n "$NEW_TIME" ]; then
    UPDATE_AS+=$'\n'"set origDuration to (end date of targetEvent) - (start date of targetEvent)"
    UPDATE_AS+=$'\n'"set eventDate to start date of targetEvent"
    UPDATE_AS+=$'\n'"set day of eventDate to 1"
    if [ -n "$NEW_DATE" ]; then
        IFS='-' read -r Y M D <<< "$NEW_DATE"
        UPDATE_AS+=$'\n'"set month of eventDate to $((10#$M))"
        UPDATE_AS+=$'\n'"set year of eventDate to $Y"
        UPDATE_AS+=$'\n'"set day of eventDate to $((10#$D))"
    fi
    if [ -n "$NEW_TIME" ]; then
        IFS=':' read -r H MIN <<< "$NEW_TIME"
        UPDATE_AS+=$'\n'"set hours of eventDate to $((10#$H))"
        UPDATE_AS+=$'\n'"set minutes of eventDate to $((10#$MIN))"
        UPDATE_AS+=$'\n'"set seconds of eventDate to 0"
    fi
    UPDATE_AS+=$'\n'"set start date of targetEvent to eventDate"
    if [ -n "$NEW_DURATION" ]; then
        UPDATE_AS+=$'\n'"set end date of targetEvent to eventDate + ($NEW_DURATION * 60)"
    else
        UPDATE_AS+=$'\n'"set end date of targetEvent to eventDate + origDuration"
    fi
elif [ -n "$NEW_DURATION" ]; then
    UPDATE_AS+=$'\n'"set end date of targetEvent to (start date of targetEvent) + ($NEW_DURATION * 60)"
fi

if [ "$SET_LOCATION" = true ]; then
    ES_L=$(escape_as "$NEW_LOCATION")
    UPDATE_AS+=$'\n'"set location of targetEvent to \"$ES_L\""
fi

if [ "$SET_NOTES" = true ]; then
    ES_N=$(escape_as "$NEW_NOTES")
    UPDATE_AS+=$'\n'"set description of targetEvent to \"$ES_N\""
fi

if [ -n "$NEW_ALARM" ]; then
    UPDATE_AS+=$'\n'"try"
    UPDATE_AS+=$'\n'"delete every display alarm of targetEvent"
    UPDATE_AS+=$'\n'"end try"
    if [ "$NEW_ALARM" -gt 0 ] 2>/dev/null; then
        UPDATE_AS+=$'\n'"make new display alarm at end of targetEvent with properties {trigger interval:-($NEW_ALARM * 60)}"
    else
        UPDATE_AS+=$'\n'"make new display alarm at end of targetEvent with properties {trigger interval:0}"
    fi
fi

[ -z "$UPDATE_AS" ] && json_error "update" "No fields to update. Specify at least one: --title, --date, --time, --duration, --location, --notes, --alarm"

result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Calendar"
    set targetUID to "$ES_UID"
    set found to false
    repeat with cal in calendars
        try
            set matched to (every event of cal whose uid = targetUID)
            if (count of matched) > 0 then
                set targetEvent to item 1 of matched
                set calName to name of cal
                set found to true
$UPDATE_AS
                return my eventLine(targetEvent, calName)
            end if
        end try
    end repeat
    if not found then error "Event not found with UID: " & targetUID
end tell
EOF
)

[ $? -ne 0 ] && json_error "update" "$result"
event_to_json "update" "$result"
