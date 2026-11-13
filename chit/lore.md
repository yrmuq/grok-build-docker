## Protected Areas

- Do not add AppImage, Flatpak, or a desktop layout to the README or CI unless the maintainer explicitly asks, because they excluded those packages on 2026-11-13 and this repository ships only the container.
- Do not replace the terminal palettes with System, Light, and Dark modes unless the maintainer explicitly asks, because they kept the grok `/theme` palettes on 2026-11-13.

## Required Behavior

- Name a new terminal tab with the next free `chatN` from the tmux session list and connect with `--session`; do not take the name from the ttyd window title and do not use a blocking allocator, because the first title is the script path and the allocator call did not return.
- Leave the Projects menu unchanged unless the listing contains `__PROJECTS_END__`, because a truncated reply is empty and used to wipe the menu.
- Deliver Ctrl+C to the terminal when nothing is selected so grok can be interrupted; copy and swallow that key only while a selection exists, because the maintainer kept the interrupt.
- Send `cd` and `grok` from `--project-go` only when the pane command is `zsh`, `bash`, or `sh`, because those keys must not be typed into a running grok session.
- When `/terminal/index.html` lacks the current marker, or `/terminal/themes/.pack` is not the shipped pack id, replace those shipped files on startup so an image update reaches the volume; do not treat that replacement as accidental data loss.
- Publish the image only as `dev` from branch `dev` and `latest` from a stable `main` release; a `dev` publish must not move `latest`, because the maintainer asked for these two tags on 2026-11-13.

## Compatibility Workarounds

- Keep `--insecure-storage` on `gh auth login` and `gh auth refresh` through the wrapper that is first on `PATH`, because this container has no keyring that survives a new shell; remove it only if a keyring both survives and still stores the token on `/core`.

## External Compatibility Constraints

- Do not put the `grok` binary in the git tree or in image layers; the first start downloads it into `/core`, because this unofficial image must not redistribute that CLI.
