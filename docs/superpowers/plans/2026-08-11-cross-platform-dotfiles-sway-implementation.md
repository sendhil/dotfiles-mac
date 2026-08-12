# Cross-platform Dotfiles and Sway Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert `dotfiles-mac` into an explicitly targeted cross-platform dotfiles repository and add a complete Sway user environment without regressing macOS.

**Architecture:** GNU Stow packages are divided into common, macOS, Ubuntu, and Sway sets selected through tested scripts and Make targets. Shared shell/multiplexer configuration sources one platform fragment installed by the selected platform package. Sway uses small companion configs plus testable helper scripts to mirror the current AeroSpace workflow while GNOME remains outside repository ownership.

**Tech Stack:** GNU Make, GNU Stow, Bash/Zsh, Sway, Waybar, Fuzzel, Mako, Kitty, tmux, Zellij

## Global Constraints

- Work in `/Users/sendhil/src/dotfiles-mac`.
- Keep `pre-linux-2026-08-11` resolving to `01b0c7035e39f481a0d87ff2e3976c15716cb411`.
- Run this plan only after the Ubuntu setup plan passes; that repository owns dependency installation.
- `make stow-macos` links common plus macOS packages; `make stow-ubuntu` links common plus Ubuntu/Sway packages.
- A read-only preflight must run before Stow mutation. Do not use the destructive `scripts/clear-out-files-before-stow.sh` workflow.
- Shared/Ubuntu-linked configuration must contain no `/opt/homebrew`, `~/Library`, `/Users/sendhil`, AppleScript, `defaults`, CMUX, AeroSpace, or Command-key-only behavior. The portable `dotfiles-copy` dispatcher is the sole allowed shared reference to `pbcopy`.
- Hammerspoon is retired and removed.
- Zsh is the intended interactive shell; Bash remains usable. Do not change the account login shell automatically.
- Sway mirrors `Alt+h/j/k/l`, movement, workspaces 1–20, back-and-forth, scratchpad, resize, output mode, floating, and app routing.
- Add `Alt+Enter`, `Alt+d`, and `Alt+f`; keep `Alt+Shift+f` as a compatibility alias.
- Do not hardcode the Mac monitor names on Linux.
- GNOME/GDM, packages, drivers, and workplace applications remain outside this repository.
- Use red-green-refactor and one focused commit per task.

---

## Planned file map

- `scripts/package-set.sh`: canonical platform-to-package mapping.
- `scripts/stow-preflight.sh`: read-only platform validation and Stow simulation.
- `Makefile`: explicit macOS/Ubuntu link and unlink commands.
- `tests/*.sh`: temporary-home, fake-Stow, portability, binding, and documentation tests.
- `bash-linux/`: shared shell entry points and portable shell fragments.
- `shell-macos/`, `shell-ubuntu/`: one selected `~/.config/dotfiles/platform.sh`.
- `bin/.local/bin/dotfiles-copy`: clipboard adapter for macOS, local Wayland, and SSH/OSC 52.
- `kitty/`: portable base; `kitty-macos/`, `kitty-ubuntu/`: platform key fragments.
- `sway/`: compositor config and workspace/scratchpad helpers.
- `waybar/`, `fuzzel/`, `mako/`, `swaylock/`: companion configuration.
- `docs/ubuntu-first-login.md`: dotfiles-specific session and binding checklist.
- `README.md`: cross-platform usage and recovery instructions.

### Task 1: Explicit platform package selection and non-mutating preflight

**Files:**
- Create: `scripts/package-set.sh`
- Create: `scripts/stow-preflight.sh`
- Create: `tests/test_helper.sh`
- Create: `tests/package_sets_test.sh`
- Create: `tests/preflight_test.sh`
- Create: `tests/run`
- Create: `bin-macos/.stow-local-ignore`
- Create: `shell-macos/.stow-local-ignore`
- Create: `shell-ubuntu/.stow-local-ignore`
- Create: `kitty-macos/.stow-local-ignore`
- Create: `kitty-ubuntu/.stow-local-ignore`
- Create: `sway/.stow-local-ignore`
- Create: `waybar/.stow-local-ignore`
- Create: `fuzzel/.stow-local-ignore`
- Create: `mako/.stow-local-ignore`
- Create: `swaylock/.stow-local-ignore`
- Create: `xdg-portal/.stow-local-ignore`
- Modify: `Makefile`

