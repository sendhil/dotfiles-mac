# Portable Herdr Radar Implementation Plan

> Execute directly in this session; delegation is not authorized. Approved design: `docs/superpowers/specs/2026-10-12-portable-herdr-radar-design.md`.

**Goal:** Reproduce Radar preferences and fonts across Macs without syncing session state or machine-generated config.

**Architecture:** Shell entry point running dependency-free Node filesystem/CLI orchestration. Main config is a local copy; Radar preferences are an individually owned symlink. Herdr plugin actions are polled to terminal status before dependent actions.

**Tech Stack:** Bash, Node >=18, Herdr >=0.9.0, GNU Make/Stow; shell test entry point with Node tests and fake CLI.

## Global constraints

- macOS only; reject custom XDG/config paths rather than target a wrong session.
- Radar commit `dd42772da4b8b9e18660d653d08149c7da1d2964` (1.4.4).
- Never stop/kill Herdr or modify pane topology.
- Do not overwrite unexpected registrations; differing config replacement is opt-in and backed up.
- Preserve unrelated worktree edits. Do not commit without owner request.

### Task 1: Deployment and action lifecycle

Files: `scripts/setup-herdr-mac.sh`, `tests/setup-herdr-mac.sh`, new tracked Radar preferences; existing baseline and Makefile.

- [x] Write isolated temporary HOME tests that spawn the real setup script with fake `herdr` and `uname` executables; assert exact resulting files/links, backup contents, command ordering, error handling, and no destructive server calls.
- [x] Run `bash tests/setup-herdr-mac.sh`; expect missing-script failure before implementation.
- [x] Implement Node orchestration inside the shell script: bounded CLI calls, JSON envelopes, version validation, ownership/backup checks, atomic replacement, action completion gates and Radar control socket health checks.
- [x] Route `make stow` and `make stow-herdr` around Stow for Herdr; keep other packages unchanged. Add explicit full setup/check targets.
- [x] Store `row_label = "tab"`; remove generated blocks from baseline only after current config is safely copied out of its existing symlink.
- [x] Rerun suite until green; run `bash -n`, `git diff --check`, and dry-run Makefile targets.

### Task 2: Documentation and live migration

Files: `herdr/README.md`, root `README.md`; live files outside repo.

- [x] Explain fresh-Mac deployment/full setup, prerequisites, backups and conflict flags, config ownership, version pin, no runtime sync, font verification, named session scope, shortcuts, and palette settings.
- [x] Back up current main config and preferences to local state, detach exact main symlink atomically without changing its source, then clean baseline and run full setup.
- [x] Verify local main config regular file, preferences exact symlink, `herdr config check`, Radar health and labels, same live agent pane IDs, and `wezterm ls-fonts --codepoints e1a9,e1c2`.
- [x] Rerun setup/check and verify tracked baseline is untouched; inspect final scoped diff. Report commands, modified files, and any remaining limitations.
