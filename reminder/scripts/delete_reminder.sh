#!/bin/bash
# ============================================
# macOS Reminders - Delete Reminder
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
        *) json_error "delete" "未知选项: $1" ;;
    esac
done

# --- Validate ---
[ -z "$ID" ] && json_error "delete" "缺少必需参数: --id"

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
