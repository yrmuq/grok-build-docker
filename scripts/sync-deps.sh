#!/bin/sh
# Move deps onto main. Keep commits that exist only on deps.
# A conflict is resolved only when the only conflicted file is VERSION; that file comes from main.
set -eu
git fetch origin main
if git rev-parse --verify origin/deps >/dev/null 2>&1; then
  git checkout -B deps origin/deps
else
  git checkout -B deps origin/main
fi
if git merge origin/main -m "Merge branch 'main' into deps"; then
  git push origin HEAD:deps
  exit 0
fi
conflicts=$(git diff --name-only --diff-filter=U)
other=$(printf '%s\n' "$conflicts" | grep -vx 'VERSION' || true)
if [ -n "$other" ]; then
  echo "deps sync stopped; conflicts besides VERSION:" >&2
  printf '%s\n' "$other" >&2
  exit 1
fi
git checkout origin/main -- VERSION
git add VERSION
git commit -m "Merge branch 'main' into deps"
git push origin HEAD:deps
