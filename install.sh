#!/usr/bin/env bash

# ============================================================================
# Vim Configuration - Quick Installation Script
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}==>${NC} ${BOLD}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}Vim Configuration Installer${NC}"
echo -e "${BOLD}========================================${NC}\n"

# Verify .vimrc exists in script directory
if [ ! -f "$SCRIPT_DIR/.vimrc" ]; then
    print_error "Cannot find .vimrc in $SCRIPT_DIR"
    echo "Please run this script from the chopsticks directory:"
    echo "  cd ~/.vim && ./install.sh"
    exit 1
fi

# Check if vim is installed
if ! command -v vim &> /dev/null; then
    print_error "Vim is not installed. Please install Vim first."
    echo "  Ubuntu/Debian: sudo apt install vim"
    echo "  macOS: brew install vim"
    echo "  Fedora: sudo dnf install vim"
    exit 1
fi

print_status "Vim version: $(vim --version | head -n1)"

# Backup existing .vimrc if it exists
if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    BACKUP_FILE="$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backing up existing .vimrc to $BACKUP_FILE"
    mv "$HOME/.vimrc" "$BACKUP_FILE"
fi

# Create symlink to .vimrc
print_status "Creating symlink: $HOME/.vimrc -> $SCRIPT_DIR/.vimrc"
ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"

# Verify symlink was created correctly
if [ -L "$HOME/.vimrc" ]; then
    LINK_TARGET=$(readlink "$HOME/.vimrc")
    if [ "$LINK_TARGET" = "$SCRIPT_DIR/.vimrc" ]; then
        echo -e "${GREEN}[OK]${NC} Symlink created successfully"
    else
        print_warning "Symlink points to unexpected target: $LINK_TARGET"
    fi
else
    print_error "Failed to create symlink"
    exit 1
fi

# Install vim-plug if not already installed
VIM_PLUG_PATH="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG_PATH" ]; then
    print_status "Installing vim-plug..."
    curl -fLo "$VIM_PLUG_PATH" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo -e "${GREEN}[OK]${NC} vim-plug installed successfully"
else
    echo -e "${GREEN}[OK]${NC} vim-plug already installed"
fi

# Install plugins
print_status "Installing Vim plugins..."
vim +PlugInstall +qall

echo -e "\n${GREEN}[OK]${NC} ${BOLD}Installation complete!${NC}\n"

# Print optional dependencies
echo -e "${BOLD}Optional Dependencies (Recommended):${NC}"
echo ""
echo -e "${BOLD}1. FZF (Fuzzy Finder):${NC}"
echo "   Ubuntu/Debian: sudo apt install fzf ripgrep"
echo "   macOS: brew install fzf ripgrep"
echo ""
echo -e "${BOLD}2. Node.js (for CoC completion):${NC}"
echo "   Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install -y nodejs"
echo "   macOS: brew install node"
echo ""
echo -e "${BOLD}3. Universal Ctags (for code navigation):${NC}"
echo "   Ubuntu/Debian: sudo apt install universal-ctags"
echo "   macOS: brew install universal-ctags"
echo ""
echo -e "${BOLD}4. Language-specific tools:${NC}"
echo "   Python: pip install black flake8 pylint"
echo "   JavaScript: npm install -g prettier eslint"
echo "   Go: go install golang.org/x/tools/gopls@latest"
echo ""

# Ask to install CoC language servers
read -p "Do you want to install CoC language servers now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing CoC language servers..."

    # Check if node is installed
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
    else
        vim +'CocInstall -sync coc-json coc-tsserver coc-pyright coc-sh coc-html coc-css coc-yaml' +qall
        echo -e "${GREEN}[OK]${NC} CoC language servers installed"
    fi
fi

echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${GREEN}All done!${NC} Open Vim and start coding!"
echo -e "${BOLD}========================================${NC}"
echo ""
echo -e "Quick tips:"
echo "  - Press ${BOLD}Ctrl+n${NC} to toggle file explorer (NERDTree)"
echo "  - Press ${BOLD}Ctrl+p${NC} to fuzzy search files (FZF)"
echo "  - Press ${BOLD},w${NC} to quick save"
echo "  - Press ${BOLD}K${NC} on a function to see documentation"
echo "  - See README.md for complete key mappings"
echo ""
