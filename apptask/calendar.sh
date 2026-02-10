#!/bin/bash
# ============================================
# macOS Calendar Tool - Unified CLI Entry Point
# Usage: bash calendar.sh <action> [options]
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)/scripts"
ACTION="$1"

if [ -z "$ACTION" ]; then
    cat << 'USAGE'
macOS Calendar CLI Tool

Usage: bash calendar.sh <action> [options]

Actions:
  calendars                         List all available calendars
  create   --title --date --time    Create a new event
  list     [--date|--from --to]     Query events
  update   --uid [--title ...]      Update an event
  delete   --uid                    Delete an event

Examples:
  bash calendar.sh calendars
  bash calendar.sh create --title "开会" --date 2026-02-20 --time 14:00
  bash calendar.sh create --title "聚会" --date 2026-02-21 --time 08:00 --calendar learn --alarm 15 --location "咖啡厅" --notes "带电脑"
  bash calendar.sh list --date 2026-02-20
  bash calendar.sh list --from 2026-02-20 --to 2026-02-28 --calendar Home
  bash calendar.sh list --uid <event-uid>
  bash calendar.sh list --title "开会" --date 2026-02-20
  bash calendar.sh update --uid <event-uid> --title "新标题" --time 15:00
  bash calendar.sh delete --uid <event-uid>

Options (create):
  --title     TEXT    Event title (required)
  --date      DATE    Date YYYY-MM-DD (required)
  --time      TIME    Time HH:MM (required)
  --calendar  NAME    Calendar name (default: Home)
  --alarm     MIN     Alert minutes before (default: 0 = at start)
  --duration  MIN     Duration in minutes (default: 30)
  --location  TEXT    Location
  --notes     TEXT    Notes
  --all-day           Mark as all-day event

Options (list):
  --date      DATE    List events on specific date
  --from      DATE    Range start (default: today)
  --to        DATE    Range end
  --uid       UID     Get specific event by UID
  --title     TEXT    Search by title (partial match)
  --calendar  NAME    Filter by calendar

Options (update):
  --uid       UID     Event UID (required)
  --title/--date/--time/--duration/--location/--notes/--alarm

Options (delete):
  --uid       UID     Event UID (required)

All output is JSON formatted.
USAGE
    exit 0
fi

shift

case "$ACTION" in
    calendars) bash "$SCRIPT_DIR/list_calendars.sh" "$@" ;;
    create)    bash "$SCRIPT_DIR/create_event.sh" "$@" ;;
    list)      bash "$SCRIPT_DIR/list_events.sh" "$@" ;;
    update)    bash "$SCRIPT_DIR/update_event.sh" "$@" ;;
    delete)    bash "$SCRIPT_DIR/delete_event.sh" "$@" ;;
    *)
        echo "{\"status\":\"error\",\"action\":\"$ACTION\",\"message\":\"Unknown action: $ACTION. Use: calendars, create, list, update, delete\"}"
        exit 1
        ;;
esac
