# Herdr + Radar on Macs

## New Mac

Prerequisites: macOS, Node 18+, Herdr 0.9.0+ (CLI **and running server**), and GNU Stow for the other dotfile packages. This script does not install runtimes, upgrade Herdr, or stop any server.

From the dotfiles checkout:

```sh
make stow-herdr        # offline: local main config + synced Radar preferences
make stow-wezterm      # if using WezTerm; retains existing Nerd Font
# make stow-ghostty    # if using Ghostty
# make stow-kitty      # if using kitty
```

Open Herdr once, then run this in a shell in its **default local session**:

```sh
make setup-herdr
make check-herdr
```

Full setup installs Radar 1.4.4 pinned to reviewed commit
`dd42772da4b8b9e18660d653d08149c7da1d2964`, ensures it is enabled, installs its user icon font, configures local sidebar/tab-bar/theme blocks, and verifies daemon health and agent labels. No Radar-specific integration is needed in Command Palette: it discovers installed actions.

An existing Radar registration with another source or commit is refused, not replaced. Review and manage upgrades explicitly before changing the pin. Command Palette installation and other plugins are not managed by this script.

In Herdr's global menu choose **reload config** for client-side layout/keys. New terminal windows pick up fonts; do not restart Herdr or close panes just to install Radar.

## Ownership and syncing

| Tracked file | Live destination / behavior |
| --- | --- |
| `herdr/.config/herdr/config.toml` | Copied to `~/.config/herdr/config.toml`; generated blocks and local UI changes stay on this Mac. |
| `herdr/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml` | Individually symlinked to the same path under `~`; popup preference edits are reviewable repo changes. |
| `wezterm/.wezterm.lua` | Stowed; supplies `Herdr Agent Icons Max` fallback while retaining the primary Nerd Font. |
| `ghostty/.config/ghostty/config` | Stowed if used; Radar PUA codepoint maps. |
| `kitty/.config/kitty/kitty.conf` | Stowed if used; Radar PUA symbol maps. |

Do **not** run `stow herdr` directly. The Makefile deliberately excludes Herdr from normal Stow and uses the deployment script. Do not Stow or symlink the entire live `~/.config/herdr` directory into the repo: it also contains downloaded plugins, sessions and sockets.

The script migrates an exact old baseline-file symlink safely, copying its contents before replacement. An equivalent existing preference file is backed up and linked; differing config/preferences or foreign links require explicit replacement consent:

```sh
# First inspect the reported file and any differences.
bash scripts/setup-herdr-mac.sh --deploy-only --replace-config
# Or deploy + apply in one step:
make setup-herdr HERDR_SETUP_ARGS=--replace-config
```

Backups: `~/.local/state/dotfiles-mac/herdr/backups/`.
Deployment bookkeeping: `~/.local/state/dotfiles-mac/herdr/deployment.json`.
An unchanged baseline preserves live main-config edits across repeated runs. A changed baseline requires `--replace-config` to replace that local config, with a backup; this is not an automatic merge. Put desired cross-machine main-config changes into the tracked baseline, not just the live copy.

After pulling Radar preference changes, run `make setup-herdr`. Changed preferences cause only Radar to stop/restart, with stop completion checked before start. Unchanged preferences and a healthy daemon do not restart it. If configure fails after stopping Radar, setup reports the failure and leaves it stopped for inspection; do not restart Herdr to recover.

`make unstow-herdr` removes only the owned preference symlink. It retains local config, plugin registration and runtime; **it is not a plugin uninstall**. Run setup again to restore the symlink. Full `make unstow` uses the same safe behavior for Herdr.

Local only, never commit: plugin registry/checkouts, sessions, sockets, PIDs, logs, installed `.ttf` files, activity history, setup stamps, tab-bar caches, and Radar's `agent-view.on` mode. Active/Recent stays local; a fresh installation defaults to Active. A mode flip is not a synced preference.

XDG config/state or `HERDR_CONFIG_PATH` overrides, foreign parent-directory symlinks, and non-default session/socket contexts are refused rather than risk writing to the wrong place. Other named sessions may use Radar, but this bootstrap applies/restarts only the default session; an existing named session needs its own Radar state-start after settings change.

## Controls

Your prefix is **Ctrl+A**, followed by the next key (not held together):

- **b**: toggle Herdr's sidebar (default compact rail when collapsed).
- **a**: Radar Active (grouped) / Recent (flat).
- **comma**: Radar settings.
- **Cmd+Shift+P**, search **`>settings`** or **`>radar`**: Command Palette's Radar Settings action. Its existing popup handoff may race and report `ui_busy`.

Without a keybinding:

```sh
herdr plugin action invoke hhdebb.herdr-radar.settings
```

Popup: arrows select/change, Enter edits text, `r` resets an option, `s` saves/applies, `q` closes. Saving restarts only Radar, not Herdr. Review and commit the preference diff to sync it.

Default tracked preferences: `row_label = "tab"`: named nonnumeric tabs win, otherwise the agent title, otherwise vendor name. Old Auto Title-generated names count as named until cleared; Radar does not rename tabs. `follow_appearance = false` makes Radar follow Herdr's selected theme rather than macOS light/dark mode, keeping sidebar colours legible with the dark terminal default.

## Verify / troubleshoot

```sh
make check-herdr
herdr plugin list
herdr plugin log list --plugin hhdebb.herdr-radar --limit 20
wezterm ls-fonts --codepoints e1a9,e1c2
```

WezTerm should resolve both codepoints to **Herdr Agent Icons Max**, not STIX Two Math. Installation writes maps for Ghostty/kitty only when those configs exist, so Stow the terminal config before setup. A fallback works for the current JetBrains Nerd Font; if the primary font itself claims Radar's PUA range, inspect resolution before changing fonts.

Idle Pi panes predating Radar may lack `sort_key` until activity is observed. The pinned source deliberately omits that key with no activity stamp; workspace/tab sort keys and title tokens plus daemon health are checked instead.

Tests (no real server or font changes):

```sh
bash tests/setup-herdr-mac.sh
```

Upstream: https://github.com/hhdebb/herdr-radar
