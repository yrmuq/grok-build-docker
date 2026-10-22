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
    --theme-get)
        FOUND="$(awk '
            /^\[/ { in_ui = ($0 ~ /^\[ui\][[:space:]]*$/) }
            in_ui && $0 ~ /^[[:space:]]*theme[[:space:]]*=/ {
                line = $0
                sub(/^[^=]*=[[:space:]]*/, "", line)
                gsub(/["'\'']/, "", line)
                gsub(/[[:space:]]/, "", line)
                print line
                exit
            }
        ' /core/config.toml 2>/dev/null || true)"
        printf '__GROK_THEME__:%s\n' "$FOUND"
        exit 0
        ;;
    --theme)
        THEME="${2:-}"
        if ! printf '%s' "$THEME" | grep -Eq '^[A-Za-z0-9_-]+$'; then
            exit 0
        fi
        touch /core/config.toml
        PREV="$(awk '
            /^\[/ { in_ui = ($0 ~ /^\[ui\][[:space:]]*$/) }
            in_ui && $0 ~ /^[[:space:]]*theme[[:space:]]*=/ {
                line = $0
                sub(/^[^=]*=[[:space:]]*/, "", line)
                gsub(/["'\'']/, "", line)
                gsub(/[[:space:]]/, "", line)
                print line
                exit
            }
        ' /core/config.toml 2>/dev/null || true)"
        awk -v theme="$THEME" '
            /^\[/ {
                if (in_ui && !wrote) {
                    print "theme = \"" theme "\""
                    wrote = 1
                }
                in_ui = ($0 ~ /^\[ui\][[:space:]]*$/)
                if (in_ui) saw_ui = 1
            }
            in_ui && $0 ~ /^[[:space:]]*theme[[:space:]]*=/ {
                print "theme = \"" theme "\""
                wrote = 1
                next
            }
            { print }
            END {
                if (!saw_ui) {
                    print ""
                    print "[ui]"
                    print "theme = \"" theme "\""
                } else if (!wrote) {
                    print "theme = \"" theme "\""
                }
            }
        ' /core/config.toml > /tmp/grok-config.toml
        mv /tmp/grok-config.toml /core/config.toml
        if [ "$PREV" = "$THEME" ]; then
            exit 0
        fi
        while IFS= read -r session; do
            [ -n "$session" ] || continue
            cmd="$(tmux list-panes -t "$session" -F '#{pane_current_command}' 2>/dev/null | head -n 1 || true)"
            if [ "$cmd" = "grok" ]; then
                tmux send-keys -t "$session" "/theme ${THEME}" Enter
            fi
        done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
        exit 0
        ;;
    --projects)
        if [ -d /projects ]; then
            find /projects -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort | while IFS= read -r name; do
                [ -n "$name" ] || continue
                printf '__PROJECT__:%s\n' "$name"
            done
        fi
        exit 0
        ;;
    --project-mkdir)
        NAME="${2:-}"
        case "$NAME" in
            ""|.|..|*/*) exit 0 ;;
        esac
        if printf '%s' "$NAME" | grep -q '[[:cntrl:]]'; then
            exit 0
        fi
        mkdir -p -- "/projects/${NAME}"
        exit 0
        ;;
    --project-go)
        SESSION="${2:-}"
        NAME="${3:-}"
        case "$NAME" in
            ""|.|..|*/*) exit 0 ;;
        esac
        if printf '%s' "$NAME" | grep -q '[[:cntrl:]]'; then
            exit 0
        fi
        [ -d "/projects/${NAME}" ] || exit 0
        [ -n "$SESSION" ] || exit 0
        CMD="$(tmux list-panes -t "$SESSION" -F '#{pane_current_command}' 2>/dev/null | head -n 1 || true)"
        case "$CMD" in
            zsh|bash|sh)
                DIR="$(printf '%q' "/projects/${NAME}")"
                tmux send-keys -t "$SESSION" "cd ${DIR} && grok" Enter
                ;;
        esac
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
