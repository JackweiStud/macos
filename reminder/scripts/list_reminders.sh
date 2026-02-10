#!/bin/bash
# ============================================
# macOS Reminders - List Reminders
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
LIST="" COMPLETED="false" SEARCH="" # Default to uncompleted, "true" or "all" to change

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --list)      LIST="$2"; shift 2 ;;
        --completed) COMPLETED="$2"; shift 2 ;;
        --search)    SEARCH="$2"; shift 2 ;;
        *) json_error "list" "Unknown option: $1" ;;
    esac
done

# --- Build AppleScript filters ---
LIST_FILTER="set listQueue to every list"
if [ -n "$LIST" ]; then
    ES_LIST=$(escape_as "$LIST")
    LIST_FILTER="set listQueue to {list \"$ES_LIST\"}"
fi

ES_SEARCH=$(escape_as "$SEARCH")

# Whose clause logic
if [ "$COMPLETED" = "true" ]; then
    COND="completed is true"
elif [ "$COMPLETED" = "false" ]; then
    COND="completed is false"
else
    COND=""
fi

if [ -n "$SEARCH" ]; then
    [ -n "$COND" ] && COND="$COND and "
    COND="${COND}name contains \"$ES_SEARCH\""
fi

if [ -n "$COND" ]; then
    WHOSE_CLAUSE="every reminder whose $COND"
else
    WHOSE_CLAUSE="every reminder"
fi

# --- Execute ---
result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Reminders"
    $LIST_FILTER
    set LF to character id 10
    set output to ""
    repeat with theList in listQueue
        set listName to name of theList
        set matchedReminders to ($WHOSE_CLAUSE) of theList
        repeat with r in matchedReminders
            set output to output & my reminderLine(r, listName) & LF
        end repeat
    end repeat
    return output
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "list" "$result"
fi

# Filter empty lines and build JSON
echo "$result" | grep -v '^$' | reminders_to_json "list"
