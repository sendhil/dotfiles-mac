# Ghostty on this Mac

## Base configuration

`ghostty/.config/ghostty/config` is stowed to `~/.config/ghostty/config`.
It keeps TokyoNight Storm, JetBrainsMono Nerd Font Mono at 23 points,
20% extra cell height, the blue cursor, and Herdr/Radar icon mappings.
Ghostty's native titlebar and standard split/font-size shortcuts are retained.

- **Cmd+D / Cmd+Shift+D:** split right / down.
- **Ctrl+Shift+P:** Ghostty's command palette, including Change Tab Title.
- **Cmd+Shift+P / Up / Down:** not intercepted by Ghostty, so Herdr can use them.
- **Cmd+Shift+,**: reload the configuration.

Close confirmation is disabled, matching the WezTerm config. Closing a
terminal can therefore terminate running work without a warning.

The redundant macOS Application Support config was backed up and removed.
The migration backups are in
`~/.local/state/dotfiles-mac/ghostty/backups/migration.S3eMP3/`.
Do not add a second copy of the Radar font mappings to
`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
Ghostty loads both locations and later macOS settings can override the stowed base.

## Theme controls

### Native theme browser

At a **shell prompt**, open **Ctrl+Shift+P**, search **Browse Themes**, and
select it. This launches Ghostty's built-in `+list-themes` browser in the
active pane. **F1** shows its controls; **Escape** exits. Reload the config
with **Cmd+Shift+,** after installing the palette entry.

The palette entry is a `text:` macro: it sends the command followed by Enter,
not an independent process launch. Do **not** invoke it while an agent,
editor, or another TUI is receiving input. The native browser is separate
from the local-persistence helper below.

### Optional favorites and persistence helper

The earlier custom favorites picker remains available, but is not used by
the Browse Themes palette entry. Run these helper commands from a normal shell:

```sh
# Search the curated favorites; Enter applies, Escape cancels.
~/.config/ghostty/theme.sh

# Toggle TokyoNight Storm / TokyoNight Day.
~/.config/ghostty/theme.sh toggle
# The original entry point remains supported:
~/.config/ghostty/toggle-theme.sh

# Select a favorite explicitly, show the current selection, or reset.
~/.config/ghostty/theme.sh set "Catppuccin Mocha"
~/.config/ghostty/theme.sh current
~/.config/ghostty/theme.sh reset
```

Favorites cover TokyoNight, Catppuccin, Solarized, One, Nord, Rose Pine,
Kanagawa, Everforest, Nightfox, and Ayu. Only themes available in the
installed Ghostty are offered. Ghostty's independent all-theme preview
remains available through `ghostty +list-themes`.

Selections are stored in
`~/.local/state/dotfiles-mac/ghostty/theme.ghostty`, outside this repository.
The base config includes this file optionally; `reset` removes it and
returns to the tracked base default. Choosing a theme does not rewrite the
base config or replace its symlink. A candidate is validated before it
atomically replaces the prior selection. Cancellation or failed validation
preserves the last good selection.

Selections persist across launches and apply **across Ghostty**, not just
one window. The toggle changes Day to Storm, and any other theme to Day.
Storm and Day get matching blue cursors; other favorites use their theme's
cursor default instead of inheriting Storm's explicit blue.

When Ghostty is running, the helper requests reload through its native
AppleScript action interface. It never sends text or simulated keystrokes
to a terminal, and does not start Ghostty for reload. macOS may request
Automation permission. If automation is denied or reload cannot be
performed, the selection remains saved and the helper asks you to press
**Cmd+Shift+,** manually.

`GHOSTTY_BIN` can select an alternate Ghostty executable. Otherwise the
helper looks on PATH, then at the installed macOS application binary.
`fzf` is required only for the interactive picker.

Herdr's own theme remains independent. Its current `auto_switch = false`
and Radar's `follow_appearance = false` are unchanged; choosing a light
Ghostty theme will not automatically switch Herdr to a light theme.

## Verification

```sh
bash tests/ghostty-theme.sh
bash -n ghostty/.config/ghostty/theme.sh ghostty/.config/ghostty/toggle-theme.sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-face --cp=0xe1a9
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-face --cp=0xe1c2
```

The tests use isolated temporary home directories and mock the macOS
automation boundary. They also exercise real Ghostty configuration parsing.
They do not change the live theme, launch Ghostty, or contact Herdr. Icon
resolution and native automation/interactive UI behavior are separate checks.
The suite requires Node and the installed macOS Ghostty CLI.

