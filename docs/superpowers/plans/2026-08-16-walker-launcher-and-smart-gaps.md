# Walker Launcher and Smart Gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an Alfred-like Walker launcher on Ubuntu and smart Sway gaps.

**Architecture:** The Linux setup repository owns verified user-level Walker and Elephant binaries; the dotfiles repository owns the selected desktop configuration, `Alt+Space` binding, and read-only Chrome bookmark bridge. Sway owns the presentation rule through `smart_gaps on`.

**Tech Stack:** Bash, GNU Stow, systemd user services, Sway, Walker, Elephant, jq.

## Global Constraints

- Install only official pinned amd64 archives after SHA-256 verification.
- Never mutate a Chrome profile; discover every profile under `~/.config/google-chrome`.
- Do not install or run Linux setup software from this macOS workspace.
- Preserve `Alt+Space` as the launcher shortcut.
- Keep 6-pixel gaps only when a workspace has more than one tiled window.

---

### Task 1: Verified Walker runtime installer

**Files:**
- Create: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/bin/install-walker`
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/bin/setup-work-laptop`
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/tests/setup_work_laptop_test.sh`
- Create: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/tests/walker_install_test.sh`

**Interfaces:**
- Produces `~/.local/bin/walker` and `~/.local/bin/elephant`, with providers in an XDG-data-managed directory.
- Consumes only official fixed GitHub asset URLs and the committed SHA-256 constants.

- [ ] **Step 1: Write failing tests**

Assert that the installer rejects a mismatched archive checksum before extraction, installs all five named providers into its managed directory from fake verified archives, and that `setup-work-laptop` executes `install-walker` after `install-work-tools`.

- [ ] **Step 2: Verify red**

Run: `./tests/walker_install_test.sh && ./tests/setup_work_laptop_test.sh`

Expected: failure because `bin/install-walker` and its coordinator stage do not exist.

- [ ] **Step 3: Implement minimal installer**

Implement a non-root amd64-only installer patterned after the existing Go archive installer: preflight owned paths, download exact assets, verify SHA-256, reject unsafe archive members, stage extraction, atomically activate files, and link `walker`/`elephant` into `~/.local/bin`.

- [ ] **Step 4: Verify green**

Run: `./tests/walker_install_test.sh && ./tests/setup_work_laptop_test.sh`

Expected: both pass using only fake commands, archives, and temporary homes.

### Task 2: Walker configuration and Chrome bookmark bridge

**Files:**
- Create: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/walker/.config/walker/*`
- Create: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/bin/.local/bin/walker-chrome-bookmarks`
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/scripts/package-set.sh`
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/sway/.config/sway/config`
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/tests/package_sets_test.sh`
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/tests/sway_config_test.sh`
- Create: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/tests/walker_bookmarks_test.sh`

**Interfaces:**
- `walker-chrome-bookmarks` writes newline-delimited title-and-URL choices from all Chrome profile bookmark JSON files and invokes `xdg-open` only for a selected URL.
- Sway executes `walker` on `Alt+Space`.

- [ ] **Step 1: Write failing tests**

Create temporary Chrome `Default` and `Profile 1` fixtures, assert both bookmarks are discoverable, assert malformed/missing files are skipped, and assert no bookmark source is modified. Assert the Ubuntu package set selects `walker`, Sway invokes Walker on `Alt+Space`, and no selected Wofi package remains.

- [ ] **Step 2: Verify red**

Run: `./tests/walker_bookmarks_test.sh && ./tests/package_sets_test.sh && ./tests/sway_config_test.sh`

Expected: failure because the bridge, Walker package, and Sway wiring are absent.

- [ ] **Step 3: Implement minimal configuration**

Add the Walker Stow package and user-service configuration for Elephant plus clipboard/snippets providers. Add the bridge using `jq` and `find`, exposing every Chrome profile bookmark title and URL without writes. Replace Wofi in the Ubuntu package selection and point `$menu` to `walker`.

- [ ] **Step 4: Verify green**

Run: `./tests/walker_bookmarks_test.sh && ./tests/package_sets_test.sh && ./tests/sway_config_test.sh && ./tests/sway_desktop_test.sh`

Expected: all tests pass.

### Task 3: Smart Sway gaps

**Files:**
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/sway/.config/sway/config`
- Modify: `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup/tests/sway_config_test.sh`

**Interfaces:**
- Produces Sway directives `gaps inner 6`, `gaps outer 6`, and `smart_gaps on`.

- [ ] **Step 1: Write failing test**

Require the exact equal inner/outer 6-pixel gap directives and `smart_gaps on`.

- [ ] **Step 2: Verify red**

Run: `./tests/sway_config_test.sh`

Expected: failure because outer gaps are zero and smart gaps are not enabled.

- [ ] **Step 3: Implement minimal Sway change**

Set `gaps outer 6` directly beside the existing inner-gap directive and add `smart_gaps on`.

- [ ] **Step 4: Verify green**

Run: `./tests/sway_config_test.sh`

Expected: pass.

### Task 4: Full regression and docs

**Files:**
- Modify: relevant README/checklist in each repository if they name Wofi or omit the new post-login launcher behavior.

- [ ] **Step 1: Write failing documentation assertion**

Require supported Ubuntu documentation to describe Walker, `Alt+Space`, Chrome-bookmark search, snippets, clipboard history, and `swaymsg reload` after a dotfiles update.

- [ ] **Step 2: Verify red**

Run each repository's focused documentation test.

- [ ] **Step 3: Write concise operational documentation**

Document that the first `setup-work-laptop` run installs verified user-local Walker assets, and that the user reloads Sway then launches with `Alt+Space`.

- [ ] **Step 4: Verify green**

Run: `./tests/run` in `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup` and `./tests/run` in `/Users/sendhil/src/dotfiles-mac/.worktrees/ubuntu-cross-platform-setup`.

Expected: both full suites pass.
