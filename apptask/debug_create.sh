#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)/scripts"
source "$SCRIPT_DIR/_common.sh"

TITLE="测试会议"
DATE="2026-02-15"
TIME="10:00"
CALENDAR="Home"
ALARM=15
DURATION=60
LOCATION="会议室A"
NOTES="这是一个测试事件"
ALL_DAY=false

ES_TITLE=$(escape_as "$TITLE")
ES_CAL=$(escape_as "$CALENDAR")
ES_LOC=$(escape_as "$LOCATION")
ES_NOTES=$(escape_as "$NOTES")
DATE_BLOCK=$(build_date_as "eventDate" "$DATE" "$TIME")

cat << EOF
========== Generated AppleScript ==========
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
========================================
EOF
