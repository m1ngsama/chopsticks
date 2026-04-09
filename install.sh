#!/usr/bin/env bash
# install.sh - chopsticks vim configuration installer
# Usage: cd /path/to/chopsticks && ./install.sh [--yes]
#
# --yes  non-interactive: install all optional components automatically

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_YES=0
[[ "${1:-}" == "--yes" ]] && AUTO_YES=1

# ── Colours ───────────────────────────────────────────────────────────────────
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
die()   { echo -e "${RED}[FATAL]${NC} $1" >&2
          echo "  Retry with: ./install.sh 2>&1 | tee /tmp/chopsticks-install.log" >&2
          echo "  Report issues: https://github.com/m1ngsama/chopsticks/issues" >&2
          exit 1; }
step()  { echo -e "\n${BOLD}==> $1${NC}"; }
info()  { echo "     $1"; }

# Track results for summary
INSTALLED=()
SKIPPED=()
FAILED=()

# Ask yes/no; returns 0 for yes
# Reads from /dev/tty so interactive prompts work even under: curl | bash
ask() {
    [[ $AUTO_YES -eq 1 ]] && return 0
    if [[ -t 0 ]]; then
        read -r -p "$1 [y/N] " reply
    elif { true </dev/tty; } 2>/dev/null; then
        read -r -p "$1 [y/N] " reply </dev/tty
    else
        # No terminal available — default to no (safe)
        echo "$1 [y/N] N"
        return 1
    fi
    [[ "$reply" =~ ^[Yy]$ ]]
}

# ── Error trap ────────────────────────────────────────────────────────────────
on_error() {
    local line="${BASH_LINENO[0]}"
    echo -e "\n${RED}[FATAL]${NC} Unexpected error at line $line." >&2
    echo "  To get a full debug log:" >&2
    echo "    ./install.sh 2>&1 | tee /tmp/chopsticks-install.log" >&2
    echo "  Report issues: https://github.com/m1ngsama/chopsticks/issues" >&2
}
trap on_error ERR

# Cleanup temp files on exit
trap 'rm -f /tmp/chopsticks-hadolint /tmp/chopsticks-marksman 2>/dev/null' EXIT

# ── Safe download helper ──────────────────────────────────────────────────────
# safe_download <url> <dest>
# Returns 1 if download fails or file is empty / HTML error page
safe_download() {
    local url="$1" dest="$2"
    curl -fsSL --connect-timeout 15 --retry 3 "$url" -o "$dest" 2>/dev/null || return 1
    # Reject empty files
    [[ -s "$dest" ]] || { rm -f "$dest"; return 1; }
    # Reject HTML error pages (GitHub 404, rate limits, etc.)
    if head -c 200 "$dest" 2>/dev/null | grep -qi "<!DOCTYPE\|<html"; then
        rm -f "$dest"; return 1
    fi
    return 0
}

# ── Cross-platform package install helper ─────────────────────────────────────
# pkg_install <brew> <apt> <pacman> <dnf>  (pass "" to skip that pkg manager)
pkg_install() {
    local brew_pkg="${1:-}" apt_pkg="${2:-}" pac_pkg="${3:-}" dnf_pkg="${4:-}"
    if   [[ $HAS_BREW   -eq 1 && -n "$brew_pkg" ]]; then brew install "$brew_pkg" >/dev/null 2>&1
    elif [[ $HAS_APT    -eq 1 && -n "$apt_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo apt-get install -y "$apt_pkg" >/dev/null 2>&1
    elif [[ $HAS_PACMAN -eq 1 && -n "$pac_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo pacman -S --noconfirm "$pac_pkg" >/dev/null 2>&1
    elif [[ $HAS_DNF    -eq 1 && -n "$dnf_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo dnf install -y "$dnf_pkg" >/dev/null 2>&1
    else return 1
    fi
}

# ── CPU architecture normalizer ───────────────────────────────────────────────
# Normalize uname -m to the naming convention used by GitHub releases
arch_github() {
    case "$(uname -m)" in
        x86_64)          echo "x86_64" ;;
        aarch64|arm64)   echo "arm64"  ;;
        armv7l)          echo "armv7"  ;;
        *)               echo "$(uname -m)" ;;
    esac
}
arch_linux_x64() {
    # Returns x64 or arm64 style (used by marksman)
    case "$(uname -m)" in
        x86_64)          echo "x64"   ;;
        aarch64|arm64)   echo "arm64" ;;
        *)               echo "$(uname -m)" ;;
    esac
}

