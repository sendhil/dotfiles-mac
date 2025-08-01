#!/bin/bash

# Neovim Docker Standalone Entrypoint Script
# This version is for the pre-built Docker Hub image

# Source the environment
source ~/.bashrc

# Ensure Go is in PATH
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# First-time setup check
if [ ! -f ~/.config/nvim/.docker-initialized ]; then
    echo -e "${BLUE}🚀 First-time setup detected!${NC}"
    echo -e "${YELLOW}Neovim will install plugins on first launch.${NC}"
    echo -e "${YELLOW}This may take a minute when you first run 'nvim'.${NC}"
    
    # Mark as initialized
    touch ~/.config/nvim/.docker-initialized
    echo ""
fi

# Display welcome message
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Welcome to Neovim in Docker!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Quick tips:${NC}"
echo "• Run 'nvim' to start Neovim"
echo "• Run ':Mason' to manage language servers"
echo "• Run ':MasonToolsInstall' to install configured tools"
echo "• Run ':checkhealth' to verify setup"
echo ""
echo -e "${YELLOW}This is a standalone image with embedded config${NC}"
echo ""

# If no command provided, start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    # Execute the provided command
    exec "$@"
fi