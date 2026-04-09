#!/usr/bin/env bash
# install.sh - chopsticks vim configuration installer
# Usage: cd /path/to/chopsticks && ./install.sh [--yes]
#
# --yes  non-interactive: install all optional components automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_YES=0
[[ "${1:-}" == "--yes" ]] && AUTO_YES=1

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()    { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[!]${NC}  $1"; }
skip()  { echo -e "${CYAN}[--]${NC}  $1"; }
fail()  { echo -e "${RED}[ERR]${NC} $1"; }
die()   { echo -e "${RED}[ERR]${NC} $1" >&2; exit 1; }
step()  { echo -e "\n${BOLD}==> $1${NC}"; }

# Track results for summary
INSTALLED=()
SKIPPED=()
FAILED=()

# Ask yes/no; returns 0 for yes
ask() {
    [[ $AUTO_YES -eq 1 ]] && return 0
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Try to install a single binary tool via a given command
# Usage: try_install <display_name> <check_cmd> <install_cmd...>
try_install() {
    local name="$1"; local check="$2"; shift 2
    if command -v "$check" >/dev/null 2>&1; then
        ok "$name (already installed: $(command -v "$check"))"
        return 0
    fi
    if "$@" >/dev/null 2>&1; then
        ok "$name"
        INSTALLED+=("$name")
    else
        fail "$name — install failed (run manually: $*)"
        FAILED+=("$name")
    fi
}

echo -e "${BOLD}chopsticks — Vim Configuration Installer${NC}"
echo "----------------------------------------"

# ============================================================================
# Preflight
# ============================================================================

step "Checking environment"

[ -f "$SCRIPT_DIR/.vimrc" ] || die ".vimrc not found in $SCRIPT_DIR"

command -v vim >/dev/null 2>&1 || die "vim not found.
  Ubuntu/Debian:  sudo apt install vim
  Fedora:         sudo dnf install vim
  macOS:          brew install vim"

VIM_VERSION=$(vim --version | head -n1)
ok "Found $VIM_VERSION"

vim --version | grep -q 'Vi IMproved 8\|Vi IMproved 9' || \
    warn "Vim 8.0+ recommended for full LSP support."

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == darwin* ]]; then
    OS="macos"
elif [[ -f /etc/debian_version ]]; then
    OS="debian"
elif [[ -f /etc/fedora-release ]]; then
    OS="fedora"
elif [[ -f /etc/arch-release ]]; then
    OS="arch"
fi
ok "OS: $OS"

# Detect package managers
HAS_BREW=0;  command -v brew >/dev/null 2>&1  && HAS_BREW=1
HAS_APT=0;   command -v apt  >/dev/null 2>&1  && HAS_APT=1
HAS_DNF=0;   command -v dnf  >/dev/null 2>&1  && HAS_DNF=1
HAS_PACMAN=0; command -v pacman >/dev/null 2>&1 && HAS_PACMAN=1
HAS_NODE=0;   command -v node >/dev/null 2>&1  && HAS_NODE=1  && ok "Node.js $(node --version) detected"
HAS_PYTHON=0; command -v python3 >/dev/null 2>&1 && HAS_PYTHON=1
HAS_PIP=0;    command -v pip3 >/dev/null 2>&1  && HAS_PIP=1
HAS_GO=0;     command -v go   >/dev/null 2>&1  && HAS_GO=1    && ok "Go $(go version | awk '{print $3}') detected"

# Bootstrap pip3 when python3 exists but pip3 is absent (common on Ubuntu minimal images)
if [[ $HAS_PYTHON -eq 1 && $HAS_PIP -eq 0 ]]; then
    warn "python3 found but pip3 missing — attempting bootstrap"
    if python3 -m ensurepip --upgrade >/dev/null 2>&1 || \
       (command -v apt-get >/dev/null 2>&1 && sudo apt-get install -y python3-pip >/dev/null 2>&1) || \
       (command -v pacman >/dev/null 2>&1 && sudo pacman -S --noconfirm python-pip >/dev/null 2>&1) || \
       (command -v dnf >/dev/null 2>&1 && sudo dnf install -y python3-pip >/dev/null 2>&1); then
        command -v pip3 >/dev/null 2>&1 && HAS_PIP=1 && ok "pip3 bootstrapped"
    else
        warn "pip3 bootstrap failed — Python tools will be skipped"
    fi
fi

[[ $HAS_PIP   -eq 1 ]] && ok "Python/pip3 detected"
[[ $HAS_NODE  -eq 0 ]] && warn "Node.js not found — JS/TS/Markdown npm tools will be skipped"
[[ $HAS_PIP   -eq 0 ]] && warn "pip3 not found — Python tools will be skipped"
[[ $HAS_GO    -eq 0 ]] && warn "Go not found — Go tools will be skipped"

