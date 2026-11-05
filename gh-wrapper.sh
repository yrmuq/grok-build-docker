#!/usr/bin/env bash
# gh stores tokens in a keyring by default. This container has no keyring
# that survives a new shell, so login and refresh always write the token
# into GH_CONFIG_DIR as a file.
set -euo pipefail

real=""
IFS=':' read -ra dirs <<< "${PATH}"
for dir in "${dirs[@]}"; do
    [ "$dir" = "/usr/local/libexec/ghwrap" ] && continue
    if [ -x "${dir}/gh" ]; then
        real="${dir}/gh"
        break
    fi
done

if [ -z "$real" ]; then
    echo "gh is not installed. Install it with: mise use -g gh@latest" >&2
    exit 127
fi

if [ "${1:-}" = "auth" ] && { [ "${2:-}" = "login" ] || [ "${2:-}" = "refresh" ]; }; then
    cmd="$2"
    shift 2
    for arg in "$@"; do
        if [ "$arg" = "--insecure-storage" ]; then
            exec "$real" auth "$cmd" "$@"
        fi
    done
    exec "$real" auth "$cmd" --insecure-storage "$@"
fi

exec "$real" "$@"
