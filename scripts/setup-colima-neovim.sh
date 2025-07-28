#!/bin/bash

# Colima Setup Script for Neovim Development
# This script creates a Colima VM optimized for Neovim development

set -e

echo "🚀 Setting up Colima VM for Neovim development..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Colima is installed
if ! command -v colima &> /dev/null; then
    echo -e "${RED}✗ Colima is not installed${NC}"
    echo "Install with: brew install colima"
    exit 1
fi

# Check if Docker is installed (required for Colima)
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker CLI is not installed${NC}"
    echo "Install with: brew install docker"
    exit 1
fi

# VM Configuration
VM_NAME="neovim-dev"
CPUS=2
MEMORY=4
DISK=20
ARCH=$(uname -m)

# Set architecture flag
if [ "$ARCH" = "arm64" ]; then
    ARCH_FLAG="--arch aarch64"
else
    ARCH_FLAG="--arch x86_64"
fi

echo -e "${BLUE}Creating Colima VM with:${NC}"
echo "  • Name: $VM_NAME"
echo "  • CPUs: $CPUS"
echo "  • Memory: ${MEMORY}GB"
echo "  • Disk: ${DISK}GB"
echo "  • Architecture: $ARCH"

# Stop existing VM if it exists
if colima list | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}Stopping existing VM...${NC}"
    colima stop "$VM_NAME" 2>/dev/null || true
    colima delete "$VM_NAME" --force 2>/dev/null || true
fi

# Get the dotfiles directory path
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create the VM with optimized settings
echo -e "${BLUE}Creating Colima VM...${NC}"
colima start "$VM_NAME" \
    --cpu "$CPUS" \
    --memory "$MEMORY" \
    --disk "$DISK" \
    $ARCH_FLAG \
    --mount "$DOTFILES_DIR:/home/dotfiles:cached" \
    --ssh-agent

# Wait for VM to be ready
echo -e "${YELLOW}Waiting for VM to be ready...${NC}"
sleep 5

# Install dependencies in the VM
echo -e "${BLUE}Installing dependencies in VM...${NC}"
colima ssh -p "$VM_NAME" << 'EOF'
# Update package list
sudo apt-get update

# Run the Linux setup script
cd /home/dotfiles
chmod +x scripts/setup-neovim-deps-linux.sh
./scripts/setup-neovim-deps-linux.sh

# Create symlink to Neovim config
mkdir -p ~/.config
ln -sf /home/dotfiles/neovim/.config/nvim ~/.config/nvim

# Install Neovim plugins
echo "Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

echo "✅ VM setup complete!"
EOF

# Create helper script
HELPER_SCRIPT="$HOME/.local/bin/colima-nvim"
mkdir -p "$HOME/.local/bin"

cat > "$HELPER_SCRIPT" << EOF
#!/bin/bash
# Helper script to access Neovim in Colima VM

case "\$1" in
    ssh)
        colima ssh -p "$VM_NAME"
        ;;
    nvim)
        colima ssh -p "$VM_NAME" -- nvim "\${@:2}"
        ;;
    exec)
        colima ssh -p "$VM_NAME" -- "\${@:2}"
        ;;
    stop)
        colima stop -p "$VM_NAME"
        ;;
    start)
        colima start -p "$VM_NAME"
        ;;
    status)
        colima list | grep "$VM_NAME" || echo "VM not found"
        ;;
    *)
        echo "Usage: colima-nvim {ssh|nvim|exec|stop|start|status}"
        echo ""
        echo "Commands:"
        echo "  ssh              - SSH into the VM"
        echo "  nvim [args]      - Run Neovim in the VM"
        echo "  exec <command>   - Execute a command in the VM"
        echo "  stop             - Stop the VM"
        echo "  start            - Start the VM"
        echo "  status           - Check VM status"
        ;;
esac
EOF

chmod +x "$HELPER_SCRIPT"

echo ""
echo -e "${GREEN}✅ Colima VM setup complete!${NC}"
echo ""
echo -e "${BLUE}Quick start commands:${NC}"
echo "  colima-nvim ssh        # SSH into the VM"
echo "  colima-nvim nvim       # Start Neovim directly"
echo "  colima-nvim exec bash  # Run bash in the VM"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo "• Your dotfiles are mounted at: /home/dotfiles"
echo "• Neovim config is linked to: ~/.config/nvim"
echo "• The VM will persist between restarts"
echo "• Helper script installed at: $HELPER_SCRIPT"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"