# ============================================================================
# Symlink
# ============================================================================

step "Setting up ~/.vimrc symlink"

if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing ~/.vimrc to ~/.vimrc.backup.$TS"
    mv "$HOME/.vimrc" "$HOME/.vimrc.backup.$TS"
fi

ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
ok "~/.vimrc -> $SCRIPT_DIR/.vimrc"

# CoC settings (marksman markdown LSP + format-on-save config)
mkdir -p "$HOME/.vim"
COC_CFG="$HOME/.vim/coc-settings.json"
if [ -f "$COC_CFG" ] && [ ! -L "$COC_CFG" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing coc-settings.json to ~/.vim/coc-settings.json.backup.$TS"
    mv "$COC_CFG" "$COC_CFG.backup.$TS"
fi
ln -sf "$SCRIPT_DIR/coc-settings.json" "$COC_CFG"
ok "~/.vim/coc-settings.json -> $SCRIPT_DIR/coc-settings.json"

# ============================================================================
# vim-plug + plugins
# ============================================================================

step "Installing vim-plug"

VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG" ]; then
    curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed"
else
    ok "vim-plug already present"
fi

step "Installing Vim plugins"
# </dev/null prevents Vim from reading stdin in non-interactive/piped environments
vim +PlugInstall +qall </dev/null
ok "Plugins installed"

# ============================================================================
# System tools (ripgrep, fzf, ctags, shellcheck, marksman)
# ============================================================================

step "System tools"

if ask "Install system tools (ripgrep, fzf, ctags, shellcheck, hadolint, marksman)?"; then
    install_sys() {
        local name="$1"; local check="$2"; shift 2
        if command -v "$check" >/dev/null 2>&1; then
            ok "$name (already installed)"
            return
        fi
        local installed=0
        for cmd in "$@"; do
            if eval "$cmd" >/dev/null 2>&1; then installed=1; break; fi
        done
        if [[ $installed -eq 1 ]]; then
            ok "$name"
            INSTALLED+=("$name")
        else
            fail "$name — could not install automatically"
            FAILED+=("$name")
        fi
    }

    if [[ $OS == macos ]]; then
        command -v brew >/dev/null 2>&1 || { warn "brew not found — skipping system tools"; }
        install_sys "ripgrep"          rg         "brew install ripgrep"
        install_sys "fzf"              fzf        "brew install fzf"
        install_sys "universal-ctags"  ctags      "brew install universal-ctags"
        install_sys "shellcheck"       shellcheck "brew install shellcheck"
        install_sys "hadolint"         hadolint   "brew install hadolint"
        install_sys "marksman"         marksman   "brew install marksman"
    elif [[ $HAS_APT -eq 1 ]]; then
        sudo apt-get update -qq
        install_sys "ripgrep"         rg         "sudo apt-get install -y ripgrep"
        install_sys "fzf"             fzf        "sudo apt-get install -y fzf"
        install_sys "universal-ctags" ctags      "sudo apt-get install -y universal-ctags"
        install_sys "shellcheck"      shellcheck "sudo apt-get install -y shellcheck"
        # hadolint: no apt package, download binary
        if ! command -v hadolint >/dev/null 2>&1; then
            ARCH=$(uname -m)
            [[ "$ARCH" == "x86_64" ]] && HARCH="x86_64" || HARCH="arm64"
            HVER=$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest \
                   | grep '"tag_name"' | cut -d'"' -f4)
            if [[ -n "$HVER" ]]; then
                curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${HVER}/hadolint-Linux-${HARCH}" \
                    -o /tmp/hadolint && chmod +x /tmp/hadolint && sudo mv /tmp/hadolint /usr/local/bin/hadolint
                ok "hadolint"
                INSTALLED+=("hadolint")
            else
                warn "hadolint: could not detect latest release, install manually"
                SKIPPED+=("hadolint")
            fi
        else
            ok "hadolint (already installed)"
        fi
        # marksman: no apt package, download binary
        if ! command -v marksman >/dev/null 2>&1; then
            ARCH=$(uname -m)
            [[ "$ARCH" == "x86_64" ]] && MARCH="x64" || MARCH="arm64"
            MVER=$(curl -s https://api.github.com/repos/artempyanykh/marksman/releases/latest \
                   | grep '"tag_name"' | cut -d'"' -f4)
            if [[ -n "$MVER" ]]; then
                curl -fsSL "https://github.com/artempyanykh/marksman/releases/download/${MVER}/marksman-linux-${MARCH}" \
                    -o /tmp/marksman && chmod +x /tmp/marksman && sudo mv /tmp/marksman /usr/local/bin/marksman
                ok "marksman"
                INSTALLED+=("marksman")
            else
                warn "marksman: could not detect latest release, install manually"
                SKIPPED+=("marksman")
            fi
        else
            ok "marksman (already installed)"
        fi
    elif [[ $HAS_PACMAN -eq 1 ]]; then
        install_sys "ripgrep"         rg         "sudo pacman -S --noconfirm ripgrep"
        install_sys "fzf"             fzf        "sudo pacman -S --noconfirm fzf"
        install_sys "universal-ctags" ctags      "sudo pacman -S --noconfirm ctags"
        install_sys "shellcheck"      shellcheck "sudo pacman -S --noconfirm shellcheck"
        install_sys "hadolint"        hadolint   "sudo pacman -S --noconfirm hadolint"
        install_sys "marksman"        marksman   "sudo pacman -S --noconfirm marksman"
    elif [[ $HAS_DNF -eq 1 ]]; then
        install_sys "ripgrep"         rg         "sudo dnf install -y ripgrep"
        install_sys "fzf"             fzf        "sudo dnf install -y fzf"
        install_sys "shellcheck"      shellcheck "sudo dnf install -y ShellCheck"
        skip "universal-ctags — install manually: sudo dnf install ctags"
        SKIPPED+=("ctags")
        skip "hadolint — install manually from https://github.com/hadolint/hadolint/releases"
        SKIPPED+=("hadolint")
        skip "marksman — install manually from https://github.com/artempyanykh/marksman/releases"
        SKIPPED+=("marksman")
    else
        warn "Unknown Linux distro — skipping system tools (install manually)"
        SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
    fi
