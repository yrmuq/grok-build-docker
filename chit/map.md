# Map

- `Dockerfile` — Ubuntu image, user `coder` 1000, apt block, ttyd, mise, Starship. Copies scripts and `terminal/` to `/opt/terminal-defaults`.
- `entrypoint.sh` — mount ownership, persists grok and GitHub auth on `/core`, seeds `/terminal`, starts nginx and ttyd.
- `tab.sh` — ttyd command: tmux sessions, grok theme in `/core/config.toml`, project list, `cd` and `grok`.
- `gh-wrapper.sh` — first directory on `PATH`; forwards to the real `gh`.
- `nginx.conf` — listens on 7681, basic auth, files from `/terminal`, `/ui/` from the image, `/ws` to ttyd on 127.0.0.1:7682.
- `terminal/index.html` — tab bar, xterm.js, projects, theme and font controls. Short ttyd calls into `tab.sh`.
- `terminal/ui/copy-selection.js` — browser clipboard and the copied banner. Served from `/ui/`, not from the volume.
- `terminal/themes/` — palette JSON and `manifest.json`. Ids match the grok `/theme` values.
- `terminal/fonts/` — bundled monospace faces.
- `.github/workflows/image.yml` — push to `main` publishes `linux/amd64` and `linux/arm64` to GHCR.
- `README.md` — compose, volumes, login.

Browser → nginx → ttyd → `tab.sh` → tmux → zsh → `grok`. The page loads theme JSON itself; grok's selected palette is `[ui].theme` in `/core/config.toml`.
