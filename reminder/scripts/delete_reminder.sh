#!/bin/bash
# ============================================
# macOS Reminders - Delete Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
ID="" TITLE="" LIST=""
MATCH_DATE="" MATCH_TIME=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --id) ID="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --list) LIST="$2"; shift 2 ;;
        --match-date|--date) MATCH_DATE="$2"; shift 2 ;; # --date 作为兼容别名
        --match-time|--time) MATCH_TIME="$2"; shift 2 ;; # --time 作为兼容别名
        *) json_error "delete" "未知选项: $1" ;;
    esac
done

# --- Validate ID/Title exclusivity ---
if [ -n "$ID" ] && [ -n "$TITLE" ]; then
    json_error "delete" "参数冲突：--id 与 --title 只能二选一"
fi
if [ -z "$ID" ] && [ -z "$TITLE" ]; then
    json_error "delete" "缺少必需参数：需要 --id 或 --title"
fi

ES_TITLE=$(escape_as "$TITLE")
ES_LIST=$(escape_as "$LIST")

# --- Resolve ID by title if needed ---
if [ -z "$ID" ] && [ -n "$TITLE" ]; then
    LIST_FILTER="set listQueue to every list"
    if [ -n "$LIST" ]; then
        LIST_FILTER="set listQueue to {list \"$ES_LIST\"}"
    fi

    match_result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Reminders"
    $LIST_FILTER
    set LF to character id 10
    set output to ""
    repeat with theList in listQueue
        set listName to name of theList
        set allReminders to every reminder of theList
        set matchedReminders to {}
        repeat with r in allReminders
            if my nameMatches(name of r, "$ES_TITLE") then
                set end of matchedReminders to r
            end if
        end repeat
        repeat with r in matchedReminders
            if my dateMatches(due date of r, "$MATCH_DATE", "$MATCH_TIME") or ("$MATCH_DATE" is "" and "$MATCH_TIME" is "") then
                set output to output & my reminderLine(r, listName) & LF
            end if
        end repeat
    end repeat
    return output
end tell
EOF
)

    if [ $? -ne 0 ]; then
        json_error "delete" "$match_result"
    fi

    lines=$(echo "$match_result" | grep -v '^$')
    count=$(echo "$lines" | grep -c '^')
    if [ -z "$lines" ]; then
        count=0
    fi

    if [ "$count" -eq 0 ]; then
        jq -n --arg a "delete" --arg r "not_found_by_title" --arg t "$TITLE" --arg l "$LIST" --arg d "$MATCH_DATE" --arg ti "$MATCH_TIME" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),match_date:$d,match_time:$ti,message:"No reminder found matching title and criteria"}'
        exit 1
    elif [ "$count" -gt 1 ]; then
        candidates=$(echo "$lines" | reminder_lines_to_array)
        jq -n --arg a "delete" --arg r "ambiguous_title" --arg t "$TITLE" --arg l "$LIST" --argjson c "$candidates" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),message:"Multiple reminders match title",candidates:$c}'
        exit 1
    fi

    ID=$(echo "$lines" | head -n 1 | cut -f1)
fi

# --- Execute ---
result=$(osascript 2>&1 << EOF
tell application "Reminders"
    set matched to (every reminder whose id is "$ID")
    if (count of matched) is 0 then
        error "找不到 ID 为 $ID 的任务"
    end if
    
    set targetRem to item 1 of matched
    delete targetRem
    return "成功删除任务: $ID"
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "delete" "$result"
fi

json_success "delete" "$result"