echo -e "${BOLD}chopsticks — Vim Configuration Installer${NC}"
echo "----------------------------------------"

# ============================================================================
# 1. OS + Package Manager Detection
# ============================================================================

step "Detecting environment"

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

HAS_BREW=0;   command -v brew   >/dev/null 2>&1 && HAS_BREW=1
HAS_APT=0;    command -v apt    >/dev/null 2>&1 && HAS_APT=1
HAS_DNF=0;    command -v dnf    >/dev/null 2>&1 && HAS_DNF=1
HAS_PACMAN=0; command -v pacman >/dev/null 2>&1 && HAS_PACMAN=1

# ── sudo ─────────────────────────────────────────────────────────────────────
HAS_SUDO=0
if [[ $OS == "macos" ]]; then
    # brew handles its own privilege escalation; no sudo needed for system tools
    HAS_SUDO=1
elif sudo -n true 2>/dev/null; then
    HAS_SUDO=1
    ok "sudo: available (passwordless)"
elif [[ $AUTO_YES -eq 1 ]]; then
    warn "sudo requires a password but running non-interactively (--yes)"
    warn "System package installations will be skipped"
else
    # Prompt once for password now so later sudo calls don't interrupt flow
    warn "Some steps require sudo. Authenticating now..."
    if sudo true; then
        HAS_SUDO=1
        ok "sudo: authenticated"
    else
        warn "sudo not available — system package installations will be skipped"
    fi
fi

# ── Network ──────────────────────────────────────────────────────────────────
if curl -fsSL --connect-timeout 5 https://github.com -o /dev/null 2>/dev/null; then
    ok "Network: github.com reachable"
else
    warn "Network: cannot reach github.com — plugin and binary downloads may fail"
    warn "Check your internet connection or proxy settings before continuing"
fi

# ── Homebrew (macOS) ─────────────────────────────────────────────────────────
if [[ $OS == "macos" && $HAS_BREW -eq 0 ]]; then
    warn "Homebrew not found — it is the recommended package manager for macOS"
    if ask "Install Homebrew now? (strongly recommended — required for system tools)"; then
        info "This may take a few minutes and will prompt for your password..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
            die "Homebrew installation failed. Install manually: https://brew.sh"
        # Source brew for Apple Silicon and Intel paths
        for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [[ -x "$brew_path" ]] && eval "$("$brew_path" shellenv)" && break
        done
        command -v brew >/dev/null 2>&1 && HAS_BREW=1 && ok "Homebrew installed"
    else
        warn "Homebrew skipped — system tools (ripgrep, fzf, etc.) will be unavailable"
    fi
fi

# ── curl ─────────────────────────────────────────────────────────────────────
if ! command -v curl >/dev/null 2>&1; then
    warn "curl not found — required to download plugins and tools"
    if pkg_install curl curl curl curl 2>/dev/null; then
        ok "curl installed"
    else
        die "curl is required but could not be installed automatically.
  Ubuntu/Debian:  sudo apt install curl
  Arch:           sudo pacman -S curl
  Fedora:         sudo dnf install curl
  macOS:          brew install curl"
    fi
fi

# ── git ──────────────────────────────────────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
    warn "git not found — required for vim-plug to install plugins"
    if pkg_install git git git git 2>/dev/null; then
        ok "git installed"
    else
        die "git is required but could not be installed automatically.
  Ubuntu/Debian:  sudo apt install git
  Arch:           sudo pacman -S git
  Fedora:         sudo dnf install git
  macOS:          brew install git  (or: xcode-select --install)"
    fi
fi

# ── vim ──────────────────────────────────────────────────────────────────────
[ -f "$SCRIPT_DIR/.vimrc" ] || die ".vimrc not found in $SCRIPT_DIR — is this the chopsticks repo?"

if ! command -v vim >/dev/null 2>&1; then
    warn "vim not found — attempting to install"
    if pkg_install vim vim vim vim 2>/dev/null; then
        ok "vim installed"
    else
        die "vim not found and could not be installed automatically.
  Ubuntu/Debian:  sudo apt install vim
  Arch:           sudo pacman -S vim
  Fedora:         sudo dnf install vim
  macOS:          brew install vim"
    fi
