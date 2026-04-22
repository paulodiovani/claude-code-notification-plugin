#!/bin/bash

ICON_FILE="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/assets/claude-logo.png"

# In the delayed re-invocation SESSION_ID is inherited via env and stdin is /dev/null.
if [ -z "$SESSION_ID" ]; then
  INPUT=$(cat)
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
fi
PIDFILE="/tmp/claude-notify-${SESSION_ID}.pid"

# macOS: resolve the bundle id of the terminal that launched this Claude session.
# $__CFBundleIdentifier is set by LaunchServices and inherited through tmux/ssh.
session_bundle_id() {
  if [ -n "$__CFBundleIdentifier" ]; then
    echo "$__CFBundleIdentifier"
    return
  fi
  local pid=$PPID bid
  while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    bid=$(lsappinfo info -only bundleid -app "$pid" 2>/dev/null \
      | sed -n 's/^"CFBundleIdentifier"="\(.*\)"$/\1/p')
    if [ -n "$bid" ]; then
      echo "$bid"
      return
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
}

is_session_frontmost() {
  local asn front session
  asn=$(lsappinfo front 2>/dev/null)
  [ -n "$asn" ] || return 1
  front=$(lsappinfo info -only bundleid "$asn" 2>/dev/null \
    | sed -n 's/^"CFBundleIdentifier"="\(.*\)"$/\1/p')
  session=$(session_bundle_id)
  [ -n "$front" ] && [ -n "$session" ] && [ "$front" = "$session" ]
}

cancel_pending() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
  fi
  if [ "$(uname)" = "Darwin" ] \
    && [ -n "$SESSION_ID" ] \
    && command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -remove "$SESSION_ID" >/dev/null 2>&1
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
    export SESSION_ID
    nohup bash -c 'sleep "$1" && "$0" "$2" "$3"; rm -f "$4"' \
      "$0" "$DELAY" "$MESSAGE" "$TITLE" "$PIDFILE" \
      </dev/null >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
  else
    case "$(uname)" in
      Darwin)
        if ! command -v terminal-notifier >/dev/null 2>&1; then
          echo "notify.sh: terminal-notifier not found; install with 'brew install terminal-notifier'" >&2
          exit 0
        fi
        is_session_frontmost && exit 0
        BUNDLE_ID=$(session_bundle_id)

        args=(-title "$TITLE" -message "$MESSAGE")
        [ -n "$SESSION_ID" ] && args+=(-group "$SESSION_ID")
        [ -n "$BUNDLE_ID" ] && args+=(-activate "$BUNDLE_ID")
        [ -s "$ICON_FILE" ] && args+=(-contentImage "$ICON_FILE")
        terminal-notifier "${args[@]}" >/dev/null 2>&1
        ;;
      Linux)
        notify-send "$TITLE" "$MESSAGE"
        ;;
    esac
  fi
fi