**Interfaces:**
- Produces `common_packages`, `macos_packages`, `ubuntu_packages`, and `packages_for PLATFORM`.
- Produces `scripts/stow-preflight.sh PLATFORM TARGET`, which validates and invokes `stow --simulate --no-folding --target TARGET PACKAGES...`.
- Produces Make targets `stow-macos`, `unstow-macos`, `preflight-macos`, `stow-ubuntu`, `unstow-ubuntu`, `preflight-ubuntu`.

- [ ] **Step 1: Write failing package-set tests**

Use a fake `stow` that logs argv. Assert:

```bash
macos=$(scripts/package-set.sh macos)
ubuntu=$(scripts/package-set.sh ubuntu)
assert_contains "$macos" 'aerospace' 'macOS includes AeroSpace'
assert_contains "$macos" 'karabiner' 'macOS includes Karabiner'
assert_contains "$macos" 'shell-macos' 'macOS includes its shell fragment'
case $macos in *sway*|*hammerspoon*) fail 'macOS contains retired/wrong platform package' ;; esac
assert_contains "$ubuntu" 'sway' 'Ubuntu includes Sway'
assert_contains "$ubuntu" 'shell-ubuntu' 'Ubuntu includes its shell fragment'
case $ubuntu in *aerospace*|*karabiner*|*hammerspoon*) fail 'Ubuntu contains a Mac package' ;; esac
assert_status 2 scripts/package-set.sh windows
```

For preflight, put an existing regular `.zshrc` in a temporary target and make fake Stow return conflict status `1`. Assert preflight exits `1`, includes `--simulate`, never includes `--delete` or `--restow`, and leaves the target checksum unchanged.

- [ ] **Step 2: Run tests to verify red**

```bash
bash tests/package_sets_test.sh
bash tests/preflight_test.sh
```

Expected: fail because selection scripts do not exist.

- [ ] **Step 3: Implement one canonical package map**

Use newline-free shell word lists:

```bash
common_packages='bash-linux bat bin direnv fd neovim prezto sesh tmux zellij'
macos_packages='aerospace bin-macos ccstatusline cmux devservices ghostty herdr karabiner kitty kitty-macos shell-macos skhd wezterm yabai'
ubuntu_packages='kitty kitty-ubuntu shell-ubuntu sway waybar fuzzel mako swaylock xdg-portal'
packages_for() {
  case $1 in
    macos) printf '%s %s\n' "$common_packages" "$macos_packages" ;;
    ubuntu) printf '%s %s\n' "$common_packages" "$ubuntu_packages" ;;
    *) printf 'error: unsupported platform: %s\n' "$1" >&2; return 2 ;;
  esac
}
```

The script must verify every selected directory exists before printing a set.

Create each future platform package directory in this task with a `.stow-local-ignore` containing only `^\\.stow-local-ignore$`. This makes the complete package map valid before later tasks add its real files, without linking placeholder files into the home directory.

Implement preflight as:

```bash
#!/bin/bash
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
[ "$#" -eq 2 ] || { printf 'usage: %s PLATFORM TARGET\n' "$0" >&2; exit 2; }
platform=$1 target=$2
[ -d "$target" ] || { printf 'error: target is not a directory: %s\n' "$target" >&2; exit 2; }
packages=$("$SCRIPT_DIR/package-set.sh" "$platform") || exit 2
cd "$ROOT_DIR"
# shellcheck disable=SC2086
exec stow --simulate --no-folding --target "$target" $packages
```

- [ ] **Step 4: Replace ambiguous Make behavior**

Make explicit targets call preflight before real Stow:

```make
TARGET ?= $(HOME)

preflight-macos:
	@./scripts/stow-preflight.sh macos "$(TARGET)"

stow-macos: preflight-macos
	@stow --no-folding --target "$(TARGET)" $$(./scripts/package-set.sh macos)

unstow-macos:
	@stow --delete --no-folding --target "$(TARGET)" $$(./scripts/package-set.sh macos)

preflight-ubuntu:
	@./scripts/stow-preflight.sh ubuntu "$(TARGET)"

stow-ubuntu: preflight-ubuntu
	@stow --no-folding --target "$(TARGET)" $$(./scripts/package-set.sh ubuntu)

unstow-ubuntu:
	@stow --delete --no-folding --target "$(TARGET)" $$(./scripts/package-set.sh ubuntu)
```

