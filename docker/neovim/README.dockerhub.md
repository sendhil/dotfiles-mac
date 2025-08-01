# Neovim Development Environment

A pre-configured Neovim development environment in Docker with language servers, formatters, and essential tools.

## Quick Start

```bash
# Run interactive shell
docker run -it --rm sendhil/neovim-dev

# Run Neovim directly
docker run -it --rm sendhil/neovim-dev nvim

# Run with your workspace mounted
docker run -it --rm -v $(pwd):/workspace sendhil/neovim-dev

# Run with persistent data
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  sendhil/neovim-dev
```

## Features

- **Neovim** (latest stable) with modern configuration
- **Language Servers**: Pre-configured for multiple languages
- **Development Tools**: Git, Make, GCC, Go, Rust, Node.js, Python
- **Search Tools**: ripgrep, fd, fzf
- **Plugin Manager**: Lazy.nvim with essential plugins
- **LSP Manager**: Mason.nvim for language server management
- **Multi-architecture**: Supports linux/amd64 and linux/arm64

## Included Tools

### Core Development
- Neovim (latest stable)
- Git
- GCC/G++ & Make
- clangd & clang-tidy

### Languages
- **Go**: Latest version with gopls
- **Rust**: Via rustup with rust-analyzer
- **Node.js**: LTS via fnm (Fast Node Manager)
- **Python 3**: With pip and pipx

### Utilities
- GitHub CLI (gh)
- ripgrep (rg)
- fd (find alternative)
- fzf (fuzzy finder)

## Usage Examples

### Interactive Development
```bash
# Start an interactive shell
docker run -it --rm sendhil/neovim-dev

# Inside the container
nvim                    # Start Neovim
:Mason                  # Manage language servers
:MasonToolsInstall      # Install configured tools
:checkhealth            # Verify setup
```

### Edit Files in Current Directory
```bash
# Mount current directory as workspace
docker run -it --rm -v $(pwd):/workspace sendhil/neovim-dev nvim /workspace
```

### Persistent Configuration
```bash
# Create named volumes for persistence
docker volume create neovim-data
docker volume create neovim-mason

# Run with persistent volumes
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  -v $(pwd):/workspace \
  sendhil/neovim-dev
```

### Custom Git Configuration
```bash
# Mount your git config
docker run -it --rm \
  -v ~/.gitconfig:/home/nvimuser/.gitconfig:ro \
  -v $(pwd):/workspace \
  sendhil/neovim-dev
```

## Environment Details

- **Base**: Ubuntu 22.04
- **User**: nvimuser (non-root with sudo access)
- **Shell**: Bash with configured paths
- **Locale**: en_US.UTF-8

## Neovim Configuration

The included Neovim configuration features:
- Modern plugin management with Lazy.nvim
- LSP support with nvim-lspconfig
- Autocompletion with nvim-cmp
- File navigation with Telescope
- Git integration with fugitive
- Status line with lualine
- File tree with neo-tree
- And more...

## Tips

1. **First Run**: Plugins are pre-installed, but you may need to run `:Lazy sync` if any fail
2. **Language Servers**: Use `:Mason` to install additional language servers
3. **Updates**: Pull the latest image regularly for updates
4. **Performance**: Use volumes for better performance with large codebases

## Source

This image is built from: https://github.com/sendhil/dotfiles-mac

## Support

For issues or suggestions, please visit the GitHub repository.