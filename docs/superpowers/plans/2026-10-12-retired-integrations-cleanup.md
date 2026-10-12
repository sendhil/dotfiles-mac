# Retired Integrations Cleanup Implementation Plan

**Goal:** Remove unused OpenCode/cmux repository integrations and repair tmux plugin metadata.

**Architecture:** Delete retired tools/configs and their callers; keep TPM as ordinary tracked files and retain four active plugin gitlinks with exact GitHub mappings. Remove the unused Nord theme gitlink.

**Tech Stack:** Git, Python unittest, shell, Lua, GNU Make.

## Global Constraints

- User approved removing retired integrations and Nord on 2026-10-12.
- Preserve installed apps, session databases, private `~/.bash_local`, and live tmux sessions.
- Preserve Ghostty, WezTerm theme/Herdr controls, and vendored TPM.
- Do not run deployment, plugin update, or recursive submodule initialization against the live checkout.

## Steps

- [x] Add `tests/test_repository_cleanup.py`: assert retired files/callers are absent and `.gitmodules` maps exactly the four tracked gitlinks; verify TPM remains tracked ordinary files.
- [x] Run `python3 -m unittest discover -s tests -p test_repository_cleanup.py` and observe failures for the existing retired integrations and mismatched metadata.
- [x] Delete `bin/.local/bin/{opencode-sessions,cmux-scratch,cmux-scratch.swift}`, both files in `cmux/.config/cmux/`, and `tmux/.tmux/plugins/tmux` gitlink.
- [x] Remove `oc-active-sessions` from `bash-linux/.bash/utilities`, the OpenCode palette entry from `wezterm/.wezterm.lua`, and `cmux` package plus `build-bin` target from `Makefile`.
- [x] Replace stale TPM mapping with mappings for `tmux-jump`, `tmux-yank`, `tokyo-night-tmux`, and `vim-tmux-navigator`, using their upstream HTTPS GitHub URLs.
- [x] Run regression tests, all Python tests, Herdr setup tests, shell syntax checks, active LSP diagnostics, `git submodule status`, and `git diff --check`. No live reloads or tool installation.
- [ ] Review scoped diff; commit and push. Verify local and remote master match and working tree is clean.
