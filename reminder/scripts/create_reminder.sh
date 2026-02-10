#!/bin/bash
# ============================================
# macOS Reminders - Create Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
NAME="" DATE="" TIME=""
LIST="Reminders" NOTES=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --name)     NAME="$2"; shift 2 ;;
        --date)     DATE="$2"; shift 2 ;;
        --time)     TIME="$2"; shift 2 ;;
        --list)     LIST="$2"; shift 2 ;;
        --notes)    NOTES="$2"; shift 2 ;;
        *) json_error "create" "Unknown option: $1" ;;
    esac
done

# --- Validate ---
[ -z "$NAME" ] && json_error "create" "Missing required: --name"

# --- Escape for AppleScript ---
ES_NAME=$(escape_as "$NAME")
ES_LIST=$(escape_as "$LIST")
ES_NOTES=$(escape_as "$NOTES")

# Date handling
DATE_BLOCK=""
PROPERTIES="{name:\"$ES_NAME\"}"

# 🆕 隐式今日日期：如果仅提供时间，自动使用今天的日期
if [ -n "$TIME" ] && [ -z "$DATE" ]; then
    DATE=$(date +%Y-%m-%d)
fi

if [ -n "$DATE" ]; then
    validate_date "$DATE" || json_error "create" "Invalid date format: $DATE (expected YYYY-MM-DD)"
    [ -z "$TIME" ] && TIME="09:00" # Default morning time for reminders
    validate_time "$TIME" || json_error "create" "Invalid time format: $TIME (expected HH:MM)"
    DATE_BLOCK=$(build_date_as "reminderDate" "$DATE" "$TIME")
    PROPERTIES="{name:\"$ES_NAME\", due date:reminderDate, remind me date:reminderDate}"
fi

# --- Execute ---
result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Reminders"
    if not (exists list "$ES_LIST") then
        error "List not found: $ES_LIST"
    end if
    
    tell list "$ES_LIST"
$DATE_BLOCK
        set newRem to make new reminder with properties $PROPERTIES
        
        if "$ES_NOTES" is not "" then
            set body of newRem to "$ES_NOTES"
        end if
        
        return my reminderLine(newRem, "$ES_LIST")
    end tell
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "create" "$result"
fi

reminder_to_json "create" "$result"
