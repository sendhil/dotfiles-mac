# SketchyBar Sync Implementation Plan

> Execute inline in this session; the user approved the Stow/package/script design and requested a 12-hour clock.

**Goal:** Reproduce the approved Mocha bar from dotfiles with one repeatable command.

**Architecture:** Stow owns the theme and AeroSpace configuration. A shell entrypoint locates Python; a standard-library installer installs missing dependencies, snapshots existing machine state, links the packages, generates per-user launch agents, and enables menu autohide. Runtime caches and backups live under the user's Library, outside Git.

**Tech Stack:** Bash, Python 3.9+, GNU Stow, Homebrew, launchd, SketchyBar, AeroSpace.

## Global Constraints

Preserve the approved theme, corrected audio spacing, no Apple shortcut, current bindings and monitor assignments. Use 12-hour time with AM/PM. No global Homebrew upgrade; never copy user-specific service paths. Keep the exact app-icon font and its matching mapping together. Do not alter unrelated dotfiles or untracked .pi content.

## Tasks

- [x] Package live theme, replace hardcoded executables with PATH resolution, place runtime caches under Library/Caches, load vendored app font, add portable event hook.
- [x] Write failing temporary-home tests for first install/rerun/restore, preserving symlinks, rejecting changed files during restore, and generated launch-agent paths. Run existing workspace projection tests.
- [x] Implement dependency manifest and shell/Python setup with --check and --restore. Snapshot config, relevant preferences and owned agents; keep a durable original snapshot on rerun. Install only missing dependencies. Require clean stow simulation before starting services.
- [x] Add README first-install/update/check/restore instructions, known-tested dependency versions, manual macOS permissions, and display-specific gap/assignment guidance. Register sketchybar in Makefile.
- [x] Validate shell syntax, Python tests, stow dry run, fresh-home install/restore simulation. Apply to actual repo, run setup twice, check live clock/workspaces/helper and clean service logs. Review final diff.

Expected command: python3 -m unittest discover -s tests -v. Expected result: all installer round-trip tests and six workspace projection tests pass. Live verification must show an AM/PM clock, package symlink to the actual dotfiles checkout, running launch agents, and both auto-hide preferences matching Always.

## Validation result

15 tests passed, including real-Stow install/rerun/restore against a temporary home with spaces. Live setup rerun retained the same original backup. Readiness polling resolves the observed asynchronous startup race. Live --check passes; clock shows AM/PM; workspace 24 event highlighted immediately and original workspace was restored. Service error logs were empty. External monitors and a second physical Mac remain untested.
