#!/bin/bash
# ============================================
# macOS Reminders - Update Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
ID="" TITLE="" LIST=""
NAME="" DATE="" TIME="" NOTES=""
MATCH_DATE="" MATCH_TIME=""
FORCE="false"

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --id)           ID="$2"; shift 2 ;;
        --title)        TITLE="$2"; shift 2 ;;
        --list)         LIST="$2"; shift 2 ;;
        --name)         NAME="$2"; shift 2 ;;
        --date)         DATE="$2"; shift 2 ;;
        --time)         TIME="$2"; shift 2 ;;
        --notes)        NOTES="$2"; shift 2 ;;
        --match-date)   MATCH_DATE="$2"; shift 2 ;;
        --match-time)   MATCH_TIME="$2"; shift 2 ;;
        --force)        FORCE="true"; shift ;;
        *) json_error "update" "未知选项: $1" ;;
    esac
done

# --- Validate ID/Title exclusivity ---
if [ -n "$ID" ] && [ -n "$TITLE" ]; then
    json_error "update" "参数冲突：--id 与 --title 只能二选一"
fi
if [ -z "$ID" ] && [ -z "$TITLE" ]; then
    json_error "update" "缺少必需参数：需要 --id 或 --title"
fi

# --- Escape & Build Logic ---
ES_NAME=$(escape_as "$NAME")
ES_NOTES=$(escape_as "$NOTES")
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
        set matchedReminders to (every reminder of theList whose name is "$ES_TITLE")
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
        json_error "update" "$match_result"
    fi

    lines=$(echo "$match_result" | grep -v '^$')
    count=$(echo "$lines" | grep -c '^')
    if [ -z "$lines" ]; then
        count=0
    fi

    if [ "$count" -eq 0 ]; then
        jq -n --arg a "update" --arg r "not_found_by_title" --arg t "$TITLE" --arg l "$LIST" --arg md "$MATCH_DATE" --arg mt "$MATCH_TIME" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),match_date:$md,match_time:$mt,message:"No reminder found matching title and criteria"}'
        exit 1
    elif [ "$count" -gt 1 ]; then
        candidates=$(echo "$lines" | reminder_lines_to_array)
        jq -n --arg a "update" --arg r "ambiguous_title" --arg t "$TITLE" --arg l "$LIST" --argjson c "$candidates" \
          '{status:"error",action:$a,reason:$r,title:$t,list:(if $l == "" then null else $l end),message:"Multiple reminders match title",candidates:$c}'
        exit 1
    fi

    ID=$(echo "$lines" | head -n 1 | cut -f1)
fi

# --- Collision Check: If updating name, check if target name already exists ---
if [ -n "$NAME" ] && [ "$FORCE" != "true" ]; then
    collision_check=$(osascript 2>&1 << EOF
tell application "Reminders"
    if "$ID" is not "" then
        set targetList to container of (first reminder whose id is "$ID")
    else
        set targetList to list "$ES_LIST"
    end if
    set collisions to (every reminder of targetList whose name is "$ES_NAME")
    return count of collisions
end tell
EOF
)
    if [ "$collision_check" -gt 0 ]; then
        jq -n --arg a "update" --arg n "$NAME" --arg l "$LIST" \
          '{status:"error",action:$a,reason:"collision",name:$n,message:"目标名称已在该清单中存在。请使用不同的名称，或通过 --force 强制更新。"}'
        exit 1
    fi
fi

UPDATE_BLOCK=""
if [ -n "$NAME" ]; then
    UPDATE_BLOCK="${UPDATE_BLOCK}set name of targetRem to \"$ES_NAME\"
    "
fi
if [ -n "$NOTES" ]; then
    UPDATE_BLOCK="${UPDATE_BLOCK}set body of targetRem to \"$ES_NOTES\"
    "
fi

if [ -n "$DATE" ]; then
    validate_date "$DATE" || json_error "update" "无效日期格式: $DATE (预期 YYYY-MM-DD)"
    [ -z "$TIME" ] && TIME="09:00"
    validate_time "$TIME" || json_error "update" "无效时间格式: $TIME (预期 HH:MM)"
    DATE_AS=$(build_date_as "newDate" "$DATE" "$TIME")
    UPDATE_BLOCK="${UPDATE_BLOCK}${DATE_AS}
    set due date of targetRem to newDate
    set remind me date of targetRem to newDate
    "
elif [ -n "$TIME" ]; then
    json_error "update" "更新时间时必须同时提供 --date（不支持单独更新时间而不指定日期）"
fi

# --- Execute ---
result=$(osascript 2>&1 << EOF
$(applescript_helpers)
tell application "Reminders"
    set matched to (every reminder whose id is "$ID")
    if (count of matched) is 0 then
        error "找不到 ID 为 $ID 的任务"
    end if
    
    set targetRem to item 1 of matched
    
    $UPDATE_BLOCK
    
    set listName to name of container of targetRem
    return my reminderLine(targetRem, listName)
end tell
EOF
)

if [ $? -ne 0 ]; then
    json_error "update" "$result"
fi

reminder_to_json "update" "$result"
