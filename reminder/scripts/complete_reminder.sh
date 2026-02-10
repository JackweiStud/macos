#!/bin/bash
# ============================================
# macOS Reminders - Complete Reminder
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
check_jq

# --- Defaults ---
ID=""

# --- Parse Args ---
while [ $# -gt 0 ]; do
    case "$1" in
        --id) ID="$2"; shift 2 ;;
        *) json_error "complete" "未知选项: $1" ;;
    esac
done

# --- Validate ---
[ -z "$ID" ] && json_error "complete" "缺少必需参数: --id"

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