else
    skip "system tools"
    SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
fi

# ============================================================================
# npm tools (prettier, markdownlint-cli, stylelint, eslint, typescript)
# ============================================================================

step "npm tools (formatters + linters)"

if [[ $HAS_NODE -eq 1 ]]; then
    if ask "Install npm tools (prettier, markdownlint-cli, stylelint, eslint, typescript)?"; then
        npm_install() {
            local pkg="$1"; local check="${2:-$1}"
            if command -v "$check" >/dev/null 2>&1; then
                ok "$pkg (already installed)"
                return
            fi
            if npm install -g "$pkg" >/dev/null 2>&1; then
                ok "$pkg"
                INSTALLED+=("$pkg")
            else
                fail "$pkg"
                FAILED+=("$pkg")
            fi
        }
        npm_install prettier
        npm_install markdownlint-cli markdownlint
        npm_install stylelint
        npm_install stylelint-config-standard
        npm_install eslint
        npm_install typescript tsc
    else
        skip "npm tools"
        SKIPPED+=("prettier" "markdownlint-cli" "stylelint" "eslint" "typescript")
    fi
else
    skip "npm tools (Node.js not installed)"
    SKIPPED+=("prettier" "markdownlint-cli" "stylelint" "eslint" "typescript")
fi

# ============================================================================
# pip tools (black, isort, flake8, pylint, sqlfluff)
# ============================================================================

step "Python tools (formatters + linters)"

if [[ $HAS_PIP -eq 1 ]]; then
    if ask "Install Python tools (black, isort, flake8, pylint, yamllint, sqlfluff)?"; then
        pip_install() {
            local pkg="$1"; local check="${2:-$1}"
            if command -v "$check" >/dev/null 2>&1; then
                ok "$pkg (already installed)"
                return
            fi
            if pip3 install --quiet "$pkg" 2>/dev/null || \
               pip3 install --quiet --break-system-packages "$pkg" 2>/dev/null; then
                ok "$pkg"
                INSTALLED+=("$pkg")
            else
                fail "$pkg"
                FAILED+=("$pkg")
            fi
        }
        pip_install black
        pip_install isort
        pip_install flake8
        pip_install pylint
        pip_install yamllint
        pip_install sqlfluff
    else
        skip "Python tools"
        SKIPPED+=("black" "isort" "flake8" "pylint" "yamllint" "sqlfluff")
    fi
else
    skip "Python tools (pip3 not installed)"
    SKIPPED+=("black" "isort" "flake8" "pylint" "yamllint" "sqlfluff")
fi

# ============================================================================
# Go tools (gopls, goimports, staticcheck)
# ============================================================================

step "Go tools"

if [[ $HAS_GO -eq 1 ]]; then
    if ask "Install Go tools (gopls, goimports, staticcheck)?"; then
        # Go installs binaries to $(go env GOPATH)/bin — add to PATH for this session
        GOBIN="$(go env GOPATH)/bin"
        export PATH="$PATH:$GOBIN"

        go_install() {
            local name="$1"; local pkg="$2"; local check="$3"
            if command -v "$check" >/dev/null 2>&1 || [[ -x "$GOBIN/$check" ]]; then
                ok "$name (already installed)"
                return
            fi
            if go install "$pkg" >/dev/null 2>&1; then
                ok "$name"
                INSTALLED+=("$name")
            else
                fail "$name"
                FAILED+=("$name")
            fi
        }
        go_install gopls       "golang.org/x/tools/gopls@latest"                   gopls
        go_install goimports   "golang.org/x/tools/cmd/goimports@latest"             goimports
        go_install staticcheck "honnef.co/go/tools/cmd/staticcheck@latest"            staticcheck

        # Remind user to add GOPATH/bin to their shell profile
        if ! echo "$PATH" | grep -q "$GOBIN"; then
            warn "Add Go binaries to PATH: export PATH=\"\$PATH:$GOBIN\""
        fi
    else
        skip "Go tools"
        SKIPPED+=("gopls" "goimports" "staticcheck")
    fi
