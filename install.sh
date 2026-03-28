#!/usr/bin/env bash
# install.sh - chopsticks vim configuration installer
# Usage: cd ~/.vim && ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }
die()  { echo -e "${RED}[ERR]${NC} $1" >&2; exit 1; }
step() { echo -e "\n${BOLD}==> $1${NC}"; }

echo -e "${BOLD}chopsticks - Vim Configuration Installer${NC}"
echo "----------------------------------------"

# --- Preflight checks ---

step "Checking environment"

[ -f "$SCRIPT_DIR/.vimrc" ] || die ".vimrc not found in $SCRIPT_DIR. Run from the cloned repo: cd ~/.vim && ./install.sh"

command -v vim >/dev/null 2>&1 || die "vim not found. Install it first:
  Ubuntu/Debian: sudo apt install vim
  Fedora:        sudo dnf install vim
  macOS:         brew install vim"

VIM_VERSION=$(vim --version | head -n1)
ok "Found $VIM_VERSION"

# Check Vim version >= 8.0
vim --version | grep -q 'Vi IMproved 8\|Vi IMproved 9' || \
    warn "Vim 8.0+ recommended for full LSP support. Some features may be missing."

# Detect Node.js for CoC
HAS_NODE=0
if command -v node >/dev/null 2>&1; then
    NODE_VER=$(node --version)
    ok "Node.js $NODE_VER detected - CoC LSP will be available"
    HAS_NODE=1
else
    warn "Node.js not found - will use vim-lsp (no Node.js required)"
    echo "     Install Node.js later to enable CoC: https://nodejs.org/en/download"
fi

# --- Symlink ---

step "Setting up ~/.vimrc symlink"

if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing ~/.vimrc to ~/.vimrc.backup.$TS"
    mv "$HOME/.vimrc" "$HOME/.vimrc.backup.$TS"
fi

ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"

if [ "$(readlink "$HOME/.vimrc")" = "$SCRIPT_DIR/.vimrc" ]; then
    ok "~/.vimrc -> $SCRIPT_DIR/.vimrc"
else
    die "Symlink verification failed"
fi

# --- vim-plug ---

step "Installing vim-plug"

VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG" ]; then
    curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed"
else
    ok "vim-plug already present"
fi

# --- Plugins ---

step "Installing Vim plugins"

vim +PlugInstall +qall
ok "Plugins installed"

# --- Optional: CoC language servers ---

echo ""
if [ "$HAS_NODE" -eq 1 ]; then
    read -p "Install CoC language servers for common languages? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        step "Installing CoC language servers"
        vim +'CocInstall -sync coc-json coc-tsserver coc-pyright coc-sh coc-html coc-css coc-yaml coc-go coc-rust-analyzer coc-marksman coc-sql' +qall
        ok "CoC language servers installed"
    fi
else
    echo "  To enable LSP without Node.js:"
    echo "  1. Open a source file in Vim"
    echo "  2. Run :LspInstallServer"
    echo "  3. vim-lsp-settings will auto-install the right language server"
fi

# --- Done ---

echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${GREEN}Installation complete.${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo "Optional tools (install for best experience):"
echo ""
echo "  ripgrep  (,rg project search)"
echo "    Ubuntu:  sudo apt install ripgrep"
echo "    macOS:   brew install ripgrep"
echo ""
echo "  fzf  (Ctrl+p file search)"
echo "    Ubuntu:  sudo apt install fzf"
echo "    macOS:   brew install fzf"
echo ""
echo "  ctags  (F8 tag browser)"
echo "    Ubuntu:  sudo apt install universal-ctags"
echo "    macOS:   brew install universal-ctags"
echo ""
echo "  Language linters and formatters:"
echo "    Python:      pip install black flake8 pylint isort"
echo "    JS/TS:       npm install -g prettier eslint typescript"
echo "    Go:          go install golang.org/x/tools/gopls@latest"
echo "    Shell:       sudo apt install shellcheck  # or: brew install shellcheck"
echo "    CSS/SCSS:    npm install -g stylelint stylelint-config-standard"
echo "    Markdown:    npm install -g markdownlint-cli"
echo "    SQL:         pip install sqlfluff  |  npm install -g sqlfmt"
echo "    Markdown LS: brew install marksman  # or: https://github.com/artempyanykh/marksman"
echo ""
echo "Getting started:"
echo "  See QUICKSTART.md for the 5-minute guide"
echo "  Run 'vim' and press ',' then wait 500ms for keybinding hints"
echo ""
