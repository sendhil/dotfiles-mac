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
