#!/bin/bash
# ============================================
# macOS Reminders - Cleanup Completed Reminders
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
LIST="" 

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --list) LIST="$2"; shift 2 ;;
        *) json_error "cleanup" "未知选项: $1" ;;
    esac
done

# --- Build AppleScript Filter ---
FILTER_CLAUSE="every list"
if [ -n "$LIST" ]; then
    ES_LIST=$(escape_as "$LIST")
    FILTER_CLAUSE="{list \"$ES_LIST\"}"
fi

# --- Execute ---
result=$(osascript 2>&1 << EOF
tell application "Reminders"
    set listQueue to $FILTER_CLAUSE
    set totalDeleted to 0
    repeat with theList in listQueue
        set completedReminders to (every reminder of theList whose completed is true)
        set countDeleted to count of completedReminders
        if countDeleted > 0 then
            delete (every reminder of theList whose completed is true)
            set totalDeleted to totalDeleted + countDeleted
        end if
    end repeat
    return totalDeleted
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "cleanup" "$result"
fi

json_success "cleanup" "成功清理了 $result 条已完成的任务"
