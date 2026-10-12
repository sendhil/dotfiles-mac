# Dotfiles

My personal dotfiles for macOS configuration.

## Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/)
- [crudini](https://github.com/pixelb/crudini) (only needed for git config management)

## Installation

### Install Everything

```bash
make stow
```

### Install Individual Packages

You can install specific configurations:

```bash
make stow-neovim    # Install only neovim config
make stow-tmux      # Install only tmux config
```

### Available Packages

- `aerospace` - Window manager configuration
- `sketchybar` - Catppuccin Mocha menu bar (see [Menu Bar Setup](#menu-bar-setup))
- `bash-linux` - Bash configuration
- `bat` - Better cat configuration
- `direnv` - Directory environment configuration
- `fd` - Find alternative configuration
- `hammerspoon` - macOS automation
- `herdr` - Herdr baseline and synced Radar preferences ([Mac setup](herdr/README.md)); deployed separately from Stow
- `karabiner` - Keyboard customization (see [karabiner/README.md](karabiner/README.md) for profile setup)
- `kitty` - Terminal emulator configuration
- `neovim` - Neovim configuration (see [Neovim Setup](#neovim-setup) for dependencies)
- `prezto` - Zsh configuration framework
- `sesh` - Session management
- `skhd` - Simple hotkey daemon
- `tmux` - Terminal multiplexer configuration
- `yabai` - Tiling window manager
## Usage

```bash
make help           # Show all available commands
make stow           # Install all configurations
make unstow         # Remove all configurations
make stow-<package> # Install specific package
make unstow-<package> # Remove specific package
make setup-herdr     # Install/apply pinned Radar after offline deployment
make check-herdr     # Verify local Herdr + Radar configuration
make gitconfig      # Update git aliases
```

## Uninstalling

### Remove Everything

```bash
make unstow
```

### Remove Individual Packages

```bash
make unstow-neovim  # Remove only neovim config
```

## Pre-stow Cleanup

If you have existing configuration files that might conflict:

```bash
make prestow  # Cleans out existing files before stowing
```

## Menu Bar Setup

The shared configuration reproduces the Catppuccin Mocha bar: colorful AeroSpace
workspace pills, app icons, workspace overflow, battery, network, volume controls,
and a **12-hour clock with AM/PM**. Moving to the very top edge reveals the native
macOS menu bar for VPN and other application menus.

### Install on another Mac

Clone this repository, install [Homebrew](https://brew.sh), then run from the checkout:

```bash
./scripts/setup-sketchybar.sh
./scripts/setup-sketchybar.sh --check
```

The script installs **missing** dependencies from
[`scripts/sketchybar-dependencies.json`](scripts/sketchybar-dependencies.json),
backs up existing configurations, and Stows only `sketchybar` and `aerospace`.
It generates login agents with this Mac's executable/home paths and sets native
menu auto-hide to **Always**, including full-screen apps. It does not run a general
Homebrew upgrade. Python 3.9+ is required; the launcher installs Python if absent.

AeroSpace needs Accessibility permission on each new Mac. Open it and accept the
macOS permission prompt, then rerun `--check`. SketchyBar also requires **Displays
have separate Spaces** in System Settings → Desktop & Dock. Changing that macOS
setting may require logout/login. See the [upstream setup guide](https://felixkratz.github.io/SketchyBar/setup).

If an older `~/.aerospace.toml` exists, setup stops so you can back it up and move it
aside; the shared configuration belongs at `~/.config/aerospace/aerospace.toml`.
If a Homebrew SketchyBar service exists, run `brew services stop sketchybar` before
setup. This package owns two login agents (`local.sketchybar-mocha` and
`local.sketchybar-native-toggle`); do not also launch SketchyBar from AeroSpace or
Homebrew services.

### Sync changes

On the Mac where you edit the theme, commit and push the relevant dotfiles changes.
On the other Mac, run from its checkout:

```bash
git pull --ff-only
./scripts/setup-sketchybar.sh
./scripts/setup-sketchybar.sh --check
```

Rerunning setup keeps the original backup, refreshes the links/login agents, and
restarts the bar. Theme edits are shared through Git/Stow; running workspace state,
logs, macOS permissions, and backups stay local. Setup refuses to overwrite changes
to files it generated outside the checkout; preserve/reconcile those edits first.

### Herdr Menubar badge

The Mocha bar includes a Herdr badge. Install the separate **Herdr Menubar** companion
app from your `herdr-menubar` checkout using its `scripts/install.sh`, then launch it.
Use the same local signing configuration you normally use to build that app on each Mac.
Core Herdr and your sessions do not need integration changes.

The badge shows how many agents need attention. Click it to open Herdr Menubar's
native menu beside the pointer; choosing an agent uses the app's session-aware focus
behavior. Mint means connected, yellow means attention, and gray means disconnected,
not running, or stale. The normal macOS menu item is still available at the top edge.
Widgets and notifications do not need to be enabled.

`sketchybar/.config/sketchybar/plugins/herdr.py` is a copy of
`herdr-menubar/integrations/sketchybar/herdr.py` (status schema v1). Update both copies
together when changing the integration. The app publishes only aggregate connection
and attention information to
`~/Library/Application Support/Herdr Menubar/sketchybar-status.json` and signals changes
with `dev.herdr.menubar.statusChanged`; the bar also refreshes every 30 seconds.
The setup script handles the bar configuration, while Herdr Menubar is installed separately.

For an appearance-only edit on a configured Mac, `sketchybar --reload` is sufficient.
`make stow-sketchybar` only links configuration; use the setup script for dependencies,
startup services, menu preferences, and a recoverable backup.

### Display differences

Workspace pills detect connected displays dynamically. Battery disappears on Macs
without a battery. The existing AeroSpace workspace assignments remain personal:
workspaces 21–24 mention `DELL S2722QC` and `Built-in`. Review
[`aerospace.toml`](aerospace/.config/aerospace/aerospace.toml) when using other monitors;
AeroSpace also supports `main` and `secondary` patterns.

The top gap is 8 points on a **notched built-in display** and 42 on external displays.
For an older non-notched laptop, change its built-in gap to 42 before using the shared
configuration. This is a shared repo setting; if your machines need different values,
keep a small machine-specific Git branch and merge shared theme changes into it.
External/mixed-display behavior has unit coverage but has not been physically tested
on all of your machines.

### Dependencies and appearance

Known working here: SketchyBar 2.21.0, sketchybar-toggle 0.5.0, AeroSpace 0.21.3.
Homebrew dependencies use available stable releases, rather than a fully locked OS/toolchain.
The exact app-icon font is bundled with its license and checksum, paired with
`app-icons.json`, and loaded privately by SketchyBar. Update them together. Other
fonts are Hack Nerd Font and macOS SF Pro. The helper comes from
[sketchybar-toggle](https://github.com/malpern/sketchybar-toggle).

### Check or undo

```bash
./scripts/setup-sketchybar.sh --check   # Read-only dependency/service/settings check
./scripts/setup-sketchybar.sh --restore
```

Restore returns configuration links/files, owned login agents, and the two menu-bar
preferences to their state **before the first setup run**. It refuses to discard
subsequent local edits to managed files. Homebrew packages remain installed, and
changes made directly to tracked repo files are not rolled back. On the original
trial Mac, this restores the standalone Mocha configuration from before packaging.

Backups: `~/Library/Application Support/dotfiles-sketchybar/`.
Logs: `~/Library/Logs/SketchyBar-Mocha/`.
Runtime cache: `~/Library/Caches/dotfiles-sketchybar/`.

To run the filesystem installer tests and workspace-layout tests:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

## Neovim Setup

The Neovim configuration requires several dependencies to work properly. You have two options:

### Option 1: Automated Setup

Run the appropriate setup script for your operating system:

#### macOS
```bash
./scripts/setup-neovim-deps-mac.sh
```

#### Linux (Ubuntu/Debian)
```bash
./scripts/setup-neovim-deps-linux.sh
```

These scripts will install:
- Core dependencies (git, make, gcc, fzf, ripgrep, fd, etc.)
- Language runtimes (Go, Node.js via fnm, Rust via rustup, Python)
- System tools (clangd, clang-tidy on Linux)
- Package managers (Homebrew on macOS, uses apt on Linux)

### Option 2: Manual Setup

If you prefer to have more control over what gets installed:

1. **Check what's already installed:**
   ```bash
   # macOS
   ./scripts/check-neovim-deps-mac.sh
   
   # Linux
   ./scripts/check-neovim-deps-linux.sh
   ```

2. **Install missing dependencies** based on the check script output

3. **Install the Neovim configuration:**
   ```bash
   make stow-neovim
   ```

4. **Open Neovim and install language servers/tools:**
   ```bash
   nvim
   # Inside Neovim:
   :Mason                 # Open Mason UI to manually install tools
   :MasonToolsInstall     # Install configured formatters/linters
   ```

### Dependencies Overview

**Core Requirements:**
- Neovim 0.9+ (latest version recommended)
- Git
- C compiler (gcc/clang)
- Make
- Python 3 with pipx
- Node.js (via fnm - Fast Node Manager)
- Go
- Rust toolchain (via rustup)

**Search & Navigation:**
- fzf - Fuzzy finder
- ripgrep - Fast grep alternative
- fd - Fast find alternative

**Optional but Recommended:**
- GitHub CLI (gh) - For GitHub integration
- clangd - C/C++ language server
- clang-tidy - C/C++ linter

### Troubleshooting

- Run `:checkhealth` inside Neovim to diagnose issues
- Check Mason logs with `:MasonLog` if language servers fail to install
- On ARM64 Linux, some tools are installed system-wide instead of via Mason
- If you see errors on first launch, try `:Lazy sync` to ensure all plugins are installed

## Try It Out

### Option 1: Docker Hub (Quickest)
```bash
# Run directly from Docker Hub (drops you into bash)
docker run -it --rm sendhil/neovim-dev

# Run directly from Docker Hub and launch into nvim
docker run -it --rm sendhil/neovim-dev nvim

# Run with your current directory mounted 
docker run -it --rm -v $(pwd):/workspace sendhil/neovim-dev

# Run with your home directory mounted
docker run -it --rm -v $HOME:/workspace sendhil/neovim-dev

# Run with persistent plugin/Mason data
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  -v $(pwd):/workspace \
  sendhil/neovim-dev

# Run with BOTH persistent data AND home directory mounted
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  -v $HOME:/workspace \
  sendhil/neovim-dev
```

### Option 2: Docker Compose (Local Build)
```bash
cd docker/neovim
docker-compose up -d
docker-compose exec neovim nvim
```

### Option 3: Colima (macOS)
```bash
./scripts/setup-colima-neovim.sh
colima-nvim nvim
```

See [docker/neovim/README.md](docker/neovim/README.md) for detailed instructions.

## Zsh/Prezto Troubleshooting

### Tab Completion Errors for Homebrew Tools

If you see errors like `_eza: function definition file not found` or `_bat: function definition file not found` when pressing tab:

**Cause:** Zprezto's completion cache doesn't include Homebrew's completion directory.

**Fix:**

1. Ensure your `~/.zshrc` has the Homebrew fpath **before** the zprezto init line:
   ```bash
   fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
   source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
   ```

2. Clear the completion caches:
   ```bash
   rm -f ~/.cache/prezto/zcompdump* ~/.zcompdump*
   ```

3. Open a new terminal session.