fi

VIM_VERSION=$(vim --version | head -n1)
ok "Found: $VIM_VERSION"

vim --version | grep -q 'Vi IMproved 8\|Vi IMproved 9' || \
    warn "Vim 8.0+ recommended for full async/LSP support — some features may not work"

# ── Node.js ──────────────────────────────────────────────────────────────────
HAS_NODE=0; command -v node >/dev/null 2>&1 && HAS_NODE=1

if [[ $HAS_NODE -eq 0 ]]; then
    warn "Node.js not found — CoC LSP and npm-based formatters will be unavailable"
    info "Without Node.js, the config falls back to vim-lsp (pure VimScript)."
    info ""
    info "Install options:"
    info "  nvm (recommended): curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash"
    info "  macOS:             brew install node"
    info "  Ubuntu/Debian:     curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    info "                     sudo apt-get install -y nodejs"
    info "  Arch:              sudo pacman -S nodejs npm"
    info ""
    if ask "Install Node.js via nvm now? (recommended — manages multiple Node versions)"; then
        info "Fetching latest nvm release..."
        NVM_VER=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
                  | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || NVM_VER="v0.40.1"
        [[ -z "$NVM_VER" ]] && NVM_VER="v0.40.1"
        info "Installing nvm $NVM_VER + Node.js LTS..."
        if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh" | bash >/dev/null 2>&1; then
            export NVM_DIR="$HOME/.nvm"
            # shellcheck disable=SC1091
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            if command -v nvm >/dev/null 2>&1; then
                nvm install --lts >/dev/null 2>&1 && nvm use --lts >/dev/null 2>&1 || true
                command -v node >/dev/null 2>&1 && HAS_NODE=1 && ok "Node.js $(node --version) installed via nvm"
            fi
        fi
        if [[ $HAS_NODE -eq 0 ]]; then
            warn "nvm install failed — CoC and npm tools will be skipped"
            warn "After manually installing Node.js, re-run: ./install.sh"
        fi
    else
        skip "Node.js — config will use vim-lsp fallback (no Node.js required)"
    fi
else
    ok "Node.js $(node --version) found"
fi

# ── Python3 ──────────────────────────────────────────────────────────────────
HAS_PYTHON=0; command -v python3 >/dev/null 2>&1 && HAS_PYTHON=1
HAS_PIP=0;    command -v pip3   >/dev/null 2>&1 && HAS_PIP=1

if [[ $HAS_PYTHON -eq 0 ]]; then
    warn "python3 not found — Python formatters/linters will be unavailable"
    if ask "Install Python 3?"; then
        if pkg_install python3 python3 python3 python3 2>/dev/null; then
            command -v python3 >/dev/null 2>&1 && HAS_PYTHON=1 && ok "Python3 installed"
        else
            warn "Python3 install failed — Python tools will be skipped"
        fi
    else
        skip "Python3"
    fi
fi

# Bootstrap pip3 when python3 exists but pip3 is absent (common on Ubuntu minimal)
if [[ $HAS_PYTHON -eq 1 && $HAS_PIP -eq 0 ]]; then
    warn "python3 found but pip3 missing — attempting bootstrap"
    if python3 -m ensurepip --upgrade >/dev/null 2>&1 || \
       pkg_install python3-pip python3-pip python-pip python3-pip >/dev/null 2>&1; then
        command -v pip3 >/dev/null 2>&1 && HAS_PIP=1 && ok "pip3 bootstrapped"
    else
        warn "pip3 bootstrap failed — Python tools will be skipped"
    fi
fi

[[ $HAS_PIP    -eq 1 ]] && ok "Python/pip3 found"
[[ $HAS_PYTHON -eq 1 && $HAS_PIP -eq 0 ]] && warn "pip3 not available — Python tools will be skipped"

# ── Go ───────────────────────────────────────────────────────────────────────
HAS_GO=0; command -v go >/dev/null 2>&1 && HAS_GO=1
[[ $HAS_GO -eq 1 ]] && ok "Go $(go version | awk '{print $3}') found"
[[ $HAS_GO -eq 0 ]] && warn "Go not found — Go tools will be skipped (see https://go.dev/dl/)"

