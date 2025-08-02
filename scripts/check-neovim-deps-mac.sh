#!/bin/bash

# Neovim Dependencies Check Script for macOS
# This script checks which dependencies are installed and reports what's missing

set -e

echo "🔍 Checking Neovim dependencies for macOS..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track missing dependencies
MISSING_DEPS=()
MISSING_BREW=()

# Function to check if a command exists
check_command() {
    local cmd=$1
    local brew_pkg=$2
    local description=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd - $description"
        if [[ "$cmd" != "brew" ]]; then
            version=$($cmd --version 2>&1 | head -n1 || echo "version unknown")
            echo "  └─ $version"
        fi
    else
        echo -e "${RED}✗${NC} $cmd - $description"
        MISSING_DEPS+=("$cmd")
        if [[ -n "$brew_pkg" ]]; then
            MISSING_BREW+=("$brew_pkg")
        fi
    fi
}

# Function to check Mason-managed tools
check_mason_tool() {
    local cmd=$1
    local description=$2
    local mason_name=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd - $description"
        version=$($cmd --version 2>&1 | head -n1 || echo "version unknown")
        echo "  └─ $version"
    else
        echo -e "${BLUE}◎${NC} $cmd - $description"
        echo "  └─ Can be installed via Mason: :MasonInstall $mason_name"
    fi
}

# Function to check Node/npm via fnm
check_node() {
    if command -v fnm &> /dev/null; then
        echo -e "${GREEN}✓${NC} fnm - Fast Node Manager"
        if fnm list | grep -q "lts"; then
            echo -e "${GREEN}✓${NC} node - JavaScript runtime (via fnm)"
            eval "$(fnm env --use-on-cd)" 2>/dev/null || true
            node_version=$(node --version 2>/dev/null || echo "not active")
            echo "  └─ $node_version"
        else
            echo -e "${YELLOW}⚠${NC} node - Not installed via fnm"
            echo "  └─ Run: fnm install --lts"
        fi
    else
        echo -e "${RED}✗${NC} fnm - Fast Node Manager"
        MISSING_DEPS+=("fnm")
        MISSING_BREW+=("fnm")
    fi
}

# Function to check Rust toolchain
check_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}✓${NC} rustc - Rust compiler"
        rustc_version=$(rustc --version)
        echo "  └─ $rustc_version"
        
        if command -v rust-analyzer &> /dev/null; then
            echo -e "${GREEN}✓${NC} rust-analyzer - Rust LSP"
        else
            echo -e "${YELLOW}⚠${NC} rust-analyzer - Rust LSP"
            echo "  └─ Run: rustup component add rust-analyzer"
        fi
    else
        echo -e "${RED}✗${NC} rustc - Rust compiler"
        echo "  └─ Install: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        MISSING_DEPS+=("rustc")
    fi
}

echo ""
echo "Core Dependencies:"
echo "------------------"

# Check Homebrew first
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗${NC} Homebrew - Package manager for macOS"
    echo ""
    echo "❌ Homebrew is required but not installed!"
    echo "Install with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
else
    echo -e "${GREEN}✓${NC} Homebrew - Package manager for macOS"
fi

# Check core tools
check_command "nvim" "neovim" "Neovim editor"
check_command "git" "git" "Version control"
check_command "make" "make" "Build tool"
check_command "gcc" "gcc" "C compiler"
check_command "gh" "gh" "GitHub CLI"
check_command "go" "go" "Go programming language"
check_command "python3" "python3" "Python interpreter"
check_command "pipx" "pipx" "Python app installer"

echo ""
echo "Search & Navigation Tools:"
echo "-------------------------"
check_command "fzf" "fzf" "Fuzzy finder"
check_command "rg" "ripgrep" "Fast grep alternative"
check_command "fd" "fd" "Fast find alternative"

echo ""
echo "Node.js Environment:"
echo "-------------------"
check_node

echo ""
echo "Rust Environment:"
echo "----------------"
check_rust

echo ""
echo "C/C++ Tools:"
echo "------------"
check_command "clang-tidy" "llvm" "C++ linter"
if ! command -v clang-tidy &> /dev/null && command -v /opt/homebrew/opt/llvm/bin/clang-tidy &> /dev/null; then
    echo -e "${YELLOW}  └─ Note:${NC} clang-tidy is installed but not in PATH"
    echo "     Add to PATH: echo 'export PATH=\"/opt/homebrew/opt/llvm/bin:\$PATH\"' >> ~/.zshrc"
fi

echo ""
echo "Language Servers (Mason-managed):"
echo "--------------------------------"
check_mason_tool "clangd" "C/C++ language server" "clangd"
check_mason_tool "rust-analyzer" "Rust language server" "rust-analyzer"
check_mason_tool "pyright" "Python language server" "pyright"
check_mason_tool "typescript-language-server" "TypeScript language server" "typescript-language-server"
check_mason_tool "gopls" "Go language server" "gopls"
check_mason_tool "lua-language-server" "Lua language server" "lua-language-server"
check_mason_tool "buf" "Protocol buffers language server" "buf"
check_mason_tool "yaml-language-server" "YAML language server" "yaml-language-server"

echo ""
echo "Formatters & Linters (Mason-managed):"
echo "------------------------------------"
check_mason_tool "black" "Python formatter" "black"
check_mason_tool "ruff" "Python linter" "ruff"
check_mason_tool "gofumpt" "Go formatter" "gofumpt"
check_mason_tool "goimports" "Go imports formatter" "goimports"

echo ""
echo "Python Tools:"
echo "-------------"
if command -v pipx &> /dev/null; then
    echo -e "${GREEN}✓${NC} pipx - Python app installer"
else
    echo -e "${YELLOW}⚠${NC} pipx - Python app installer"
fi

if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓${NC} uv - Modern Python package manager"
else
    echo -e "${YELLOW}⚠${NC} uv - Modern Python package manager"
    echo "  └─ Run: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

if command -v vectorcode &> /dev/null; then
    echo -e "${GREEN}✓${NC} vectorcode - AI coding assistant"
else
    echo -e "${YELLOW}⚠${NC} vectorcode - AI coding assistant"
    echo "  └─ Run: uv tool install vectorcode"
fi

echo ""
echo "================================================"
echo "Summary:"
echo "--------"

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All core dependencies are installed!${NC}"
else
    echo -e "${RED}✗ Missing ${#MISSING_DEPS[@]} core dependencies:${NC}"
    printf '%s\n' "${MISSING_DEPS[@]}" | sed 's/^/  - /'
    
    if [ ${#MISSING_BREW[@]} -gt 0 ]; then
        echo ""
        echo "To install missing Homebrew packages:"
        echo -e "${YELLOW}brew install ${MISSING_BREW[*]}${NC}"
    fi
fi

echo ""
echo "Notes:"
echo "------"
echo "• ${BLUE}◎${NC} = Can be installed via Mason within Neovim"
echo "• ${GREEN}✓${NC} = Installed and available"
echo "• ${RED}✗${NC} = Missing (required for core functionality)"
echo "• ${YELLOW}⚠${NC} = Missing (optional but recommended)"

echo ""
echo "Next steps:"
echo "1. Install any missing core dependencies"
echo "2. Run 'nvim' to start Neovim"
echo "3. Inside Neovim, run ':Mason' to manually install language servers"
echo "4. Or run ':MasonToolsInstall' to install configured formatters/linters"
echo ""
echo "For complete setup, run: ${YELLOW}./setup-neovim-deps-mac.sh${NC}"
echo "To check Neovim health: ${YELLOW}nvim -c ':checkhealth'${NC}"