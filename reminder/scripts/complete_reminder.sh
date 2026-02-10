#!/bin/bash
# ============================================
# macOS Reminders - Complete Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
ID="" TITLE="" LIST=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --id) ID="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --list) LIST="$2"; shift 2 ;;
        *) json_error "complete" "未知选项: $1" ;;
    esac
done

# --- Validate ID/Title exclusivity ---
if [ -n "$ID" ] && [ -n "$TITLE" ]; then
    json_error "complete" "参数冲突：--id 与 --title 只能二选一"
fi
if [ -z "$ID" ] && [ -z "$TITLE" ]; then
    json_error "complete" "缺少必需参数：需要 --id 或 --title"
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
        set matchedReminders to (every reminder of theList whose name is "$ES_TITLE")
        repeat with r in matchedReminders
            set output to output & my reminderLine(r, name of theList) & LF
        end repeat
    end repeat
    return output
end tell
EOF
)

    if [ $? -ne 0 ]; then
        json_error "complete" "$match_result"
    fi

    lines=$(echo "$match_result" | grep -v '^$')
    count=$(echo "$lines" | grep -c '^')
    if [ -z "$lines" ]; then
        count=0
    fi

    if [ "$count" -eq 0 ]; then
        jq -n --arg a "complete" --arg r "not_found_by_title" --arg t "$TITLE" --arg l "$LIST" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),message:"No reminder found for title"}'
        exit 1
    elif [ "$count" -gt 1 ]; then
        candidates=$(echo "$lines" | reminder_lines_to_array)
        jq -n --arg a "complete" --arg r "ambiguous_title" --arg t "$TITLE" --arg l "$LIST" --argjson c "$candidates" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),message:"Multiple reminders match title",candidates:$c}'
        exit 1
    fi

    ID=$(echo "$lines" | head -n 1 | cut -f1)
fi

# --- Execute ---
# 我们需要先找到该任务，然后再标记完成
result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Reminders"
    set matched to (every reminder whose id is "$ID")
    if (count of matched) is 0 then
        error "找不到 ID 为 $ID 的任务"
    end if
    
    set targetRem to item 1 of matched
    set completed of targetRem to true
    
    -- 获取所属清单名称以返回格式化行
    set listName to name of container of targetRem
    return my reminderLine(targetRem, listName)
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "complete" "$result"
fi

reminder_to_json "complete" "$result"
