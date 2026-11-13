## Protected Areas

- Do not add a `dev` branch, pull requests, `release.yml`, version tags, or Dependabot; keep integrating and publishing the image from `main`, because the maintainer accepted that flow on 2026-11-13.
- Do not add `languages/` or translate the terminal UI unless the maintainer explicitly asks, because that same review left the page in English.
- Do not restructure `README.md` into a desktop, AppImage, or Flatpak layout unless the maintainer explicitly asks, because that review kept the container-only document.

## Required Behavior

- Name a new terminal tab with the next free `chatN` from the tmux session list and connect with `--session`; do not take the name from the ttyd window title and do not use a blocking allocator, because the first title is the script path and the allocator call did not return.
- Leave the Projects menu unchanged unless the listing contains `__PROJECTS_END__`, because a truncated reply is empty and used to wipe the menu.
- Deliver Ctrl+C to the terminal when nothing is selected so grok can be interrupted; copy and swallow that key only while a selection exists, because the maintainer kept the interrupt.
- Send `cd` and `grok` from `--project-go` only when the pane command is `zsh`, `bash`, or `sh`, because those keys must not be typed into a running grok session.
- When `/terminal/index.html` lacks the current marker, or `/terminal/themes/.pack` is not the shipped pack id, replace those shipped files on startup so an image update reaches the volume; do not treat that replacement as accidental data loss.

## Compatibility Workarounds

- Keep `--insecure-storage` on `gh auth login` and `gh auth refresh` through the wrapper that is first on `PATH`, because this container has no keyring that survives a new shell; remove it only if a keyring both survives and still stores the token on `/core`.

## External Compatibility Constraints

- Do not put the `grok` binary in the git tree or in image layers; the first start downloads it into `/core`, because this unofficial image must not redistribute that CLI.
