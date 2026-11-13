#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git init -q "$tmp"
cp "$root/scripts/bump-version.sh" "$tmp/bump-version.sh"
printf '1.4.0\n' > "$tmp/VERSION"
cd "$tmp"
git config user.email "test@example.com"
git config user.name "test"
git add VERSION
git commit -q -m "init"
stable=$(sh bump-version.sh stable VERSION)
[ "$stable" = "1.5.0" ]
pre=$(sh bump-version.sh prerelease VERSION)
[ "$pre" = "1.4.1" ]
git tag v1.4.7
pre=$(sh bump-version.sh prerelease VERSION)
[ "$pre" = "1.4.8" ]
printf '0.0.0\n' > VERSION
stable=$(sh bump-version.sh stable VERSION)
[ "$stable" = "0.1.0" ]
echo ok
