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
- `bash-linux` - Bash configuration
- `bat` - Better cat configuration
- `direnv` - Directory environment configuration
- `fd` - Find alternative configuration
- `hammerspoon` - macOS automation
- `karabiner` - Keyboard customization
- `kitty` - Terminal emulator configuration
- `neovim` - Neovim configuration
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