Change `all` to depend on `stow-macos gitconfig`, preserving the current Mac default while keeping direct `make stow` explicit and unsupported.

Make bare `stow` print a migration error and exit `2`; do not auto-detect silently. Keep individual `stow-PACKAGE` only for directories that exist.

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/run
bash -n scripts/package-set.sh scripts/stow-preflight.sh tests/*.sh
git diff --check
git add Makefile scripts/package-set.sh scripts/stow-preflight.sh tests
git commit -m "feat: add explicit cross-platform stow targets"
```

### Task 2: Portable shell layers and local overrides

**Files:**
- Modify: `bash-linux/.bashrc`
- Modify: `bash-linux/.zshrc`
- Modify: `bash-linux/.zshenv`
- Modify: `bash-linux/.bash/bash_profile`
- Modify: `bash-linux/.bash/bash_aliases`
- Create: `bash-linux/.config/dotfiles/common.sh`
- Create: `shell-macos/.config/dotfiles/platform.sh`
- Create: `shell-ubuntu/.config/dotfiles/platform.sh`
- Modify: `.gitignore`
- Create: `tests/shell_test.sh`
- Modify: `tests/run`
- Modify: `scripts/package-set.sh`

**Interfaces:**
- Shared entry points source `~/.config/dotfiles/common.sh`, the selected `platform.sh`, and optional `~/.config/dotfiles/local.sh`.
- The local override is ignored and never created automatically.

- [ ] **Step 1: Write failing temporary-home shell tests**

Stow each platform into a separate temporary home. With a minimal PATH and optional tools absent, run:

```bash
HOME="$MAC_HOME" ZDOTDIR="$MAC_HOME" zsh -dfc 'source "$HOME/.zshrc"'
HOME="$UBUNTU_HOME" ZDOTDIR="$UBUNTU_HOME" zsh -dfc 'source "$HOME/.zshrc"'
HOME="$UBUNTU_HOME" bash --noprofile --norc -c 'source "$HOME/.bashrc"'
```

Assert all exit `0`. Search Ubuntu-linked configuration and fail on `/opt/homebrew`, `Library/`, `/Users/`, `defaults`, `osascript`, or Xcode. Exclude `~/.local/bin/dotfiles-copy` from the configuration scan and separately assert it is the only Ubuntu-linked file containing `pbcopy`. Assert Mac platform fragment contains Homebrew setup only conditionally. Assert no test writes `local.sh`.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/shell_test.sh`.

Expected: fail on current macOS paths, unguarded Prezto/zoxide calls, and malformed source line.

- [ ] **Step 3: Extract portable and platform behavior**

`common.sh` owns `EDITOR=nvim`, `LESS=FRX`, XDG-safe PATH additions, exact-file optional sources, `dircolors`, and guarded tool initialization:

```bash
path_prepend() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) : ;; *) PATH="$1:$PATH" ;; esac; }
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"
[ -d "$HOME/go/bin" ] && path_prepend "$HOME/go/bin"
export PATH EDITOR=nvim LESS=FRX
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init ${ZSH_VERSION:+zsh}${BASH_VERSION:+bash})"
```

Do not initialize interactive-only tools in `.zshenv`. In `.zshrc`, guard Prezto and P10k by file existence. In `.bashrc`, return immediately when non-interactive after exporting shared environment. Fix the accidental `source ~/.bash/utilities source ~/.bash/google_cloud` line.

Move Xcode, CocoaPods, Homebrew completion paths, `defaults`, and Mac local-IP aliases to `shell-macos`. Put Linux `BROWSER`, `TERMINAL=kitty`, and Wayland-aware environment defaults in `shell-ubuntu` without assuming a display.

- [ ] **Step 4: Add local override policy**

Ignore `.config/dotfiles/local.sh` at the repository package level and document in comments:

```bash
[ -r "$HOME/.config/dotfiles/local.sh" ] && . "$HOME/.config/dotfiles/local.sh"
```

Remove hardcoded `/Users/sendhil/Projects` aliases rather than relocating them.

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/shell_test.sh
bash tests/run
bash -n bash-linux/.bashrc bash-linux/.bash/bash_profile bash-linux/.bash/bash_aliases bash-linux/.config/dotfiles/common.sh shell-macos/.config/dotfiles/platform.sh shell-ubuntu/.config/dotfiles/platform.sh
git diff --check
git add bash-linux shell-macos shell-ubuntu .gitignore scripts/package-set.sh tests
git commit -m "refactor: split portable and platform shell config"
```

### Task 3: Portable clipboard, tmux, Zellij, and Kitty

**Files:**
- Create: `bin/.local/bin/dotfiles-copy`
- Move: `bin/.local/bin/cmux-scratch` to `bin-macos/.local/bin/cmux-scratch`
- Move: `bin/.local/bin/cmux-scratch.swift` to `bin-macos/.local/bin/cmux-scratch.swift`
- Modify: `tmux/.tmux.conf`
- Modify: `zellij/.config/zellij/config.kdl`
- Modify: `kitty/.config/kitty/kitty.conf`
- Create: `kitty-macos/.config/kitty/platform.conf`
- Create: `kitty-ubuntu/.config/kitty/platform.conf`
- Create: `tests/clipboard_test.sh`
- Create: `tests/terminal_test.sh`
- Modify: `tests/run`

**Interfaces:**
- `dotfiles-copy` consumes stdin and selects `pbcopy`, `wl-copy`, or OSC 52.
- `DOTFILES_TTY` overrides `/dev/tty` in tests.
- Kitty base includes `platform.conf`; exactly one platform package owns it.

- [ ] **Step 1: Write failing clipboard selection tests**

Fake `pbcopy` and `wl-copy` and assert:

- Darwin path uses `pbcopy`;
- `WAYLAND_DISPLAY=wayland-1` uses `wl-copy`;
- SSH/no-display base64-encodes stdin and emits an OSC 52 sequence to `DOTFILES_TTY`;
- failure to access any target exits nonzero with a clear error;
- tmux copy bindings invoke `dotfiles-copy`;
- Zellij no longer hardcodes `pbcopy`.

Inject `DOTFILES_UNAME` for deterministic OS tests rather than shadowing the system `uname`.

- [ ] **Step 2: Run tests to verify red**

```bash
bash tests/clipboard_test.sh
bash tests/terminal_test.sh
```

Expected: fail because the helper and platform Kitty fragments do not exist.

- [ ] **Step 3: Implement clipboard adapter**

```bash
#!/bin/bash
set -eu
os=${DOTFILES_UNAME:-$(uname -s)}
if [ "$os" = Darwin ] && command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy
fi
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
fi
tty=${DOTFILES_TTY:-/dev/tty}
[ -w "$tty" ] || { printf 'error: no clipboard transport is available\n' >&2; exit 1; }
payload=$(base64 | tr -d '\n')
printf '\033]52;c;%s\a' "$payload" >"$tty"
```

Point all tmux copy bindings at `~/.local/bin/dotfiles-copy`; retain `set-clipboard on`. Remove Zellij's explicit `copy_command` so its OSC 52 default works in SSH and local terminals.

Move both CMUX scratchpad files into `bin-macos` before linking `bin` on Ubuntu. Leave the portable `opencode-sessions` helper in `bin`; the Ubuntu portability test must fail if a Mach-O binary, Swift source, CMUX path, or AeroSpace reference remains in the common `bin` package.

- [ ] **Step 4: Split Kitty platform keys**

Keep fonts/themes/general behavior in the current Kitty package, remove `macos_colorspace` and `cmd+` maps, and add:

```text
include platform.conf
```

Mac platform config owns `macos_colorspace srgb` and the existing Command mappings. Ubuntu platform config uses `ctrl+shift+c`, `ctrl+shift+v`, and no global `Alt` mappings that conflict with Sway.

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/clipboard_test.sh
bash tests/terminal_test.sh
bash tests/run
bash -n bin/.local/bin/dotfiles-copy
git diff --check
git add bin bin-macos tmux zellij kitty kitty-macos kitty-ubuntu tests
git commit -m "feat: make clipboard and terminal config portable"
```

### Task 4: Sway core and mirrored bindings

**Files:**
- Create: `sway/.config/sway/config`
- Create: `sway/.local/bin/sway-workspace-toggle`
- Create: `sway/.local/bin/sway-scratchpad`
- Create: `tests/sway_helpers_test.sh`
- Create: `tests/sway_config_test.sh`
- Modify: `tests/run`

**Interfaces:**
- `sway-workspace-toggle DIGIT` maps `0` to 10/20 and other digits to N/N+10 using focused workspace JSON.
- `sway-scratchpad` shows an existing `kitty-scratchpad` or launches one.
- Sway config uses `$mod Mod1` and invokes both helpers from `~/.local/bin`.

- [ ] **Step 1: Write failing helper tests**

Fake `swaymsg`, capture commands, and assert:

- focused workspace 1 plus argument 1 selects workspace 11;
- focused 11 plus argument 1 selects workspace 1;
- focused 3 plus argument 1 selects workspace 1;
- argument 0 maps 10/20;
- non-digit exits `2`;
- existing scratch app invokes `[app_id="^kitty-scratchpad$"] scratchpad show`;
- absent scratch app launches `kitty --class kitty-scratchpad`.

- [ ] **Step 2: Write failing static binding tests**

Assert config includes exact bindings for:

- `Mod1+h/j/k/l` focus and Shift variants move;
- number helpers and secondary mode 11–20;
- `Mod1+Tab workspace back_and_forth`;
- grave scratchpad;
- resize and output modes;
- floating toggle;
- `Mod1+Return exec kitty`;
- `Mod1+d exec fuzzel`;
- both fullscreen bindings;
- no `DELL S2722QC`, `Built-in`, or fixed output identifier.

- [ ] **Step 3: Implement helpers**

Use `swaymsg -t get_workspaces -r` plus `jq` for the focused number and `swaymsg -t get_tree -r` for scratch existence. Validate all numeric input before constructing a command. Launch scratch with a unique title/class and `--directory "$HOME"`.

- [ ] **Step 4: Implement Sway config**

Start with:

```text
set $mod Mod1
set $term kitty
set $menu fuzzel
floating_modifier $mod normal
default_border pixel 2
gaps inner 6
gaps outer 0
focus_wrapping workspace
```

Use `exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway`. Add keyboard bindings, media/brightness keys, `grim/slurp` screenshots, `swaylock`, session exit confirmation, and modes named `resize`, `alternate`, `workspace2`, and `outputs`.

Initial app routing must use these known/common Linux identities: Chrome (`app_id="google-chrome"` or `class="Google-chrome"`) to workspace 1, VS Code (`app_id="code"` or `class="Code"`) to workspace 2, Kitty (`app_id="kitty"`) to workspace 3, Obsidian (`app_id="obsidian"` or `class="obsidian"`) to workspace 9, and Slack (`app_id="Slack"` or `class="Slack"`) to workspace 10. Do not add an Outlook rule until the physical laptop reveals its PWA/app identifier. Put every Wayland `app_id` and XWayland `class` criterion on a separate commented line so a mismatched rule is easy to disable.

- [ ] **Step 5: Validate green and commit**

```bash
bash tests/sway_helpers_test.sh
bash tests/sway_config_test.sh
if command -v sway >/dev/null 2>&1; then sway --validate --config sway/.config/sway/config; fi
bash tests/run
bash -n sway/.local/bin/sway-workspace-toggle sway/.local/bin/sway-scratchpad
git diff --check
git add sway tests
git commit -m "feat: add Sway config with mirrored bindings"
```

### Task 5: Sway companion desktop configuration

**Files:**
- Create: `waybar/.config/waybar/config.jsonc`
- Create: `waybar/.config/waybar/style.css`
- Create: `fuzzel/.config/fuzzel/fuzzel.ini`
- Create: `mako/.config/mako/config`
- Create: `swaylock/.config/swaylock/config`
- Create: `xdg-portal/.config/xdg-desktop-portal/portals.conf`
- Modify: `sway/.config/sway/config`
- Create: `tests/sway_desktop_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Sway starts Waybar, Mako, Swayidle, NetworkManager applet, Blueman applet, and the graphical policy agent.
- Waybar uses Sway workspaces plus network, Bluetooth, PipeWire, battery, backlight, and clock modules.
- The portal preference uses wlr for screenshots/screencasts and GTK for file chooser/application portals.

- [ ] **Step 1: Write failing companion tests**

Assert every selected Stow directory exists and Sway starts:

```text
waybar
mako
nm-applet --indicator
blueman-applet
swayidle -w
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
```

Assert idle locks before display power-off and resumes outputs. Assert Waybar uses `sway/workspaces`, `wireplumber`, `network`, `bluetooth`, `battery`, `backlight`, and `clock`. Assert configs contain no output names or host paths.

Assert `portals.conf` contains `default=wlr;gtk` and explicitly selects `gtk` for `org.freedesktop.impl.portal.FileChooser`.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/sway_desktop_test.sh`.

Expected: fail because companion packages do not exist.

- [ ] **Step 3: Implement minimal cohesive desktop**

Use Tokyo Night colors already present in terminal configuration. Configure Fuzzel with JetBrains Mono Nerd Font when available but no hard dependency on a per-host path. Configure Mako default timeout plus critical persistence. Configure Swaylock with indicator and Tokyo Night colors.

Swayidle must implement this sequence:

```text
timeout 300 'swaylock -f'
timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"'
before-sleep 'swaylock -f'
```

Waybar click handlers may open `pavucontrol`, `nm-connection-editor`, or `blueman-manager` only if the corresponding commands are installed; use shell guards.

Create this portal preference:

```ini
[preferred]
default=wlr;gtk
org.freedesktop.impl.portal.FileChooser=gtk
```

- [ ] **Step 4: Validate and commit**

```bash
bash tests/sway_desktop_test.sh
bash tests/run
python3 -m json.tool waybar/.config/waybar/config.jsonc >/dev/null
git diff --check
git add sway waybar fuzzel mako swaylock xdg-portal tests
git commit -m "feat: add Sway desktop companion configs"
```

If Python's strict JSON parser rejects intentional JSONC comments, add a test helper that strips full-line comments before parsing rather than weakening validation.

### Task 6: Remove retired Mac/Linux overlap and Hammerspoon

**Files:**
- Delete: `hammerspoon/.hammerspoon/init.lua`
- Delete: `hammerspoon/.hammerspoon/.gitignore`
- Delete: `scripts/clear-out-files-before-stow.sh`
- Delete: `scripts/setup-neovim-deps-linux.sh`
- Delete: `scripts/check-neovim-deps-linux.sh`
- Modify: `Makefile`
- Modify: `scripts/package-set.sh`
- Create: `tests/retirement_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Ubuntu dependency setup is owned only by `linux-laptop-setup`.
- No supported Make/help path exposes destructive prestow or Hammerspoon.

- [ ] **Step 1: Write failing retirement test**

Assert no selected set contains Hammerspoon, the directory is absent, `make help` does not mention `prestow`, and README/Make/scripts contain no reference to deleted Linux dependency installers. Assert macOS still includes AeroSpace, Karabiner, skhd, yabai, and current terminals.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/retirement_test.sh`.

Expected: fail on existing Hammerspoon and scripts.

- [ ] **Step 3: Remove exact retired ownership**

Delete the listed tracked files/directories. Remove `prestow` from Make help and targets. Do not delete unrelated Mac automation or the Docker Neovim environment.

- [ ] **Step 4: Validate and commit**

```bash
bash tests/retirement_test.sh
bash tests/run
git diff --check
git add Makefile scripts hammerspoon tests
git commit -m "chore: retire Hammerspoon and duplicate Linux setup"
```

### Task 7: Cross-platform documentation and end-to-end temporary homes

**Files:**
- Rewrite: `README.md`
- Create: `docs/ubuntu-first-login.md`
- Create: `tests/stow_integration_test.sh`
- Create: `tests/docs_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Produces documented Mac and Ubuntu workflows and a dotfiles-specific physical checklist.
- End-to-end test uses real Stow when available and otherwise emits an explicit skip.

- [ ] **Step 1: Write failing documentation and Stow integration tests**

README tests require `make preflight-macos`, `make stow-macos`, `make preflight-ubuntu`, `make stow-ubuntu`, local override instructions, Ubuntu setup repository ordering, GNOME fallback, NVIDIA warning, and recovery tag.

The integration test creates separate empty homes, runs both preflight/link targets, verifies representative links, verifies no Hammerspoon/Sway on Mac and no AeroSpace/Karabiner on Ubuntu, starts Bash/Zsh, unlinks both targets, and asserts the temporary homes retain only test-owned marker files.

- [ ] **Step 2: Run tests to verify red**

```bash
bash tests/docs_test.sh
bash tests/stow_integration_test.sh
```

Expected: docs fail until rewritten; integration reveals any remaining package conflicts.

- [ ] **Step 3: Rewrite README and add checklist**

Lead with repository now being cross-platform. Document prerequisites as belonging to `mac-laptop-setup` or `linux-laptop-setup`, never install them here. Document explicit preflight/link/unlink commands, conflict resolution without deletion, platform package ownership, SSH behavior, local overrides, Sway/GNOME selection, binding differences from stock i3, app-ID inspection with `swaymsg -t get_tree`, and tag recovery.

The checklist covers GDM/Sway login, launcher, terminal, focus/move, workspaces 1–20, back-and-forth, scratchpad, resize, outputs, routing, Waybar, Mako, clipboard, screenshots, lock/idle, audio, network, Bluetooth, policy prompts, Slack/Zoom launch and screen share, SSH from Mac, logout, and GNOME login.

- [ ] **Step 4: Run complete repository validation**

```bash
bash tests/run
bash tests/stow_integration_test.sh
for file in scripts/*.sh bin/.local/bin/dotfiles-copy sway/.local/bin/* tests/*.sh; do bash -n "$file"; done
if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh bin/.local/bin/dotfiles-copy sway/.local/bin/* tests/*.sh; fi
if command -v sway >/dev/null 2>&1; then sway --validate --config sway/.config/sway/config; fi
git diff --check
git rev-list -n 1 pre-linux-2026-08-11
```

Expected tag output: `01b0c7035e39f481a0d87ff2e3976c15716cb411`.

- [ ] **Step 5: Commit documentation and integration coverage**

```bash
git add README.md docs tests
git commit -m "docs: document cross-platform dotfiles workflow"
```

### Task 8: Final two-repository verification and recovery-tag publication

**Files:**
- Modify only if validation reveals a documented defect.

**Interfaces:**
- Consumes both completed plans.
- Produces clean verified histories and remotely recoverable tags.

- [ ] **Step 1: Run both suites**

```bash
cd /Users/sendhil/src/linux-laptop-setup
bash tests/run
git diff --check

cd /Users/sendhil/src/dotfiles-mac
bash tests/run
git diff --check
```

Expected: all tests pass.

- [ ] **Step 2: Verify exact tags and review histories**

```bash
git -C /Users/sendhil/src/linux-laptop-setup rev-list -n 1 pre-modernization-2026-08-11
git -C /Users/sendhil/src/dotfiles-mac rev-list -n 1 pre-linux-2026-08-11
git -C /Users/sendhil/src/linux-laptop-setup status --short --branch
git -C /Users/sendhil/src/dotfiles-mac status --short --branch
```

Expected hashes are the values in Global Constraints. Linux status may contain only the three preserved pre-existing untracked files.

- [ ] **Step 3: Push only the verified recovery tags**

```bash
git -C /Users/sendhil/src/linux-laptop-setup push origin refs/tags/pre-modernization-2026-08-11
git -C /Users/sendhil/src/dotfiles-mac push origin refs/tags/pre-linux-2026-08-11
```

Expected: both remote tag pushes succeed. Do not push feature branches or default branches unless separately requested.

- [ ] **Step 4: Prepare laptop handoff**

Report both repository commits, tag publication, automated checks, any skipped Docker/Sway validation, and the exact first-laptop sequence:

```bash
./bin/bootstrap
./bin/audit work
./bin/apply work
./bin/doctor work
make preflight-ubuntu
make stow-ubuntu
```

The last two commands run from the dotfiles checkout; the first four run from `linux-laptop-setup`.

## Plan completion checks

```bash
git status --short --branch
git log --oneline pre-linux-2026-08-11..HEAD
git diff --check
bash tests/run
```

Expected: focused Task 1–8 commits, clean tracked state, and a passing suite.
