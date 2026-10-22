<div align="center">
  <img src="docs/logo.png" alt="Grok Build Docker" width="96">

  <h1>Grok Build Docker (Unofficial)</h1>

  [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
  [![Base Image: Ubuntu](https://img.shields.io/badge/Ubuntu-Base-E95420?logo=ubuntu&logoColor=white)](https://hub.docker.com/_/ubuntu)

  <p>
    A self-hosted, persistent <code>Docker</code> environment and multi-tab web terminal wrapper for the <code>grok</code> AI coding agent CLI, integrating <code>ttyd</code>, <code>tmux</code>, <code>xterm.js</code>, <code>mise</code>, and <code>Starship</code> for a zero-bloat, isolated workspace.
  </p>
</div>

---

> [!WARNING]
> **Unofficial Community Project:** This repository is an **unofficial**, community-maintained `Docker` environment and web terminal wrapper. It is **not** affiliated with, endorsed by, sponsored by, or officially connected to **xAI (X.AI Corp.)** or any of its subsidiaries.
>
> **No Proprietary Binaries Included:** To strictly respect redistribution terms and upstream licensing, this repository and its `Dockerfile` do **not** contain or distribute any pre-packaged `grok-build` binaries. The official `grok` CLI is downloaded directly from `https://x.ai/cli/install.sh` onto your local host volume (`/core`) during the container's first startup.

---

![Grok Build Docker](docs/screenshot.webp)

---

## Features

* **Zero-Bloat Persistent Architecture:** Separated host-mounted volumes isolate agent binaries, runtime toolchains, custom skills, web assets, and user workspaces from the container image.
* **Custom Multi-Tab Web UI:** Built on `ttyd`, `tmux`, and `xterm.js` with a 100% mouse-driven top bar. Closing the browser tab detaches seamlessly; reopening restores all active `tmux` sessions (`chat0`, `chat1`, etc.) as browser tabs.
* **Two-Way Live Theme & Font Sync:** Includes `GrokNight`, `GrokDay`, `Tokyo Night`, `Rose Pine Moon`, and `Oscura Midnight` palettes synchronized with the `/theme` command inside `grok`. Custom font files (`woff2`, `woff`, `ttf`, `otf`) placed in `/terminal/fonts/` are automatically populated in the UI selector alongside `System Monospace`, with font size persisted in `localStorage`.
* **Sandboxed Package Management:** Runs as a non-root user (`coder`, `UID:GID 1000:1000`) with `sudo`, `apt`, and `apt-get` blocked at runtime. An `apt` wrapper redirects the AI agent to install programming languages, compilers, and CLI tools directly into the persistent `/utilities` volume via `mise`.

---

## Controls & Shortcuts

| Input | Action |
| :--- | :--- |
| Click `[+]` (Tab Bar) | Spawn a new `tmux` session tab. |
| Click Tab | Switch the active terminal session. |
| Double-Click Tab Name | Rename the active session tab. |
| Click `[×]` (Tab Bar) | Terminate the `tmux` session and close the tab. |
| Click `Reconnect` | Re-establish a dropped WebSocket connection. |
| Project Menu (`+`) | Prompt for a folder name, create it under `/projects`, and execute `cd` and `grok` if the active shell is idle. |
| Theme Selector / `/theme` | Switch color palettes (`GrokNight`, `GrokDay`, `Tokyo Night`, `Rose Pine Moon`, `Oscura Midnight`) with two-way synchronization. |
| Font Selector | Switch active terminal font from `/terminal/fonts/` or `System Monospace`. |

---

## Directory Architecture

All stateful data resides outside the container image across 5 dedicated host-mounted volumes:

| Container Path | Purpose |
| :--- | :--- |
| `/core` | `GROK_HOME` — stores the `grok` binary, OAuth tokens (`auth.json`), `config.toml`, `AGENTS.md`, memory, sessions, and `git` worktrees. |
| `/utilities` | Persistent storage for runtimes and CLI tools installed via `mise`, `cargo`, `rustup`, `uv`, and `npm`. |
| `/skills` | Custom `grok` skills (`/skills/<skill_name>/SKILL.md`), automatically linked to `/core/skills`. |
| `/projects` | Default `WORKDIR` for `git` repositories and coding projects. |
| `/terminal` | Web UI (`index.html`), theme JSON files (`/terminal/themes/`), and custom fonts (`/terminal/fonts/`). Changes apply on browser refresh without rebuilding the image. |

---

## Quick Start (Docker Compose)

### Architecture Support

Build the image directly on the target host so `docker compose build` selects the matching `ttyd` binary:

| Architecture | Status |
| :--- | :---: |
| `x86_64` | ✅ |
| `arm64` | ✅ |
| `arm` (32-bit) | ❌ |

### Deployment

Create the persistent directories on the host and set `1000:1000` ownership:

```bash
mkdir -p docker/data/grok_build/{core,utilities,skills,projects,terminal}
sudo chown -R 1000:1000 docker/data/grok_build

```

Add the service to `docker-compose.yml`:

```yaml
services:

  grok_build:
    container_name: grok_build
    build: [https://github.com/yrmuq/grok-build-docker.git#main](https://github.com/yrmuq/grok-build-docker.git#main)
    image: grok_build:latest
    ports:
      - ${GROK_BUILD}:7681
    volumes:
      - ${LOCATION}/docker/data/grok_build/core:/core
      - ${LOCATION}/docker/data/grok_build/utilities:/utilities
      - ${LOCATION}/docker/data/grok_build/skills:/skills
      - ${LOCATION}/docker/data/grok_build/projects:/projects
      - ${LOCATION}/docker/data/grok_build/terminal:/terminal
    environment:
      - TZ=${GROK_TZ:-UTC}
      - USER=${GROK_USER:-admin}
      - PASSWORD=${GROK_PASSWORD:-}
    logging:
      driver: json-file
      options:
        max-size: "55m"
        max-file: "1"
    restart: unless-stopped

```

Create a companion `.env` file (prefixed variable names avoid conflicts with default Linux shell variables like `USER`, `PASSWORD`, and `TZ`):

```dotenv
GROK_TZ=Europe/Tallinn
LOCATION=/home/user
GROK_USER=admin
GROK_PASSWORD=supersecretpassword # Leave empty to disable login
GROK_BUILD=7681

```

Build and start the container, then optionally follow the logs to verify the initial `grok` CLI installation:

```bash
docker compose up -d
docker logs -f grok_build

```

To pull upstream repository updates and rebuild the `grok_build:latest` image:

```bash
docker compose up -d --build

```

---

## Authentication & Usage

1. Navigate to `http://<SERVER_IP>:7681` and authenticate using `GROK_USER` and `GROK_PASSWORD`.
2. Authenticate `grok` using an xAI / X subscription via headless device authentication:

```bash
grok login --device-auth

```

3. Open the verification URL in a browser, enter the code to store the session token in `/core`, and start the agent:

```bash
grok

```

4. Install additional runtimes or CLI tools persistently via `mise`:

```bash
mise use -g python@latest rust@latest go@latest gh@latest

```

5. Update the `grok` CLI binary in `/core` when new versions release:

```bash
grok update

```

---

## License & Attribution

### Repository License

The scripts, configuration files, `Dockerfile`, `entrypoint.sh`, `tab.sh`, and custom web interface (`index.html`) in this repository are licensed under `GPL-3.0`. See the `LICENSE` file for full details.

### Third-Party Software & Attributions

| Component | Upstream | License | Integration Details |
| --- | --- | --- | --- |
| `grok` (`grok-build`) | [xai-org/grok-build](https://github.com/xai-org/grok-build) | `Apache-2.0` / xAI ToS | AI coding agent CLI downloaded to `/core` at runtime. |
| `ttyd` | [tsl0922/ttyd](https://github.com/tsl0922/ttyd) | `MIT` | Web-based terminal server. |
| `xterm.js` (+ `fit` & `web-links` addons) | [xtermjs/xterm.js](https://www.google.com/search?q=https://github.com/xtermjs/xterm.js) | `MIT` | Browser terminal emulator frontend loaded via CDN. |
| `tmux` | [tmux/tmux](https://github.com/tmux/tmux) | `ISC` | Terminal multiplexer for persistent multi-tab sessions. |
| `mise` (`mise-en-place`) | [jdx/mise](https://github.com/jdx/mise) | `MIT` | Polyglot runtime and CLI package manager targeting `/utilities`. |
| `Starship` | [starship/starship](https://github.com/starship/starship) | `ISC` | Cross-shell terminal prompt. |
| `JetBrains Mono` | [JetBrains/JetBrainsMono](https://github.com/JetBrains/JetBrainsMono) | `OFL-1.1` | Bundled monospace font copied to `/terminal/fonts/`. |
| `Fira Code` | [tonsky/FiraCode](https://github.com/tonsky/FiraCode) | `OFL-1.1` | Bundled monospace font copied to `/terminal/fonts/`. |
| `GrokNight` / `GrokDay` | [xai-org/grok-build](https://github.com/xai-org/grok-build) | `Apache-2.0` | Terminal color palettes stored in `/terminal/themes/`. |
| `Tokyo Night` | [enkia/tokyo-night-vscode-theme](https://github.com/enkia/tokyo-night-vscode-theme) | `MIT` | Terminal color palette stored in `/terminal/themes/`. |
| `Rosé Pine Moon` | [rose-pine/rose-pine-theme](https://github.com/rose-pine/rose-pine-theme) | `MIT` | Terminal color palette stored in `/terminal/themes/`. |
| `Oscura Midnight` | [narative/oscura](https://github.com/narative/oscura) | `MIT` | Terminal color palette stored in `/terminal/themes/`. |

*"Grok" and "xAI" are trademarks of X.AI Corp. All third-party trademarks and logos belong to their respective owners.*
