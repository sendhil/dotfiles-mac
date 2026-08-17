# Walker Launcher and Smart Gaps Design

## Goal

Replace the limited Wofi launcher with Walker so `Alt+Space` provides one
Alfred-like surface for applications, clipboard history, snippets, and Chrome
bookmarks; make Sway remove all workspace-edge gaps for a single tiled window.

## Launcher Design

`linux-laptop-setup` installs pinned official amd64 releases of Walker 2.17.0,
Elephant 2.22.0, and the desktop-applications, bookmarks, clipboard, snippets,
and provider-list providers.  Every archive is downloaded from its official
GitHub release URL and verified against a committed SHA-256 before extraction.
The installation is per-user under XDG data and exposes only the required
commands through `~/.local/bin`.

The dotfiles repository owns the Walker configuration, user services, and
launcher binding.  It replaces the Wofi Stow package, preserves `Alt+Space`,
and starts Walker's background services in the graphical Sway session.

Walker does not currently import Chrome bookmarks.  A small local bridge reads
all Chrome-profile `Bookmarks` JSON files below `~/.config/google-chrome`,
emits title-and-URL entries, and opens a selected URL with `xdg-open`.  It does
not write browser data, require Chrome to be closed, or copy browser profiles.

## Smart Gaps Design

The Sway configuration sets equal 6-pixel inner and outer gaps, with Sway's
`smart_gaps on`.  A workspace with one tiled window therefore has no visible
edge gap; a workspace with two or more tiled windows keeps its 6-pixel inner
and outer spacing.

## Verification

Shell tests first assert the pinned assets, checksum verification, expected
user-service/config wiring, Chrome bookmark bridge behavior, and the Sway gap
directives.  Tests use fake commands and temporary homes only; they never
install software or modify a Linux machine.
