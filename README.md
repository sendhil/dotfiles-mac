# Cross-platform dotfiles

These are shared macOS and Ubuntu dotfiles with explicit platform layers.
GNU Stow links configuration into a home directory; this repository never
installs operating-system packages, changes a login shell, or replaces a
desktop session.

The supported entry points are deliberately explicit:

- `make stow-macos` links the common and macOS package sets.
- `make stow-ubuntu` links the common, Ubuntu, and Sway package sets.
- Bare `make stow` is unsupported so one platform can never be selected by
  accident.

## Prerequisites and setup order

Machine software is owned by a separate setup repository. On a Mac, complete
the current workflow in `mac-laptop-setup`. On an Ubuntu work laptop, complete
the supported flow in `linux-laptop-setup` first:

```bash
bin/bootstrap
bin/audit work
bin/apply work
bin/audit work
bin/doctor work
```

Review the first audit before applying. The second audit should converge.
Review the doctor output, then clone this repository, including any
submodules, and continue with its Ubuntu preflight. Run doctor again from
inside Sway when completing the physical-session checklist.

The setup repositories own prerequisites such as GNU Stow, Zsh, Neovim,
desktop packages, and command-line tools. Workplace IT continues to own
drivers, privileged runtimes, GNOME/GDM, Slack, Zoom, VPNs, and corporate
agents. Do not use this repository to install or reconfigure those items.

## Link and unlink safely

Run commands from this repository. Preflight is read-only and performs a real
Stow simulation against the selected target.

### macOS

```bash
make preflight-macos
make stow-macos

# Later, to remove only links owned by the selected package set:
make unstow-macos
```

### Ubuntu and Sway

```bash
make preflight-ubuntu
make stow-ubuntu

# Later, to remove only links owned by the selected package set:
make unstow-ubuntu
```

`make stow-macos` and `make stow-ubuntu` run their corresponding preflight
again immediately before linking. To exercise an isolated home or another
target, pass it explicitly, for example:

```bash
make TARGET=/tmp/dotfiles-home preflight-ubuntu
```

If preflight reports a conflict, inspect both paths and decide which content
to keep. A useful sequence is `ls -ld` followed by `diff -u` for regular text
files. Merge needed machine-specific values into the local override described
below, or rename the existing file to an intentional backup before rerunning
preflight. Do not delete existing home-directory content merely to make Stow
succeed, and do not use a bulk cleanup script.

## Package ownership

[`scripts/package-set.sh`](scripts/package-set.sh) is the canonical map. The
grouping is:

- **Common packages:** `bash-linux`, `bat`, `bin`, `direnv`, `fd`, `neovim`,
  `prezto`, `sesh`, `tmux`, and `zellij`. These must work on either platform
  and in a non-graphical SSH session.
- **macOS packages:** AeroSpace, Karabiner, skhd, yabai, macOS terminal layers,
  and other Mac-only helpers and applications.
- **Ubuntu packages:** the Linux shell and Kitty layers plus Sway, Waybar,
  Fuzzel, Mako, Swaylock, and the desktop-portal preference.

The package set controls only user configuration. It does not imply that the
corresponding software is installed. Individual package targets remain
available as `make stow-PACKAGE` and `make unstow-PACKAGE`, but the platform
targets are the normal workflow because they install a coherent shell and
desktop layer.

## Shells, local overrides, and SSH copy

Zsh is the intended interactive shell, while Bash remains safe for scripts
and remote use. The shared shell entry points load, in order:

1. `~/.config/dotfiles/common.sh`;
2. the selected `~/.config/dotfiles/platform.sh`;
3. optional `~/.config/dotfiles/local.sh`.

Create `local.sh` yourself for workplace paths, host-specific environment
variables, or private aliases:

```bash
mkdir -p ~/.config/dotfiles
${EDITOR:-vi} ~/.config/dotfiles/local.sh
```

The file is ignored by Git, is never created by Stow, and should remain local
to that machine. Do not put secrets or workplace-specific paths in a tracked
package.

