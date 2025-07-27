#!/bin/bash

# Neovim Dependencies Setup Script for macOS
# This script installs core dependencies needed for the Neovim configuration
# Language servers, formatters, and linters will be handled by Mason inside Neovim

set -e

echo "🚀 Starting Neovim dependencies installation for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "📦 Installing core dependencies via Homebrew..."
brew install \
    neovim \
    git \
    make \
    gcc \
    gh \
    fzf \
    ripgrep \
    fd \
    python3 \
    pipx \
    go

echo "📦 Installing fnm (Fast Node Manager)..."
brew install fnm

# Install Node.js LTS via fnm
echo "📦 Installing Node.js LTS via fnm..."
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm use lts-latest
fnm default lts-latest

# Add fnm to shell config based on shell type
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    SHELL_CONFIG="$HOME/.bash_profile"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

if ! grep -q "fnm env" "$SHELL_CONFIG"; then
    echo '' >> "$SHELL_CONFIG"
    echo '# fnm (Fast Node Manager)' >> "$SHELL_CONFIG"
    echo 'eval "$(fnm env --use-on-cd)"' >> "$SHELL_CONFIG"
fi

echo "🦀 Installing Rust toolchain via rustup..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup component add rust-analyzer
else
    echo "✓ Rust already installed"
fi

echo "🐍 Ensuring pipx is in PATH..."
pipx ensurepath

echo "✅ Core dependencies installation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Open a new terminal to ensure all PATH updates are loaded"
echo "2. Run 'nvim' to start Neovim"
echo "3. Inside Neovim, install language servers and tools:"
echo "   - Run ':Mason' to open the UI"
echo "   - Or run ':MasonToolsInstall' to install all configured tools"
echo "4. Run ':checkhealth' in Neovim to verify everything is working"
echo ""
echo "💡 Mason commands:"
echo "   :Mason              - Open Mason UI to manually install/manage tools"
echo "   :MasonToolsInstall  - Install all tools configured in mason-tool-installer"
echo "   :MasonToolsUpdate   - Update all installed tools"
echo "   :MasonUpdate        - Update Mason itself"
echo ""
echo "🔍 Verification commands:"
echo "   nvim --version"
echo "   git --version"
echo "   node --version"
echo "   go version"
echo "   rustc --version"
echo "   fzf --version"
echo "   rg --version"
echo "   fd --version"