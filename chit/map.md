# Map

- `Dockerfile` — Ubuntu image, user `coder` 1000, apt block, ttyd, mise, Starship. Copies scripts, `terminal/`, and `languages/` to `/opt/terminal-defaults`.
- `entrypoint.sh` — mount ownership, persists grok and GitHub auth on `/core`, seeds `/terminal`, starts nginx and ttyd.
- `tab.sh` — ttyd command: tmux sessions, grok theme in `/core/config.toml`, project list, `cd` and `grok`.
- `gh-wrapper.sh` — first directory on `PATH`; forwards to the real `gh`.
- `nginx.conf` — listens on 7681, basic auth, files from `/terminal`, `/ui/` and `/languages/` from the image, `/ws` to ttyd on 127.0.0.1:7682.
- `terminal/index.html` — tab bar, xterm.js, projects, palette, font, and language controls. Short ttyd calls into `tab.sh`.
- `terminal/ui/i18n.js` — parses `languages/*.ini` and picks a string, falling back to the English original.
- `terminal/ui/copy-selection.js` — browser clipboard and the copied banner. Served from `/ui/`, not from the volume.
- `languages/` — `English.ini` and `Russian.ini`.
- `terminal/themes/` — palette JSON and `manifest.json`. Ids match the grok `/theme` values.
- `terminal/fonts/` — bundled monospace faces.
- `VERSION` — last allocated `X.Y.Z`. `scripts/bump-version.sh` computes the next stable or prerelease number.
- `.github/workflows/image.yml` — push to `dev` publishes the image tag `dev` after tests and a startup check.
- `.github/workflows/release.yml` — push to `main` publishes the image tag `latest`, then tags `vX.Y.0`.
- `.github/workflows/publish-image.yml` — shared build, startup check, and unauthenticated pull.
- `.github/workflows/prerelease.yml` — a merge of `deps` into `dev` publishes `vX.Y.Z` with `Z > 0` and refreshes the `dev` tag.
- `.github/dependabot.yml` — weekly Friday 09:00 UTC updates onto `deps`. `scripts/sync-deps.sh` merges `main` into `deps`.
- `README.md` — compose, volumes, login.

Browser → nginx → ttyd → `tab.sh` → tmux → zsh → `grok`. The page loads palette JSON itself; grok's selected palette is `[ui].theme` in `/core/config.toml`.