Clipboard behavior also follows the session. `~/.local/bin/dotfiles-copy`
uses `pbcopy` on macOS, `wl-copy` in a local Wayland session, and an OSC 52
escape sequence through the controlling terminal when neither local clipboard
transport is available. That last path lets tmux copy mode send text back to
the terminal on the work Mac during SSH. The Mac terminal must allow OSC 52
clipboard writes; if corporate terminal policy blocks them, the command fails
without assuming a graphical display on the Ubuntu host.

## Sway as primary, GNOME as fallback

After the Ubuntu software workflow, dotfiles preflight/link, and
`bin/doctor work` are complete, log out. In GDM, use the session chooser to
select Sway. This makes Sway primary by user choice; it does not remove or
modify GNOME. Keep GNOME selectable until the physical checks in
[`docs/ubuntu-first-login.md`](docs/ubuntu-first-login.md) pass. If graphics,
screen sharing, or a workplace application blocks work, log out normally and
select GNOME.

> **NVIDIA caution:** Sway does not officially support the proprietary NVIDIA
> driver. Do not replace a workplace-managed driver. Smoke-test the actual
> laptop and displays, retain GNOME as the fallback, and involve IT if the
> session is unstable.

The Sway configuration is hardware-neutral: it does not name a particular
panel, dock, or monitor. Inspect the real output identifiers with
`swaymsg -t get_outputs` before adding a machine-local output profile.

### Bindings and deviations from stock i3

The configuration follows the previous window-management muscle memory, so a
few choices intentionally differ from stock i3:

| Action | This configuration | Difference from stock i3 |
| --- | --- | --- |
| Modifier | `Alt` (`Mod1`) | Stock i3 commonly uses the Super key (`Mod4`). |
| Focus | `Alt+h/j/k/l` | Vim `h/j/k/l` replaces stock i3's `j/k/l/;`. |
| Move | `Alt+Shift+h/j/k/l` | Uses the same Vim directions as focus. |
| Workspaces | `Alt+1`…`0` | Toggles between workspace N and N+10 when N is already focused. |
| Workspaces 11–20 | `Alt+Shift+Backtick`, then a number | An explicit secondary-workspace mode. |
| Back-and-forth | `Alt+Tab` | Direct previous-workspace access. |
| Scratch terminal | `Alt+Backtick` | Uses Sway's native scratchpad with Kitty. |
| Resize | `Alt+r`, then `h/j/k/l` | A Vim-direction resize mode. |
| Outputs | `Alt+Shift+;`, then `m` | Enters a mode for focusing outputs or moving containers. |
| Floating | `Alt+Shift+Space` | Toggles floating for the focused container. |
| Fullscreen | `Alt+f` | `Alt+Shift+f` remains a compatibility alias. |
| Terminal / launcher | `Alt+Enter` / `Alt+d` | Explicit Kitty and Fuzzel launch bindings. |

Known Chrome, VS Code, Kitty, Obsidian, and Slack identifiers have initial
workspace routes. Wayland `app_id` values and XWayland classes vary by package
and launch mode, so do not guess a new rule. Launch the application, run
`swaymsg -t get_tree`, inspect its `app_id` or `window_properties.class`, and
then add one exact criterion per rule. Reload Sway and verify the observed
application before relying on the route.

## Neovim and container notes

The machine setup repository owns Neovim's external dependencies. Inside
Neovim, use `:checkhealth`, `:Mason`, and `:MasonToolsInstall` to inspect
editor-managed tools. The disposable Neovim images and Colima notes remain in
[`docker/neovim/README.md`](docker/neovim/README.md); they are optional test
environments and are not part of Ubuntu laptop provisioning.

On macOS, `scripts/setup-colima-neovim.sh` configures only a pre-provisioned `neovim-dev`
profile. External provisioning must already have the profile running with
Neovim installed and this repository mounted at `/home/dotfiles`. The helper
does not own the Colima guest lifecycle.

## Recovery

The annotated tag `pre-linux-2026-08-11` points to the dotfiles state before
this cross-platform migration:

```bash
git show pre-linux-2026-08-11
```

Use the tag for inspection or selective recovery. Preserve current work before
switching revisions or restoring a file from it.
