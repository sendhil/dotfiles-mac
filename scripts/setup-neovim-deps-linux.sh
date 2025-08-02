#!/bin/bash

# Neovim Dependencies Setup Script for Linux (ARM64/AMD64)
# This script installs core dependencies needed for the Neovim configuration
# Language servers, formatters, and linters will be handled by Mason inside Neovim

set -e

echo "🚀 Starting Neovim dependencies installation for Linux..."

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
  ARCH="amd64"
fi

echo "🔍 Detected architecture: $ARCH"

# Update package list
echo "📦 Updating package list..."
sudo apt update

# Install basic dependencies
echo "📦 Installing basic dependencies..."
sudo apt install -y \
  git \
  make \
  gcc \
  g++ \
  clangd \
  clang-tidy \
  python3 \
  python3-pip \
  pipx \
  curl \
  wget \
  unzip \
  fzf \
  ripgrep \
  fd-find

# Install Neovim from official release
echo "📦 Installing Neovim from official release..."
NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "   Latest Neovim version: $NVIM_VERSION"

# Download and install Neovim based on architecture
cd /tmp

# Check if ARM64 tarball exists (available from v0.10.0+)
ARM64_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
if [ "$ARCH" = "arm64" ]; then
  # Try ARM64-specific build first
  ARM64_SPECIFIC_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-arm64.tar.gz"
  if wget --spider "$ARM64_SPECIFIC_URL" 2>/dev/null; then
    echo "   Downloading Neovim ARM64 build..."
    wget "$ARM64_SPECIFIC_URL" -O nvim.tar.gz
    sudo tar -C /opt -xzf nvim.tar.gz
    sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
  else
    # Fallback: Build from source for ARM64
    echo "   No ARM64 build available. Building from source..."
    sudo apt install -y ninja-build gettext cmake

    # Clone and build
    git clone https://github.com/neovim/neovim
    cd neovim
    git checkout ${NVIM_VERSION}
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    cd ..
    rm -rf neovim
  fi
  rm -f nvim.tar.gz
else
  # For x86_64, use the standard tarball
  echo "   Downloading Neovim x86_64 build..."
  wget "$ARM64_URL" -O nvim.tar.gz
  sudo tar -C /opt -xzf nvim.tar.gz
  sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
  rm nvim.tar.gz
fi
cd -

# Install fnm (Fast Node Manager)
echo "📦 Installing fnm (Fast Node Manager)..."
curl -fsSL https://fnm.vercel.app/install | bash

# Add fnm to PATH for current script
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

# Install Node.js LTS
echo "📦 Installing Node.js LTS via fnm..."
fnm install --lts
fnm use lts-latest
fnm default lts-latest

# Add fnm to shell config if not already there
if ! grep -q "fnm env" ~/.bashrc; then
  echo '' >>~/.bashrc
  echo '# fnm (Fast Node Manager)' >>~/.bashrc
  echo 'export PATH="$HOME/.local/share/fnm:$PATH"' >>~/.bashrc
  echo 'eval "$(fnm env --use-on-cd)"' >>~/.bashrc
fi

# Install Go
echo "📦 Installing Go..."
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
wget -q https://go.dev/dl/${GO_VERSION}.linux-${ARCH}.tar.gz -O /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

# Add Go to PATH if not already there
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
  echo 'export PATH=$PATH:$HOME/go/bin' >>~/.bashrc
fi

# Install GitHub CLI
echo "📦 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update
sudo apt install -y gh

# Install Rust toolchain
echo "🦀 Installing Rust toolchain via rustup..."
if ! command -v rustc &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  rustup component add rust-analyzer
else
  echo "✓ Rust already installed"
fi

# Setup pipx path
echo "🐍 Ensuring pipx is in PATH..."
pipx ensurepath

# Install uv (modern Python package manager)
echo "📦 Installing uv (modern Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.cargo/env"

# Install vectorcode via uv
echo "🤖 Installing vectorcode via uv..."
uv tool install vectorcode

# Create fd symlink (Ubuntu/Debian calls it fdfind)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -s $(which fdfind) /usr/local/bin/fd
fi

echo "✅ Core dependencies installation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Run 'source ~/.bashrc' or open a new terminal to load PATH updates"
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
echo "🔍 Quick verification (run after sourcing ~/.bashrc):"
echo "   nvim --version"
echo "   git --version"
echo "   node --version"
echo "   go version"
echo "   rustc --version"
echo "   fzf --version"
echo "   rg --version"
echo "   fd --version"