else
    skip "Go tools (go not installed)"
    SKIPPED+=("gopls" "goimports" "staticcheck")
fi

# ============================================================================
# tmux: vim-tmux-navigator integration
# ============================================================================

step "tmux: vim-tmux-navigator integration"

if command -v tmux >/dev/null 2>&1; then
    TMUX_CONF="$HOME/.tmux.conf"
    # Check if already configured
    if grep -q 'vim-tmux-navigator' "$TMUX_CONF" 2>/dev/null; then
        ok "vim-tmux-navigator bindings already present in ~/.tmux.conf"
    else
        if ask "Append vim-tmux-navigator bindings to ~/.tmux.conf (enables seamless Ctrl+h/j/k/l across vim and tmux)?"; then
            cat >> "$TMUX_CONF" << 'TMUXEOF'

# vim-tmux-navigator: seamless Ctrl+h/j/k/l navigation between vim and tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
TMUXEOF
            ok "vim-tmux-navigator bindings appended to ~/.tmux.conf"
            warn "Reload tmux config now: tmux source-file ~/.tmux.conf"
            warn "Note: C-l now navigates panes instead of clearing the screen."
            warn "      To restore clear: add 'bind C-l send-keys C-l' to ~/.tmux.conf"
            INSTALLED+=("tmux-navigator-config")
        else
            skip "tmux navigator config"
            SKIPPED+=("tmux-navigator-config")
        fi
    fi
else
    skip "tmux not found — skipping navigator config"
    SKIPPED+=("tmux-navigator-config")
fi

# ============================================================================
# CoC language server extensions
# ============================================================================

step "CoC language server extensions"

if [[ $HAS_NODE -eq 1 ]]; then
    if ask "Install CoC language servers (LSP for all configured languages)?"; then
        # Note: coc-marksman doesn't exist on npm — markdown LSP is handled via coc-settings.json
        vim +'CocInstall -sync coc-json coc-tsserver coc-pyright coc-sh coc-html coc-css coc-yaml coc-go coc-rust-analyzer coc-sql' +qall </dev/null
        ok "CoC language servers installed"
    else
        skip "CoC language servers"
        echo "     Install later with :CocInstall <name> inside Vim"
    fi
else
    warn "Node.js not found — using vim-lsp fallback (run :LspInstallServer inside Vim)"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BOLD}=======================================${NC}"
echo -e "${GREEN}Installation complete.${NC}"
echo -e "${BOLD}=======================================${NC}"

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo -e "\n${GREEN}Installed:${NC}"
    for t in "${INSTALLED[@]}"; do echo "  + $t"; done
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo -e "\n${CYAN}Skipped:${NC}"
    for t in "${SKIPPED[@]}"; do echo "  - $t"; done
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "\n${RED}Failed (install manually):${NC}"
    for t in "${FAILED[@]}"; do echo "  ! $t"; done
fi

echo ""
echo -e "${BOLD}---------------------------------------${NC}"
echo -e "${BOLD}  You're ready. Open Vim with:${NC}"
echo -e "${BOLD}---------------------------------------${NC}"
echo -e "  ${CYAN}vim${NC}            Launch startup dashboard"
echo -e "  ${CYAN}vim .${NC}          Open file tree + dashboard"
echo -e "  ${CYAN}vim myfile${NC}     Edit a specific file"
echo ""
echo -e "${BOLD}  Survival Guide (first-time Vim users)${NC}"
echo -e "  ${CYAN}Esc${NC} or ${CYAN}jk${NC}     Exit insert mode → back to Normal"
echo -e "  ${CYAN}:q!${NC} + Enter   Emergency quit without saving"
echo -e "  ${CYAN},x${NC}            Save and quit"
echo -e "  ${CYAN},?${NC}            Open cheat sheet inside Vim"
echo -e "  ${CYAN},${NC} + pause     Interactive keybinding guide"
echo ""
echo -e "${YELLOW}[!]${NC}  Ctrl+s is mapped to save in Vim."
echo    "     If it freezes your terminal, add this to ~/.bashrc or ~/.zshrc:"
echo -e "     ${CYAN}stty -ixon${NC}"
echo ""
