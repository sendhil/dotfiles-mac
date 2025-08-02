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

# Display welcome message
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Welcome to Neovim in Docker!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Quick tips:${NC}"
echo "• Run 'nvim' to start Neovim"
echo "• All plugins and tools are pre-installed and ready to use!"
echo "• Run ':Mason' to view/manage language servers"
echo "• Run ':checkhealth' to verify setup"
echo ""
echo -e "${YELLOW}Workspace mounted at: /workspace${NC}"
echo ""

# If no command provided, start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    # Execute the provided command
    exec "$@"
fi