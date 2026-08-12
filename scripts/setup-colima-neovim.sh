#!/bin/bash

# Colima Setup Script for Neovim Development
# This script configures an externally provisioned Colima VM. It never creates,
# stops, deletes, or recreates the VM.

set -e

echo "🚀 Configuring an existing Colima VM for Neovim development..."

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

# Externally owned VM configuration
VM_NAME="neovim-dev"

prerequisite_error() {
    echo -e "${RED}✗ Expected a pre-provisioned \`$VM_NAME\` Colima profile${NC}"
    echo "Provision and start that profile outside this dotfiles repository."
    echo "The running guest must have nvim installed and this repository mounted at /home/dotfiles."
}

if ! colima list 2>/dev/null | awk -v profile="$VM_NAME" '
    NR > 1 && $1 == profile { found = 1 }
    END { exit found ? 0 : 1 }
'; then
    prerequisite_error
    exit 1
fi

if ! colima ssh -p "$VM_NAME" -- command -v nvim >/dev/null 2>&1; then
    prerequisite_error
    exit 1
fi

if ! colima ssh -p "$VM_NAME" -- test -d /home/dotfiles/neovim/.config/nvim >/dev/null 2>&1; then
    echo -e "${RED}✗ Missing /home/dotfiles/neovim/.config/nvim in the \`$VM_NAME\` guest${NC}"
    echo "Mount this repository at /home/dotfiles through the external Colima profile configuration, then rerun."
    exit 1
fi

# All external prerequisites are present; guest configuration can now mutate.
echo -e "${BLUE}Configuring Neovim in VM...${NC}"
colima ssh -p "$VM_NAME" << 'EOF'
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
echo "• The externally provisioned VM was preserved"
echo "• Helper script installed at: $HELPER_SCRIPT"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
