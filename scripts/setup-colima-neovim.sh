#!/bin/bash

# Colima Setup Script for Neovim Development
# This script configures an externally provisioned Colima VM. It never creates,
# stops, deletes, or recreates the VM.

set -eu

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

HELPER_DIR="$HOME/.local/bin"
HELPER_SCRIPT="$HELPER_DIR/colima-nvim"

if [ ! -d "$HELPER_DIR" ] || [ -L "$HELPER_DIR" ] || [ ! -w "$HELPER_DIR" ]; then
    echo -e "${RED}✗ Local helper directory must be an existing, writable, non-symlink directory: $HELPER_DIR${NC}"
    exit 1
fi

if [ -L "$HELPER_SCRIPT" ] || { [ -e "$HELPER_SCRIPT" ] && [ ! -f "$HELPER_SCRIPT" ]; }; then
    echo -e "${RED}✗ Refusing unsafe local helper destination: $HELPER_SCRIPT${NC}"
    exit 1
fi

guest_destination_preflight='config_dir=$HOME/.config
destination=$config_dir/nvim
intended=/home/dotfiles/neovim/.config/nvim
if [ -L "$config_dir" ] || { [ -e "$config_dir" ] && [ ! -d "$config_dir" ]; }; then
    echo "error: guest config parent conflicts with existing state: $config_dir" >&2
    exit 1
elif [ -d "$config_dir" ] && [ ! -w "$config_dir" ]; then
    echo "error: guest config parent is not writable: $config_dir" >&2
    exit 1
elif [ ! -e "$config_dir" ] && { [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; }; then
    echo "error: guest home cannot create config parent: $HOME" >&2
    exit 1
elif [ -L "$destination" ]; then
    [ "$(readlink "$destination")" = "$intended" ] || {
        echo "error: guest destination is not the intended symlink: $destination" >&2
        exit 1
    }
elif [ -e "$destination" ]; then
    echo "error: guest destination conflicts with existing state: $destination" >&2
    exit 1
fi'
if ! colima ssh -p "$VM_NAME" -- sh -eu -c "$guest_destination_preflight"; then
    echo -e "${RED}✗ Guest ~/.config/nvim must be absent or link exactly to /home/dotfiles/neovim/.config/nvim${NC}"
    exit 1
fi

HELPER_TEMP=$(mktemp "$HELPER_DIR/.colima-nvim.XXXXXX")
cleanup_helper_temp() {
    rm -f "$HELPER_TEMP"
}
trap cleanup_helper_temp EXIT HUP INT TERM

cat > "$HELPER_TEMP" << 'EOF'
#!/bin/bash
# Helper script to access Neovim in Colima VM

set -eu

VM_NAME="neovim-dev"

profile_running() {
    colima list 2>/dev/null | awk -v profile="$VM_NAME" '
        NR > 1 && $1 == profile && tolower($2) == "running" { found = 1 }
        END { exit found ? 0 : 1 }
    '
}

require_running_profile() {
    if ! profile_running; then
        echo "error: expected the pre-provisioned $VM_NAME Colima profile to be running" >&2
        exit 1
    fi
}

command_name=${1-}
case "$command_name" in
    ssh)
        [ "$#" -eq 1 ] || { echo "usage: colima-nvim ssh" >&2; exit 2; }
        require_running_profile
        colima ssh -p "$VM_NAME"
        ;;
    nvim)
        shift
        require_running_profile
        colima ssh -p "$VM_NAME" -- nvim "$@"
        ;;
    exec)
        shift
        [ "$#" -gt 0 ] || { echo "usage: colima-nvim exec COMMAND [ARG...]" >&2; exit 2; }
        require_running_profile
        colima ssh -p "$VM_NAME" -- "$@"
        ;;
    status)
        [ "$#" -eq 1 ] || { echo "usage: colima-nvim status" >&2; exit 2; }
        profile_running
        ;;
    *)
        echo "Usage: colima-nvim {ssh|nvim|exec|status}"
        echo ""
        echo "Commands:"
        echo "  ssh              - SSH into the VM"
        echo "  nvim [args]      - Run Neovim in the VM"
        echo "  exec <command>   - Execute a command in the VM"
        echo "  status           - Check that the provisioned VM is running"
        exit 2
        ;;
esac
EOF
chmod 0755 "$HELPER_TEMP"
bash -n "$HELPER_TEMP"

# All local and guest destinations are safe; guest configuration can now mutate.
echo -e "${BLUE}Configuring Neovim in VM...${NC}"
colima ssh -p "$VM_NAME" << 'EOF'
set -eu

destination=$HOME/.config/nvim
intended=/home/dotfiles/neovim/.config/nvim

# Create symlink to Neovim config
mkdir -p ~/.config
if [ ! -L "$destination" ]; then
    ln -s /home/dotfiles/neovim/.config/nvim "$destination"
fi

# Install Neovim plugins
echo "Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
EOF

if [ -L "$HELPER_SCRIPT" ] || { [ -e "$HELPER_SCRIPT" ] && [ ! -f "$HELPER_SCRIPT" ]; }; then
    echo -e "${RED}✗ Refusing unsafe local helper destination: $HELPER_SCRIPT${NC}"
    exit 1
fi
mv -f "$HELPER_TEMP" "$HELPER_SCRIPT"
trap - EXIT HUP INT TERM

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
