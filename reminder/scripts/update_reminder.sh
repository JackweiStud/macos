#!/bin/bash
# ============================================
# macOS Reminders - Update Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
ID="" NAME="" DATE="" TIME="" NOTES=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --id)       ID="$2"; shift 2 ;;
        --name)     NAME="$2"; shift 2 ;;
        --date)     DATE="$2"; shift 2 ;;
        --time)     TIME="$2"; shift 2 ;;
        --notes)    NOTES="$2"; shift 2 ;;
        *) json_error "update" "未知选项: $1" ;;
    esac
done

# --- Validate ---
[ -z "$ID" ] && json_error "update" "缺少必需参数: --id"

# --- Escape & Build Logic ---
ES_NAME=$(escape_as "$NAME")
ES_NOTES=$(escape_as "$NOTES")

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
    # 如果没提供时间，我们需要保留原有时间或设为 09:00？
    # 为了简单起见，如果只更新日期不提供时间，我们需要从 AppleScript 获取原有时间
    # 但 AppleScript 脚本逻辑会比较复杂。
    # 这里我们采用保守策略：如果提供了日期，必须提供时间，或者默认为 09:00
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
