#!/usr/bin/env bash
set -euo pipefail

AUTH_USER="${USER:-}"
AUTH_PASSWORD="${PASSWORD:-}"

# Bind mounts created by Docker are root-owned. Fix the mount roots only.
mkdir -p /core/bin /skills /projects /terminal/themes /terminal/fonts /home/coder
for dir in /core /utilities /skills /projects /terminal /home/coder /app; do
    mkdir -p "$dir"
    chown 1000:1000 "$dir"
done
# /core itself is fixed above, but mkdir created /core/bin as root.
chown -R 1000:1000 /core/bin
chmod 755 /core/bin

as_coder() {
    runuser -u coder --preserve-environment -- env \
        HOME=/home/coder \
        USER=coder \
        LOGNAME=coder \
        SHELL=/usr/bin/zsh \
        GROK_HOME=/core \
        GROK_BIN_DIR=/core/bin \
        MISE_DATA_DIR=/utilities/mise \
        MISE_CONFIG_DIR=/utilities/mise/config \
        MISE_CACHE_DIR=/utilities/mise/cache \
        CARGO_HOME=/utilities/cargo \
        RUSTUP_HOME=/utilities/rustup \
        UV_CACHE_DIR=/utilities/uv/cache \
        UV_PYTHON_INSTALL_DIR=/utilities/uv/python \
        UV_TOOL_DIR=/utilities/uv/tools \
        NPM_CONFIG_PREFIX=/utilities/npm \
        PATH="/core/bin:/utilities/mise/shims:/utilities/cargo/bin:/utilities/uv/tools/bin:/utilities/npm/bin:/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/sbin:/bin" \
        LANG="${LANG:-en_US.UTF-8}" \
        LC_ALL="${LC_ALL:-en_US.UTF-8}" \
        TZ="${TZ:-UTC}" \
        "$@"
}

as_coder mkdir -p \
    /core/bin \
    /utilities/mise/config \
    /utilities/mise/cache \
    /utilities/cargo \
    /utilities/rustup \
    /utilities/uv/cache \
    /utilities/uv/python \
    /utilities/uv/tools \
    /utilities/npm \
    /skills \
    /projects

