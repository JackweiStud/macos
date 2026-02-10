#!/bin/bash
# ============================================
# macOS Calendar - List / Query Events
# Modes: --date, --from/--to, --uid, --title
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
DATE="" FROM="" TO="" EVENT_UID="" TITLE="" CALENDAR=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --date)     DATE="$2"; shift 2 ;;
        --from)     FROM="$2"; shift 2 ;;
        --to)       TO="$2"; shift 2 ;;
        --uid)      EVENT_UID="$2"; shift 2 ;;
        --title)    TITLE="$2"; shift 2 ;;
        --calendar) CALENDAR="$2"; shift 2 ;;
        *) json_error "list" "Unknown option: $1" ;;
    esac
done

# --- Mode: by UID ---
if [ -n "$EVENT_UID" ]; then
    ES_UID=$(escape_as "$EVENT_UID")
    result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Calendar"
    repeat with cal in calendars
        try
            set matched to (every event of cal whose uid = "$ES_UID")
            if (count of matched) > 0 then
                return my eventLine(item 1 of matched, name of cal)
            end if
        end try
    end repeat
    error "Event not found with UID: $ES_UID"
end tell
EOF
    )
    [ $? -ne 0 ] && json_error "list" "$result"
    event_to_json "list" "$result"
    exit 0
fi

# --- Determine date range ---
if [ -n "$DATE" ]; then
    validate_date "$DATE" || json_error "list" "Invalid date: $DATE"
    FROM="$DATE"; TO="$DATE"
elif [ -z "$FROM" ] && [ -z "$TO" ]; then
    # Default: next 7 days
    FROM=$(date +%Y-%m-%d)
    TO=$(date -v+7d +%Y-%m-%d)
fi
[ -n "$FROM" ] && validate_date "$FROM" || json_error "list" "Invalid --from date: $FROM"
[ -n "$TO" ] && validate_date "$TO" || json_error "list" "Invalid --to date: $TO"

START_BLOCK=$(build_date_as "filterStart" "$FROM" "00:00")
END_BLOCK=$(build_date_as "filterEnd" "$TO" "23:59")

# Build calendar filter
if [ -n "$CALENDAR" ]; then
    ES_CAL=$(escape_as "$CALENDAR")
    CAL_FILTER="set calList to {calendar \"$ES_CAL\"}"
else
    CAL_FILTER="set calList to every calendar"
fi

# Build title filter
if [ -n "$TITLE" ]; then
    ES_TITLE=$(escape_as "$TITLE")
    WHOSE_CLAUSE="every event whose start date >= filterStart and start date <= filterEnd and summary contains \"$ES_TITLE\""
else
    WHOSE_CLAUSE="every event whose start date >= filterStart and start date <= filterEnd"
fi

result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Calendar"
$START_BLOCK
$END_BLOCK
    $CAL_FILTER
    set LF to character id 10
    set output to ""
    repeat with cal in calList
        try
            set matched to ($WHOSE_CLAUSE) of cal
            repeat with e in matched
                set output to output & my eventLine(e, name of cal) & LF
            end repeat
        end try
    end repeat
    return output
end tell
EOF
)

[ $? -ne 0 ] && json_error "list" "$result"

# Filter empty lines and build JSON
echo "$result" | grep -v '^$' | events_to_json "list"
