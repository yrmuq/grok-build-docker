#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    --list)
        SESSIONS="$(tmux list-sessions -F "#{session_name}" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || true)"
        printf '__TMUX_SESSIONS__:%s\n' "$SESSIONS"
        exit 0
        ;;
    --kill)
        if [ -n "${2:-}" ]; then
            tmux kill-session -t "$2" 2>/dev/null || true
        fi
        exit 0
        ;;
    --rename)
        if [ -n "${2:-}" ] && [ -n "${3:-}" ]; then
            tmux rename-session -t "$2" "$3" 2>/dev/null || true
        fi
        exit 0
        ;;
    --session)
        if [ -n "${2:-}" ]; then
            exec tmux new-session -A -s "$2"
        fi
        ;;
esac

i=0
while true; do
    NAME="chat${i}"
    if ! tmux has-session -t "$NAME" 2>/dev/null; then
        exec tmux new-session -A -s "$NAME"
    fi
    ATTACHED="$(tmux list-sessions -F "#{session_name} #{session_attached}" 2>/dev/null | awk -v n="$NAME" '$1 == n {print $2}')"
    if [ "$ATTACHED" = "0" ]; then
        exec tmux new-session -A -s "$NAME"
    fi
    i=$((i + 1))
done