# User skills live on the /skills volume, which Grok scans via $GROK_HOME/skills.
if [ -d /core/skills ] && [ ! -L /core/skills ]; then
    mkdir -p /skills
    shopt -s dotglob nullglob
    for item in /core/skills/*; do
        base="$(basename "$item")"
        if [ -e "/skills/${base}" ]; then
            echo "ERROR: /skills/${base} already exists, and /core/skills/${base} was not moved." >&2
            exit 1
        fi
        mv "$item" "/skills/${base}" || exit 1
    done
    shopt -u dotglob nullglob
    rmdir /core/skills || {
        echo "ERROR: /core/skills is not empty, so it was not linked to /skills." >&2
        exit 1
    }
fi
if [ ! -e /core/skills ] && [ ! -L /core/skills ]; then
    ln -s /skills /core/skills
    chown -h 1000:1000 /core/skills 2>/dev/null || true
fi

if [ ! -f /core/AGENTS.md ]; then
    cat << 'EOF' > /core/AGENTS.md
# Container Environment Rules for Grok Build
1. **System Package Manager Disabled**: `apt` and `apt-get` are strictly disabled. Do NOT attempt to use `apt` or `sudo`.
2. **Installing Languages & Utilities (`/utilities`)**: Always use `mise` to install any language, runtime, or CLI utility globally into `/utilities`:
   - Example: `mise use -g python@latest node@lts rust@latest ripgrep@latest fd@latest gh@latest uv@latest`
3. **Directory Layout**:
   - `/core`: Grok Build binary, config, memory, sessions (`GROK_HOME`).
   - `/utilities`: All installed languages, runtimes, and tools (`mise`, `cargo`, `uv`, `npm`).
   - `/skills`: Custom skills directory (`/skills/<skill_name>/SKILL.md`), linked from `$GROK_HOME/skills`.
   - `/projects`: User workspaces and git repositories.
4. **Web UI**: `/terminal/index.html` and `/terminal/themes/*.json` are the browser UI. Refresh the page to see edits. Do not rebuild the image for theme changes.
EOF
    chown 1000:1000 /core/AGENTS.md
fi

# The updater only swaps a symlink. A regular file at /core/bin/grok makes
# `grok update` fail with "reading prior symlink target ... Invalid argument".
# The installer stores the blob in ~/.grok/downloads and ignores GROK_HOME,
# so ~/.grok points at the /core volume and the link stays relative.
persist_grok_home() {
    mkdir -p /core/downloads /core/bin
    if [ -d /home/coder/.grok ] && [ ! -L /home/coder/.grok ]; then
        if [ -d /home/coder/.grok/downloads ]; then
            cp -a /home/coder/.grok/downloads/. /core/downloads/ || true
        fi
        rm -rf /home/coder/.grok
    fi
    if [ ! -L /home/coder/.grok ]; then
        ln -sfn /core /home/coder/.grok
    fi
    chown -h 1000:1000 /home/coder/.grok 2>/dev/null || true
    chown 1000:1000 /core/downloads /core/bin
}

link_managed() {
    local name="$1"
    local path="/core/bin/${name}"
    local target base dest
    mkdir -p /core/downloads
    if [ -L "$path" ]; then
        target="$(readlink -f "$path" || true)"
        if [ -n "$target" ] && [ -f "$target" ]; then
            base="$(basename "$target")"
            if [ "$target" != "/core/downloads/${base}" ]; then
                cp -f "$target" "/core/downloads/${base}"
                chown 1000:1000 "/core/downloads/${base}"
                chmod 755 "/core/downloads/${base}"
            fi
            ln -sfn "../downloads/${base}" "$path"
        fi
    elif [ -f "$path" ]; then
        case "$(uname -m)" in
            aarch64|arm64) cpu=aarch64 ;;
            *) cpu=x86_64 ;;
        esac
        dest="/core/downloads/${name}-managed-linux-${cpu}"
        mv -f "$path" "$dest"
        chown 1000:1000 "$dest"
        chmod 755 "$dest"
        ln -sfn "../downloads/${name}-managed-linux-${cpu}" "$path"
    else
        return 0
    fi
    chown -h 1000:1000 "$path" 2>/dev/null || true
}

persist_grok_home

cat << 'EOF' > /etc/zsh/zshrc
export GROK_HOME=/core
export GROK_BIN_DIR=/core/bin
export MISE_DATA_DIR=/utilities/mise
export MISE_CONFIG_DIR=/utilities/mise/config
export MISE_CACHE_DIR=/utilities/mise/cache
export CARGO_HOME=/utilities/cargo
export RUSTUP_HOME=/utilities/rustup
export UV_CACHE_DIR=/utilities/uv/cache
export UV_PYTHON_INSTALL_DIR=/utilities/uv/python
export UV_TOOL_DIR=/utilities/uv/tools
export NPM_CONFIG_PREFIX=/utilities/npm
export PATH="/core/bin:/utilities/mise/shims:/utilities/cargo/bin:/utilities/uv/tools/bin:/utilities/npm/bin:/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/sbin:/bin"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"
if ! command -v grok >/dev/null 2>&1; then
  echo "grok is not on PATH. Last lines of /core/grok-install.log:"
  tail -n 40 /core/grok-install.log 2>/dev/null || true
else
  echo "Ready. Sign in once with 'grok login --device-auth', then run 'grok'. Install tools with 'mise use -g <tool>@latest'."
fi
EOF

# Do not replace a file the user or the Grok installer already wrote.
if [ ! -f /home/coder/.zshrc ]; then
    printf '%s\n' '# Personal zsh settings. Not replaced on restart.' > /home/coder/.zshrc
elif grep -q 'Ready. Sign in once with' /home/coder/.zshrc && ! grep -q 'fpath=' /home/coder/.zshrc; then
    printf '%s\n' '# Personal zsh settings. Not replaced on restart.' > /home/coder/.zshrc
fi
if [ -d /core/completions ] && ! grep -q '/core/completions' /home/coder/.zshrc 2>/dev/null; then
    cat >> /home/coder/.zshrc << 'EOF'
fpath=(/core/completions $fpath)
autoload -Uz compinit && compinit
EOF
fi

cat << 'EOF' > /home/coder/.tmux.conf
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g default-shell /usr/bin/zsh
set -g mouse off
set -g status off
set -g set-titles on
set -g set-titles-string "#S"
set -g history-limit 100000
EOF
chown 1000:1000 /home/coder/.zshrc /home/coder/.tmux.conf

cd /projects

# Seed the mounted UI. Replace an older page once so double-click rename is present.
if [ ! -f /terminal/index.html ] || ! grep -q 'grok-audit-v1' /terminal/index.html; then
    cp /opt/terminal-defaults/index.html /terminal/index.html
fi
# Replace the first theme pack. Later files the user adds are left alone.
if [ ! -f /terminal/themes/.pack ] || [ "$(cat /terminal/themes/.pack 2>/dev/null)" != grok-open-1 ]; then
    rm -f /terminal/themes/catppuccin.json /terminal/themes/dracula.json \
        /terminal/themes/gruvbox.json /terminal/themes/latte.json
    cp /opt/terminal-defaults/themes/manifest.json /terminal/themes/manifest.json
    cp /opt/terminal-defaults/themes/*.json /terminal/themes/
    cp /opt/terminal-defaults/themes/NOTICE /terminal/themes/NOTICE
    printf 'grok-open-1\n' > /terminal/themes/.pack
fi
if [ ! -f /terminal/.favicon-rev ] || [ "$(cat /terminal/.favicon-rev 2>/dev/null)" != v5 ]; then
    cp /opt/terminal-defaults/favicon.png /terminal/favicon.png
    printf 'v5\n' > /terminal/.favicon-rev
fi
if [ ! -f /terminal/fonts/.pack ]; then
    cp /opt/terminal-defaults/fonts/* /terminal/fonts/ 2>/dev/null || true
    if [ ! -f "/terminal/fonts/JetBrains Mono.woff2" ]; then
        curl -fsSL --max-time 60 "https://cdn.jsdelivr.net/gh/JetBrains/JetBrainsMono@2.304/fonts/webfonts/JetBrainsMono-Regular.woff2" -o "/terminal/fonts/JetBrains Mono.woff2" || true
    fi
    if [ ! -f "/terminal/fonts/Fira Code.woff2" ]; then
        curl -fsSL --max-time 60 "https://cdn.jsdelivr.net/npm/firacode@6.2.0/distr/woff2/FiraCode-Regular.woff2" -o "/terminal/fonts/Fira Code.woff2" || true
    fi
    printf 'fonts-1\n' > /terminal/fonts/.pack
fi
chmod -R a+rX /terminal
chown -R 1000:1000 /terminal

# Older volumes were seeded before copy-on-select. Insert the helper once.
if [ -f /terminal/index.html ] && ! grep -q 'grok-copy-selection' /terminal/index.html; then
    awk '
        { print }
        /addon-web-links@0\.11\.0\/lib\/addon-web-links\.min\.js/ && !done {
            print "  <script src=\"/ui/copy-selection.js\" data-grok-copy-selection></script>"
            done = 1
        }
    ' /terminal/index.html > /tmp/index.html.new
    if grep -q 'grok-copy-selection' /tmp/index.html.new; then
        cat /tmp/index.html.new > /terminal/index.html
    fi
    rm -f /tmp/index.html.new
fi

if [ -n "$AUTH_PASSWORD" ]; then
    if [ -z "$AUTH_USER" ]; then
        AUTH_USER=admin
    fi
    htpasswd -bc /etc/nginx/ttyd.htpasswd "$AUTH_USER" "$AUTH_PASSWORD" >/dev/null
    chown root:www-data /etc/nginx/ttyd.htpasswd
    chmod 640 /etc/nginx/ttyd.htpasswd
    echo "Web UI basic auth enabled for ${AUTH_USER}."
else
    sed -i '/auth_basic/d' /etc/nginx/nginx.conf
    echo "PASSWORD is empty; web UI is open without basic auth."
fi
mkdir -p /tmp/nginx-client /tmp/nginx-proxy /tmp/nginx-fastcgi /tmp/nginx-uwsgi /tmp/nginx-scgi

as_coder ttyd -i 127.0.0.1 -p 7682 -I /terminal/index.html -a -W -m 40 /app/tab.sh &
ttyd_pid=$!
nginx -g 'daemon off;' &
nginx_pid=$!

# Downloads must not keep port 7681 closed. A stall stops at the timeout.
(
    install_log=/core/grok-install.log
    if [ ! -x /core/bin/grok ]; then
        echo "Downloading Grok Build into /core/bin ..." | tee -a "$install_log"
        if curl -fsSL --max-time 60 https://x.ai/cli/install.sh -o /tmp/grok-install.sh; then
            chown 1000:1000 /tmp/grok-install.sh
            if ! timeout 120 as_coder bash /tmp/grok-install.sh >>"$install_log" 2>&1; then
                echo "WARNING: grok install failed. See /core/grok-install.log" | tee -a "$install_log" >&2
            fi
            rm -f /tmp/grok-install.sh
        else
            echo "WARNING: could not download https://x.ai/cli/install.sh" | tee -a "$install_log" >&2
        fi
        chown 1000:1000 "$install_log" 2>/dev/null || true
    fi
    link_managed grok
    link_managed agent
    if [ -L /core/bin/grok ] || [ -x /core/bin/grok ]; then
        ln -sfn /core/bin/grok /usr/local/bin/grok
    fi
    if [ -e /core/bin/agent ]; then
        ln -sfn /core/bin/agent /usr/local/bin/agent
    fi
    if [ -d /core/completions ] && ! grep -q '/core/completions' /home/coder/.zshrc 2>/dev/null; then
        cat >> /home/coder/.zshrc << 'EOF'
fpath=(/core/completions $fpath)
autoload -Uz compinit && compinit
EOF
        chown 1000:1000 /home/coder/.zshrc
    fi
    if [ ! -f /utilities/mise/.bootstrapped ]; then
        echo "Bootstrapping ripgrep, fd, uv, node into /utilities ..."
        if timeout 300 as_coder mise use -g ripgrep@latest fd@latest uv@latest node@lts; then
            as_coder touch /utilities/mise/.bootstrapped
        else
            echo "WARNING: mise bootstrap failed. Install tools later with: mise use -g <tool>@latest" >&2
        fi
    fi
) &

cleanup() {
    if [ -n "${ttyd_pid:-}" ]; then
        pkill -TERM -P "$ttyd_pid" 2>/dev/null || true
        kill "$ttyd_pid" 2>/dev/null || true
    fi
    if [ -n "${nginx_pid:-}" ]; then
        kill "$nginx_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM
wait -n "$ttyd_pid" "$nginx_pid"
status=$?
cleanup
wait || true
exit "$status"