# ============================================================================
# 2. Symlinks
# ============================================================================

step "Setting up symlinks"

if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing ~/.vimrc → ~/.vimrc.backup.$TS"
    mv "$HOME/.vimrc" "$HOME/.vimrc.backup.$TS"
fi
ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
# Verify symlink
[[ -L "$HOME/.vimrc" ]] && ok "~/.vimrc → $SCRIPT_DIR/.vimrc" || die "Failed to create ~/.vimrc symlink"

mkdir -p "$HOME/.vim"
COC_CFG="$HOME/.vim/coc-settings.json"
if [ -f "$COC_CFG" ] && [ ! -L "$COC_CFG" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing coc-settings.json → ~/.vim/coc-settings.json.backup.$TS"
    mv "$COC_CFG" "$COC_CFG.backup.$TS"
fi
ln -sf "$SCRIPT_DIR/coc-settings.json" "$COC_CFG"
[[ -L "$COC_CFG" ]] && ok "~/.vim/coc-settings.json → $SCRIPT_DIR/coc-settings.json" || warn "coc-settings.json symlink failed (non-fatal)"

# ============================================================================
# 3. vim-plug + Plugins
# ============================================================================

step "Installing vim-plug"

VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG" ]; then
    mkdir -p "$HOME/.vim/autoload"
    if safe_download "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" "$VIM_PLUG"; then
        ok "vim-plug downloaded"
    else
        # Fallback: git clone
        warn "curl download failed — trying git clone fallback"
        if git clone --depth=1 https://github.com/junegunn/vim-plug.git /tmp/vim-plug-src 2>/dev/null; then
            cp /tmp/vim-plug-src/plug.vim "$VIM_PLUG" && rm -rf /tmp/vim-plug-src
            ok "vim-plug installed (via git)"
        else
            die "vim-plug installation failed. Check your network connection and try again."
        fi
    fi
    [[ -s "$VIM_PLUG" ]] || die "vim-plug file is empty after download — aborting"
else
    ok "vim-plug already present"
fi

step "Installing Vim plugins"
info "(Vim will open fullscreen to install plugins — screen may go dark for 10-30s, this is normal)"
# </dev/null prevents Vim from reading stdin in non-interactive/piped environments
if ! vim +PlugInstall +qall </dev/null; then
    warn "vim +PlugInstall exited non-zero — plugins may be partially installed"
    warn "Run :PlugInstall manually inside Vim if something looks wrong"
else
    ok "Plugins installed"
fi

# ============================================================================
# 4. System Tools
# ============================================================================

step "System tools"

if [[ $OS == "macos" && $HAS_BREW -eq 0 ]]; then
    skip "system tools (Homebrew not available — install brew first, then re-run)"
    SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
elif ask "Install system tools (ripgrep, fzf, ctags, shellcheck, hadolint, marksman)?"; then

    install_sys() {
        local name="$1" check="$2"; shift 2
        if command -v "$check" >/dev/null 2>&1; then
            ok "$name (already installed)"
            return
        fi
        local installed=0
        for cmd in "$@"; do
            if eval "$cmd" >/dev/null 2>&1; then installed=1; break; fi
        done
        if [[ $installed -eq 1 ]]; then
            ok "$name"; INSTALLED+=("$name")
        else
            fail "$name — could not install automatically (install manually)"
            FAILED+=("$name")
        fi
    }

    if [[ $OS == "macos" ]]; then
        install_sys "ripgrep"         rg         "brew install ripgrep"
        install_sys "fzf"             fzf        "brew install fzf"
        install_sys "universal-ctags" ctags      "brew install universal-ctags"
        install_sys "shellcheck"      shellcheck "brew install shellcheck"
        install_sys "hadolint"        hadolint   "brew install hadolint"
        install_sys "marksman"        marksman   "brew install marksman"

    elif [[ $HAS_APT -eq 1 ]]; then
        if [[ $HAS_SUDO -eq 0 ]]; then
            warn "No sudo — skipping apt system tools"
            SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
        else
            sudo apt-get update -qq
            install_sys "ripgrep"         rg         "sudo apt-get install -y ripgrep"
            install_sys "fzf"             fzf        "sudo apt-get install -y fzf"
            install_sys "universal-ctags" ctags      "sudo apt-get install -y universal-ctags"
            install_sys "shellcheck"      shellcheck "sudo apt-get install -y shellcheck"

            # hadolint: no apt package — download binary from GitHub releases
            if command -v hadolint >/dev/null 2>&1; then
                ok "hadolint (already installed)"
            else
                HARCH=$(arch_github)
                HVER=$(curl -fsSL https://api.github.com/repos/hadolint/hadolint/releases/latest \
                       | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || HVER=""
                if [[ -n "$HVER" ]] && safe_download \
                    "https://github.com/hadolint/hadolint/releases/download/${HVER}/hadolint-Linux-${HARCH}" \
                    /tmp/chopsticks-hadolint; then
                    chmod +x /tmp/chopsticks-hadolint && sudo mv /tmp/chopsticks-hadolint /usr/local/bin/hadolint
                    ok "hadolint"; INSTALLED+=("hadolint")
                else
                    fail "hadolint — download failed (install manually: https://github.com/hadolint/hadolint/releases)"
                    FAILED+=("hadolint")
                fi
            fi

            # marksman: no apt package — download binary from GitHub releases
            if command -v marksman >/dev/null 2>&1; then
                ok "marksman (already installed)"
            else
                MARCH=$(arch_linux_x64)
                MVER=$(curl -fsSL https://api.github.com/repos/artempyanykh/marksman/releases/latest \
                       | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || MVER=""
                if [[ -n "$MVER" ]] && safe_download \
                    "https://github.com/artempyanykh/marksman/releases/download/${MVER}/marksman-linux-${MARCH}" \
                    /tmp/chopsticks-marksman; then
                    chmod +x /tmp/chopsticks-marksman && sudo mv /tmp/chopsticks-marksman /usr/local/bin/marksman
                    ok "marksman"; INSTALLED+=("marksman")
                else
                    fail "marksman — download failed (install manually: https://github.com/artempyanykh/marksman/releases)"
                    FAILED+=("marksman")
                fi
            fi
        fi

    elif [[ $HAS_PACMAN -eq 1 ]]; then
        if [[ $HAS_SUDO -eq 0 ]]; then
            warn "No sudo — skipping pacman system tools"
            SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
        else
            install_sys "ripgrep"         rg         "sudo pacman -S --noconfirm ripgrep"
            install_sys "fzf"             fzf        "sudo pacman -S --noconfirm fzf"
            install_sys "universal-ctags" ctags      "sudo pacman -S --noconfirm ctags"
            install_sys "shellcheck"      shellcheck "sudo pacman -S --noconfirm shellcheck"
            install_sys "hadolint"        hadolint   "sudo pacman -S --noconfirm hadolint"
            install_sys "marksman"        marksman   "sudo pacman -S --noconfirm marksman"
        fi

    elif [[ $HAS_DNF -eq 1 ]]; then
        if [[ $HAS_SUDO -eq 0 ]]; then
            warn "No sudo — skipping dnf system tools"
            SKIPPED+=("ripgrep" "fzf" "shellcheck" "ctags" "hadolint" "marksman")
        else
            install_sys "ripgrep"         rg         "sudo dnf install -y ripgrep"
            install_sys "fzf"             fzf        "sudo dnf install -y fzf"
            install_sys "shellcheck"      shellcheck "sudo dnf install -y ShellCheck"
            skip "universal-ctags — install manually: sudo dnf install ctags"
            SKIPPED+=("ctags")
            skip "hadolint — install manually: https://github.com/hadolint/hadolint/releases"
            SKIPPED+=("hadolint")
            skip "marksman — install manually: https://github.com/artempyanykh/marksman/releases"
            SKIPPED+=("marksman")
        fi

    else
        warn "Unknown distro — skipping system tools (install manually)"
        SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
    fi

else
    skip "system tools"
    SKIPPED+=("ripgrep" "fzf" "ctags" "shellcheck" "hadolint" "marksman")
fi

# ============================================================================
# 5. npm tools
# ============================================================================

step "npm tools (formatters + linters)"

if [[ $HAS_NODE -eq 1 ]]; then
    if ask "Install npm tools (prettier, markdownlint-cli, stylelint, eslint, typescript)?"; then
        npm_install() {
            local pkg="$1"; local check="${2:-$1}"
            if command -v "$check" >/dev/null 2>&1; then
                ok "$pkg (already installed)"; return
            fi
            if npm install -g "$pkg" >/dev/null 2>&1; then
                ok "$pkg"; INSTALLED+=("$pkg")
            else
                fail "$pkg"; FAILED+=("$pkg")
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
# 6. Python tools
# ============================================================================

step "Python tools (formatters + linters)"

if [[ $HAS_PIP -eq 1 ]]; then
    if ask "Install Python tools (black, isort, flake8, pylint, yamllint, sqlfluff)?"; then
        pip_install() {
            local pkg="$1"; local check="${2:-$1}"
            if command -v "$check" >/dev/null 2>&1; then
                ok "$pkg (already installed)"; return
            fi
            if pip3 install --quiet "$pkg" 2>/dev/null || \
               pip3 install --quiet --break-system-packages "$pkg" 2>/dev/null; then
                ok "$pkg"; INSTALLED+=("$pkg")
            else
                fail "$pkg"; FAILED+=("$pkg")
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
# 7. Go tools
# ============================================================================

step "Go tools"

if [[ $HAS_GO -eq 1 ]]; then
    if ask "Install Go tools (gopls, goimports, staticcheck)?"; then
        GOBIN="$(go env GOPATH)/bin"
        export PATH="$PATH:$GOBIN"

        go_install() {
            local name="$1" pkg="$2" check="$3"
            if command -v "$check" >/dev/null 2>&1 || [[ -x "$GOBIN/$check" ]]; then
                ok "$name (already installed)"; return
            fi
            if go install "$pkg" >/dev/null 2>&1; then
                ok "$name"; INSTALLED+=("$name")
            else
                fail "$name"; FAILED+=("$name")
            fi
        }
        go_install gopls       "golang.org/x/tools/gopls@latest"                gopls
        go_install goimports   "golang.org/x/tools/cmd/goimports@latest"        goimports
        go_install staticcheck "honnef.co/go/tools/cmd/staticcheck@latest"      staticcheck

        echo "$PATH" | grep -q "$GOBIN" || \
            warn "Add Go binaries to PATH: export PATH=\"\$PATH:$GOBIN\""
    else
        skip "Go tools"
        SKIPPED+=("gopls" "goimports" "staticcheck")
    fi
else
    skip "Go tools (go not installed — see https://go.dev/dl/)"
    SKIPPED+=("gopls" "goimports" "staticcheck")
fi

# ============================================================================
# 8. tmux: vim-tmux-navigator integration
# ============================================================================

step "tmux: vim-tmux-navigator integration"

if command -v tmux >/dev/null 2>&1; then
    TMUX_CONF="$HOME/.tmux.conf"
    if grep -q 'vim-tmux-navigator' "$TMUX_CONF" 2>/dev/null; then
        ok "vim-tmux-navigator bindings already present in ~/.tmux.conf"
    elif ask "Append vim-tmux-navigator bindings to ~/.tmux.conf (enables seamless Ctrl+h/j/k/l across vim and tmux)?"; then
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
else
    skip "tmux not found — skipping navigator config"
    SKIPPED+=("tmux-navigator-config")
fi

# ============================================================================
# 9. CoC language server extensions
# ============================================================================

step "CoC language server extensions"

if [[ $HAS_NODE -eq 1 ]]; then
    if ask "Install CoC language servers (LSP for all configured languages)?"; then
        info "(Downloading CoC extensions via npm — screen may go dark for 1-3 minutes, this is normal)"
        # Note: coc-marksman doesn't exist on npm — markdown LSP is handled via coc-settings.json
        vim +'CocInstall -sync coc-json coc-tsserver coc-pyright coc-sh coc-html coc-css coc-yaml coc-go coc-rust-analyzer coc-sql' +qall </dev/null
        ok "CoC language servers installed"
    else
        skip "CoC language servers"
        info "Install later with :CocInstall <name> inside Vim"
    fi
else
    warn "Node.js not found — using vim-lsp fallback (run :LspInstallServer inside Vim for each language)"
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
    echo ""
    echo "  To debug failures: ./install.sh 2>&1 | tee /tmp/chopsticks-install.log"
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
