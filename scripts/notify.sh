#!/bin/bash

# Read hook stdin and extract session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
PIDFILE="/tmp/claude-notify-${SESSION_ID}.pid"

cancel_pending() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
  fi
}

# Parse options
if [ "$1" = "-c" ]; then
  cancel_pending
  shift
fi

# If arguments remain, schedule a new delayed notification
if [ $# -ge 2 ]; then
  MESSAGE="$1"
  TITLE="$2"
  nohup bash -c "sleep 30 && osascript -e 'display notification \"$MESSAGE\" with title \"$TITLE\"'; rm -f \"$PIDFILE\"" >/dev/null 2>&1 &
  echo $! > "$PIDFILE"
fi
