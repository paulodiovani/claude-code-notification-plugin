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

if [ "$1" = "-c" ]; then
  cancel_pending
  shift
fi

DELAY=0
if [ "$1" = "-d" ]; then
  DELAY="$2"
  shift 2
fi

if [ $# -ge 2 ]; then
  MESSAGE="$1"
  TITLE="$2"

  if [ "$DELAY" -gt 0 ]; then
    nohup bash -c "sleep '$DELAY' && '$0' '$MESSAGE' '$TITLE'; rm -f '$PIDFILE'" \
      >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
  else
    case "$(uname)" in
      Darwin) osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" ;;
      Linux)  notify-send "$TITLE" "$MESSAGE" ;;
    esac
  fi
fi
