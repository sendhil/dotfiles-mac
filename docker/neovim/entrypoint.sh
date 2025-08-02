#!/bin/bash

# Neovim Docker Entrypoint Script

# Source the environment
source ~/.bashrc

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# First-time setup check
if [ ! -f ~/.config/nvim/.docker-initialized ]; then
    echo -e "${BLUE}🚀 First-time setup detected!${NC}"
    echo -e "${YELLOW}Setting up Neovim environment...${NC}"
    
    # Ensure all directories exist with correct permissions
    mkdir -p ~/.config/nvim ~/.cache/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.local/share/nvim/mason
    
    # Clear any partial plugin downloads
    rm -rf ~/.local/share/nvim/lazy/*
    
    # Re-clone lazy.nvim to ensure it's fresh
    git clone --filter=blob:none --branch=stable https://github.com/folke/lazy.nvim.git \
        ~/.local/share/nvim/lazy/lazy.nvim
    
    echo -e "${YELLOW}Installing Neovim plugins (this may take a minute)...${NC}"
    
    # Install plugins with better error handling
    nvim --headless -c "autocmd User LazyDone quitall" -c "Lazy sync" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Some plugins may have failed to install.${NC}"
        echo "You can manually run ':Lazy sync' inside Neovim to retry."
    }
    
    # Mark as initialized
    touch ~/.config/nvim/.docker-initialized
    
    echo -e "${GREEN}✓ Initial setup complete!${NC}"
fi

# Ensure Mason directory exists and has correct permissions
mkdir -p ~/.local/share/nvim/mason/registries
chmod -R 755 ~/.local/share/nvim/mason

# Initialize Mason registry if it doesn't exist
if [ ! -d ~/.local/share/nvim/mason/registries/github ]; then
    echo -e "${YELLOW}Initializing Mason registry...${NC}"
    # Force Mason to update its registry
    nvim --headless -c "lua require('mason-registry').refresh()" -c "q" 2>/dev/null || true
fi

# Display welcome message
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Welcome to Neovim in Docker!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Quick tips:${NC}"
echo "• Run 'nvim' to start Neovim"
echo "• Run ':Mason' to manage language servers"
echo "• Run ':MasonToolsInstall' to install all configured tools at once"
echo "• Run ':checkhealth' to verify setup"
echo ""
echo -e "${YELLOW}Config location:${NC} ~/.config/nvim"
echo -e "${YELLOW}Workspace:${NC} ~/workspace (if mounted)"
echo ""

# If no command provided, start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    # Execute the provided command
    exec "$@"
fi