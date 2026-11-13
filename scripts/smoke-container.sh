#!/bin/sh
# Exit 0 when nginx inside a fresh container answers on /.
set -eu
image="${1:?image}"
port="${2:?port}"
platform="${3:?platform}"
name="smoke-$$"
docker rm -f "$name" >/dev/null 2>&1 || true
docker run -d --name "$name" --platform "$platform" -p "${port}:7681" "$image" >/dev/null
cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT
i=0
while [ "$i" -lt 90 ]; do
  if curl -sf -o /dev/null "http://127.0.0.1:${port}/"; then
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done
docker logs "$name" >&2 || true
exit 1
