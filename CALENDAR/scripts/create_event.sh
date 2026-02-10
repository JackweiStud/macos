#!/bin/bash
# ============================================
# macOS Calendar - Create Event
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
TITLE="" DATE="" TIME=""
CALENDAR="Home" ALARM=0 DURATION=30
LOCATION="" NOTES="" ALL_DAY=false

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --title)    TITLE="$2"; shift 2 ;;
        --date)     DATE="$2"; shift 2 ;;
        --time)     TIME="$2"; shift 2 ;;
        --calendar) CALENDAR="$2"; shift 2 ;;
        --alarm)    ALARM="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        --location) LOCATION="$2"; shift 2 ;;
        --notes)    NOTES="$2"; shift 2 ;;
        --all-day)  ALL_DAY=true; shift ;;
        *) json_error "create" "Unknown option: $1" ;;
    esac
done

# --- Validate ---
[ -z "$TITLE" ] && json_error "create" "Missing required: --title"
[ -z "$DATE" ]  && json_error "create" "Missing required: --date"
[ -z "$TIME" ]  && json_error "create" "Missing required: --time"
validate_date "$DATE" || json_error "create" "Invalid date format: $DATE (expected YYYY-MM-DD)"
validate_time "$TIME" || json_error "create" "Invalid time format: $TIME (expected HH:MM)"
[ "$ALARM" -lt 0 ] 2>/dev/null && ALARM=0
[ "$DURATION" -lt 1 ] 2>/dev/null && DURATION=30

# --- Escape for AppleScript ---
ES_TITLE=$(escape_as "$TITLE")
ES_CAL=$(escape_as "$CALENDAR")
ES_LOC=$(escape_as "$LOCATION")
ES_NOTES=$(escape_as "$NOTES")
DATE_BLOCK=$(build_date_as "eventDate" "$DATE" "$TIME")

# --- Execute ---
result=$(osascript 2>&1 << EOF
$(applescript_helpers)

tell application "Calendar"
$DATE_BLOCK
    set endDate to eventDate + ($DURATION * 60)

    tell calendar "$ES_CAL"
        set newEvent to make new event with properties {summary:"$ES_TITLE", start date:eventDate, end date:endDate, allday event:$ALL_DAY}

        if "$ES_LOC" is not "" then
            set location of newEvent to "$ES_LOC"
        end if

        if "$ES_NOTES" is not "" then
            set description of newEvent to "$ES_NOTES"
        end if

        if $ALARM > 0 then
            make new display alarm at end of newEvent with properties {trigger interval:-($ALARM * 60)}
        else
            make new display alarm at end of newEvent with properties {trigger interval:0}
        end if

        return my eventLine(newEvent, "$ES_CAL")
    end tell
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "create" "AppleScript error: $result"
fi

event_to_json "create" "$result"
