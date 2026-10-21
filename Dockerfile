FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
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
    PATH="/core/bin:/utilities/mise/shims:/utilities/cargo/bin:/utilities/uv/tools/bin:/utilities/npm/bin:/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        unzip \
        xz-utils \
        zstd \
        gzip \
        jq \
        tmux \
        zsh \
        fzf \
        locales \
        nginx \
        apache2-utils \
    && printf 'en_US.UTF-8 UTF-8\n' > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && curl -fsSL https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod 755 /usr/local/bin/ttyd \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin \
    && curl -fsSL https://mise.jdx.dev/install.sh | MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Entrypoint is root only so it can chown bind-mounted volumes, then drops to coder.
RUN groupadd -g 1000 coder \
    && useradd -m -u 1000 -g 1000 -s /usr/bin/zsh coder \
    && mkdir -p /core/bin /utilities /skills /projects /terminal /app \
    && chown -R 1000:1000 /core /utilities /skills /projects /terminal /app /home/coder

# Hard-block apt for every user, including absolute /usr/bin/apt paths.
RUN printf '%s\n' \
      '#!/usr/bin/env bash' \
      'echo "ERROR: apt is disabled in this container. You MUST install all languages, runtimes, and CLI tools into /utilities using: mise use -g <tool>@latest" >&2' \
      'exit 1' \
      > /usr/local/bin/apt \
    && cp /usr/local/bin/apt /usr/local/bin/apt-get \
    && cp /usr/local/bin/apt /usr/bin/apt \
    && cp /usr/local/bin/apt /usr/bin/apt-get \
    && chmod 755 /usr/local/bin/apt /usr/local/bin/apt-get /usr/bin/apt /usr/bin/apt-get

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY tab.sh /app/tab.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY terminal/ /opt/terminal-defaults/
RUN chmod 755 /usr/local/bin/entrypoint.sh /app/tab.sh \
    && chown -R 1000:1000 /app /opt/terminal-defaults

WORKDIR /projects
EXPOSE 7681
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
