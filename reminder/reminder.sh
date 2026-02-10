#!/bin/bash
# ============================================
# macOS Reminders CLI Entry Point
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/scripts"

usage() {
    cat <<EOF
Usage: $0 [action] [options]

Actions:
  create    Create a new reminder
  list      List reminders (defaults to uncompleted)
  lists     List available reminder lists
  complete  Mark a reminder as completed (by --id or --title [--list])
  delete    Delete a reminder (by --id or --title [--list])
  update    Update a reminder (by --id or --title [--list])
  cleanup   Cleanup completed reminders (optionally by list)

Examples:
  # 基础操作
  $0 create --name "Buy Milk" --date 2026-02-15 --time 18:00
  $0 list --completed false
  $0 lists
  
  # v2.0+ 高级功能
  $0 list --search "关键字"                          # 关键字搜索
  $0 complete --title "任务名" --match-time "15:00"  # 时间消歧
  $0 update --title "旧名" --name "新名" --force     # 强制覆盖
EOF
    exit 1
}

[ $# -lt 1 ] && usage

ACTION="$1"
shift

case "$ACTION" in
    create)
        bash "$BIN_DIR/create_reminder.sh" "$@"
        ;;
    list)
        bash "$BIN_DIR/list_reminders.sh" "$@"
        ;;
    complete)
        bash "$BIN_DIR/complete_reminder.sh" "$@"
        ;;
    delete)
        bash "$BIN_DIR/delete_reminder.sh" "$@"
        ;;
    update)
        bash "$BIN_DIR/update_reminder.sh" "$@"
        ;;
    cleanup)
        bash "$BIN_DIR/cleanup_reminders.sh" "$@"
        ;;
    lists)
        osascript << 'EOF' | jq -R 'split("\t")' | jq --arg a "lists" '{status:"success",action:$a,count:length,lists:.}'
        tell application "Reminders"
            set oldD to AppleScript's text item delimiters
            set AppleScript's text item delimiters to tab
            set allLists to name of every list
            set output to allLists as text
            set AppleScript's text item delimiters to oldD
            return output
        end tell
EOF
        ;;
    *)
        usage
        ;;
esac
