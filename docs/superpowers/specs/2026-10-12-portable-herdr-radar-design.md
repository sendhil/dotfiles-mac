# Portable Herdr Radar setup for Macs

Approved in chat on 2026-10-12: track portable Herdr/Radar/terminal preferences and provide a repeatable Mac setup script. Do not stop Herdr, kill its processes, or touch unrelated dotfiles.

## Ownership

- `herdr/.config/herdr/config.toml` is a portable baseline, not the live config symlink. Preserve existing keys and Radar shortcuts; omit Radar's generated blocks and absolute user paths.
- The deployed `~/.config/herdr/config.toml` is a local regular file. Radar may write its sidebar/theme/tab-bar blocks here without dirtying the checkout.
- `herdr/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml` is symlinked individually. Start with `row_label = "tab"`; settings saved through Radar are reviewable repo changes.
- Existing WezTerm fallback and Ghostty/kitty mappings are portable and retained. Fonts and plugin installations are local, not versioned.
- Active/Recent mode, sessions, logs, sockets, PIDs, plugin registry, and activity caches are not synced.

## Deployment contract

`scripts/setup-herdr-mac.sh` checks macOS and Node >=18; full setup also checks Herdr CLI and running server >=0.9.0. Pin Radar 1.4.4 to commit `dd42772da4b8b9e18660d653d08149c7da1d2964`. Refuse unexpected plugin sources/versions and config destinations. Never install language runtimes or upgrade Herdr implicitly.

Modes: default full setup; `--deploy-only` offline dotfile deployment; `--check` read-only verification; `--unlink-preferences` remove only the owned preference symlink. `--replace-config` explicitly authorizes backed-up replacement of differing local config/preferences, not a conflicting plugin registration.

Recognize and safely migrate the existing exact baseline symlink. Back up before replacement and atomically replace links/files without writing through the old link. On repeated runs preserve local main-config edits if the tracked baseline is unchanged. Applying a changed baseline to a populated local config requires `--replace-config` and creates a backup.

Full setup deploys first, ensures pinned plugin enabled, installs/maps fonts, stops only Radar and waits for action completion plus daemon shutdown, configures local blocks, starts only Radar and verifies healthy state and live agent tokens. Failure is reported, not treated as successful asynchronous invocation. No shell-command or child-process fallback that bypasses Herdr action lifecycle. A fresh machine must launch Herdr once before full plugin setup; offline deployment is independent.

GNU Stow handles all existing packages except Herdr. `make stow-herdr` deploys only; `make setup-herdr` performs full setup; `make check-herdr` verifies; unstow leaves local main config and live runtime alone.

## Verification

Use isolated temporary HOME/checkouts and fake Herdr/OS CLI boundaries. Test fresh deployment, own-symlink migration, conflicting file/symlink refusal, explicit replacement/backups, repeat no-op, changed-baseline protection, XDG/override rejection, Node/Herdr version floors, wrong plugin source/version, asynchronous action errors, shutdown-before-start, no server stop/kill, and Makefile routing. Verify real config parses, preference symlink, healthy Radar, correct WezTerm glyph font, preserved agent pane IDs, and unchanged repo baseline across a repeat run.
