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

Examples:
  $0 create --name "Buy Milk" --date 2026-02-15 --time 18:00
  $0 list --completed false
  $0 lists
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
