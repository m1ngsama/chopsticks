#!/usr/bin/env bash
# install.sh - chopsticks vim configuration installer
# Usage: cd /path/to/chopsticks && ./install.sh [--yes] [--help]
#
# --yes   non-interactive: use default component selections
# --help  show this help and exit

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_YES=0
for arg in "$@"; do
    case "$arg" in
        --yes)  AUTO_YES=1 ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --yes    Non-interactive mode: use default component selections"
            echo "  --help   Show this help and exit"
            echo ""
            echo "Supported platforms: macOS (brew), Debian/Ubuntu (apt), Arch (pacman), Fedora (dnf)"
            exit 0 ;;
    esac
done

# ── Colours (respect NO_COLOR and non-TTY) ───────────────────────────────────
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    CYAN='\033[0;36m'
    DIM='\033[2m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BOLD='' CYAN='' DIM='' NC=''
fi

ok()   { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }
skip() { echo -e "${CYAN}[--]${NC}  $1"; }
fail() { echo -e "${RED}[ERR]${NC} $1"; }
die()  { echo -e "${RED}[FATAL]${NC} $1" >&2
         echo "  Retry with: ./install.sh 2>&1 | tee /tmp/chopsticks-install.log" >&2
         echo "  Report issues: https://github.com/m1ngsama/chopsticks/issues" >&2
         exit 1; }
step() { echo -e "\n${BOLD}==> $1${NC}"; }
info() { echo "     $1"; }

INSTALLED=()
SKIPPED=()
FAILED=()

# Ask yes/no; reads from /dev/tty so it works under: curl | bash
ask() {
    [[ $AUTO_YES -eq 1 ]] && return 0
    if [[ -t 0 ]]; then
        read -r -p "$1 [y/N] " reply
    elif { true </dev/tty; } 2>/dev/null; then
        read -r -p "$1 [y/N] " reply </dev/tty
    else
        echo "$1 [y/N] N"
        return 1
    fi
    [[ "$reply" =~ ^[Yy]$ ]]
}

# ── Error trap ────────────────────────────────────────────────────────────────
on_error() {
    echo -e "\n${RED}[FATAL]${NC} Command '${BASH_COMMAND}' failed at line ${BASH_LINENO[0]}." >&2
    echo "  To get a full debug log:" >&2
    echo "    ./install.sh 2>&1 | tee /tmp/chopsticks-install.log" >&2
    echo "  Report issues: https://github.com/m1ngsama/chopsticks/issues" >&2
}
trap on_error ERR
_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-XXXXXX")
trap 'rm -rf "$_TMPDIR" 2>/dev/null' EXIT

# ── Safe download helper ──────────────────────────────────────────────────────
safe_download() {
    local url="$1" dest="$2"
    curl -fsSL --connect-timeout 15 --retry 3 "$url" -o "$dest" 2>/dev/null || return 1
    [[ -s "$dest" ]] || { rm -f "$dest"; return 1; }
    if head -c 200 "$dest" 2>/dev/null | grep -qi "<!DOCTYPE\|<html"; then
        rm -f "$dest"; return 1
    fi
    return 0
}

# ── Cross-platform package install helper ─────────────────────────────────────
pkg_install() {
    local brew_pkg="${1:-}" apt_pkg="${2:-}" pac_pkg="${3:-}" dnf_pkg="${4:-}"
    if   [[ $OS == "macos" && $HAS_BREW -eq 1 && -n "$brew_pkg" ]]; then brew install "$brew_pkg" >/dev/null 2>&1
    elif [[ $HAS_APT    -eq 1 && -n "$apt_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo apt-get install -y "$apt_pkg" >/dev/null 2>&1
    elif [[ $HAS_PACMAN -eq 1 && -n "$pac_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo pacman -S --noconfirm "$pac_pkg" >/dev/null 2>&1
    elif [[ $HAS_DNF    -eq 1 && -n "$dnf_pkg"  && $HAS_SUDO -eq 1 ]]; then sudo dnf install -y "$dnf_pkg" >/dev/null 2>&1
    elif [[ $HAS_BREW   -eq 1 && -n "$brew_pkg" ]]; then brew install "$brew_pkg" >/dev/null 2>&1
    else return 1
    fi
}

# ── CPU architecture helpers ──────────────────────────────────────────────────
arch_github() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64" ;;
        aarch64|arm64) echo "arm64"  ;;
        armv7l)        echo "armv7"  ;;
        *)             uname -m     ;;
    esac
}
arch_linux_x64() {
    case "$(uname -m)" in
        x86_64)        echo "x64"   ;;
        aarch64|arm64) echo "arm64" ;;
        *)             uname -m    ;;
    esac
}

# ============================================================================
# Checkbox selection menu
# ============================================================================
#
# Usage:
#   _menu_checkbox "Title" "label|description|default(0/1)" ...
#
# Result: global MENU_SEL array — MENU_SEL[i]=1 means item i was selected.
# Globals _MENU_LABELS / _MENU_DESCS remain populated after return.
#
# In --yes mode or non-TTY: uses defaults silently.
# Controls: ↑↓ navigate · Space toggle · a all · n none · Enter confirm
# ─────────────────────────────────────────────────────────────────────────────

_MENU_LABELS=()
_MENU_DESCS=()
_MENU_SELS=()
_MENU_N=0
_MENU_TITLE=""
_MENU_CUR=0
MENU_SEL=()

_menu_draw() {
    local i mark
    printf "\033[2K${BOLD}%s${NC}\n" "$_MENU_TITLE"
    printf "\033[2K  %b%b\n" "$DIM" "↑/↓ move   Space toggle   a all   n none   Enter confirm${NC}"
    printf "\033[2K\n"
    for ((i = 0; i < _MENU_N; i++)); do
        if [[ ${_MENU_SELS[$i]} -eq 1 ]]; then
            mark="${GREEN}✓${NC}"
        else
            mark=" "
        fi
        if [[ $i -eq $_MENU_CUR ]]; then
            printf "\033[2K  ${BOLD}▶ [%b] %s${NC}\n" "$mark" "${_MENU_LABELS[$i]}"
        else
            printf "\033[2K    [%b] %s\n" "$mark" "${_MENU_LABELS[$i]}"
        fi
        printf "\033[2K      ${CYAN}%s${NC}\n" "${_MENU_DESCS[$i]}"
    done
}

_menu_checkbox() {
    _MENU_TITLE="$1"; shift
    _MENU_LABELS=(); _MENU_DESCS=(); _MENU_SELS=()
    _MENU_N=0; _MENU_CUR=0

    while [[ $# -gt 0 ]]; do
        IFS='|' read -r \
            "_MENU_LABELS[$_MENU_N]" \
            "_MENU_DESCS[$_MENU_N]"  \
            "_MENU_SELS[$_MENU_N]"  <<< "$1"
        shift; : $(( _MENU_N++ ))
    done

    # Non-interactive or --yes: use defaults, no UI
    if [[ $AUTO_YES -eq 1 ]] || ! { true </dev/tty; } 2>/dev/null; then
        MENU_SEL=("${_MENU_SELS[@]}")
        [[ $AUTO_YES -eq 1 ]] && info "(--yes mode: using all defaults)"
        return
    fi

    # Lines printed per _menu_draw call: 3 header + 2 per item
    local _lines=$(( 3 + 2 * _MENU_N ))
    local _key _esc _i

    tput civis 2>/dev/null   # hide cursor
    local _first=1

    while true; do
        if [[ $_first -eq 0 ]]; then
            tput cuu "$_lines" 2>/dev/null   # move back to top of menu
        fi
        _menu_draw
        _first=0

        IFS= read -r -s -n1 _key </dev/tty
        if [[ $_key == $'\x1b' ]]; then
            IFS= read -r -s -n2 _esc </dev/tty
            case "$_esc" in
                '[A') ((_MENU_CUR > 0))            && ((_MENU_CUR--)) ;;
                '[B') ((_MENU_CUR < _MENU_N - 1)) && ((_MENU_CUR++)) ;;
            esac
        elif [[ $_key == ' ' ]]; then
            _MENU_SELS[_MENU_CUR]=$(( 1 - _MENU_SELS[_MENU_CUR] ))
        elif [[ $_key == 'a' || $_key == 'A' ]]; then
            for ((_i = 0; _i < _MENU_N; _i++)); do _MENU_SELS[_i]=1; done
        elif [[ $_key == 'n' || $_key == 'N' ]]; then
            for ((_i = 0; _i < _MENU_N; _i++)); do _MENU_SELS[_i]=0; done
        elif [[ -z $_key ]]; then   # Enter
            break
        fi
    done

    tput cnorm 2>/dev/null   # restore cursor
    echo ""
    MENU_SEL=("${_MENU_SELS[@]}")
}

# Helper: was menu item at index $1 selected?
_selected() { [[ ${MENU_SEL[${1:-999}]:-0} -eq 1 ]]; }

echo -e "${BOLD}chopsticks — Vim Configuration Installer${NC}"
echo "----------------------------------------"

# ============================================================================
# 1. OS + Package Manager Detection
# ============================================================================

step "Detecting environment"

OS="unknown"
if   [[ "$OSTYPE" == darwin* ]];         then OS="macos"
elif [[ -f /etc/debian_version ]];       then OS="debian"
elif [[ -f /etc/fedora-release ]];       then OS="fedora"
elif [[ -f /etc/arch-release ]];         then OS="arch"
fi
ok "OS: $OS"

HAS_BREW=0;   command -v brew   >/dev/null 2>&1 && HAS_BREW=1
HAS_APT=0;    command -v apt    >/dev/null 2>&1 && HAS_APT=1
HAS_DNF=0;    command -v dnf    >/dev/null 2>&1 && HAS_DNF=1
HAS_PACMAN=0; command -v pacman >/dev/null 2>&1 && HAS_PACMAN=1

# sudo
HAS_SUDO=0
if [[ $OS == "macos" ]]; then
    HAS_SUDO=1   # brew handles its own privilege escalation
elif sudo -n true 2>/dev/null; then
    HAS_SUDO=1; ok "sudo: available (passwordless)"
elif [[ $AUTO_YES -eq 1 ]]; then
    warn "sudo requires a password but running non-interactively (--yes)"
    warn "System package installations will be skipped"
else
    warn "Some steps require sudo. Authenticating now..."
    if sudo true; then
        HAS_SUDO=1; ok "sudo: authenticated"
    else
        warn "sudo not available — system package installations will be skipped"
    fi
fi

# Network
if curl -fsSL --connect-timeout 5 https://github.com -o /dev/null 2>/dev/null; then
    ok "Network: github.com reachable"
else
    warn "Network: cannot reach github.com — plugin and binary downloads may fail"
fi

# Homebrew (macOS)
if [[ $OS == "macos" && $HAS_BREW -eq 0 ]]; then
    warn "Homebrew not found — it is the recommended package manager for macOS"
    if ask "Install Homebrew now? (strongly recommended — required for system tools)"; then
        info "This may take a few minutes and will prompt for your password..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
            die "Homebrew installation failed. Install manually: https://brew.sh"
        for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [[ -x "$brew_path" ]] && eval "$("$brew_path" shellenv)" && break
        done
        command -v brew >/dev/null 2>&1 && HAS_BREW=1 && ok "Homebrew installed"
    else
        warn "Homebrew skipped — system tools (ripgrep, fzf, etc.) will be unavailable"
    fi
fi

# curl
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

# git
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

# vim
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
ok "Found: $(vim --version | head -n1)"
vim --version | grep -q 'Vi IMproved 8\|Vi IMproved 9' || \
    warn "Vim 8.0+ recommended for full async/LSP support — some features may not work"

# Node.js (optional — vim-lsp needs no Node.js; only npm formatters do)
HAS_NODE=0; command -v node >/dev/null 2>&1 && HAS_NODE=1
if [[ $HAS_NODE -eq 1 ]]; then
    ok "Node.js $(node --version) found"
else
    warn "Node.js not found — npm formatters (prettier, eslint) will be unavailable"
    warn "LSP still works without Node.js. To add formatters later: brew install node"
fi

# Python3 / pip3
HAS_PYTHON=0; command -v python3 >/dev/null 2>&1 && HAS_PYTHON=1
HAS_PIP=0;    command -v pip3   >/dev/null 2>&1 && HAS_PIP=1
if [[ $HAS_PYTHON -eq 0 ]]; then
    warn "python3 not found — Python formatters/linters will be unavailable"
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

# Go
HAS_GO=0; command -v go >/dev/null 2>&1 && HAS_GO=1
[[ $HAS_GO -eq 1 ]] && ok "Go $(go version | awk '{print $3}') found"
[[ $HAS_GO -eq 0 ]] && warn "Go not found — Go tools will be skipped (see https://go.dev/dl/)"

# ============================================================================
# 2. Symlinks
# ============================================================================

step "Setting up symlinks"

if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    warn "Backing up existing ~/.vimrc → $HOME/.vimrc.backup.$TS"
    mv "$HOME/.vimrc" "$HOME/.vimrc.backup.$TS"
fi
ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
if [[ -L "$HOME/.vimrc" ]]; then
    ok "$HOME/.vimrc → $SCRIPT_DIR/.vimrc"
else
    die "Failed to create ~/.vimrc symlink"
fi

mkdir -p "$HOME/.vim"

# ============================================================================
# 3. vim-plug + Plugins
# ============================================================================

step "Installing vim-plug"

VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_PLUG" ]; then
    mkdir -p "$HOME/.vim/autoload"
    if safe_download \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
        "$VIM_PLUG"; then
        ok "vim-plug downloaded"
    else
        warn "curl download failed — trying git clone fallback"
        if git clone --depth=1 https://github.com/junegunn/vim-plug.git \
               /tmp/vim-plug-src 2>/dev/null; then
            cp /tmp/vim-plug-src/plug.vim "$VIM_PLUG"
            rm -rf /tmp/vim-plug-src
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

_vim_run() {
    if { true </dev/tty; } 2>/dev/null; then
        # Interactive terminal: vim uses alternate screen; user sees progress
        vim "$@" </dev/tty
    else
        # No TTY (SSH batch, CI): do NOT redirect stdin (causes "Error reading input" exit)
        # or stdout (breaks async job callbacks — partial install).
        # Redirect only stderr; escape sequences appear on stdout but installation succeeds.
        vim --not-a-term "$@" 2>/dev/null
    fi
}
if [[ -d "$HOME/.vim/plugged" ]] && [[ -n "$(find "$HOME/.vim/plugged" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    warn "PlugClean: removing plugins not listed in .vimrc from ~/.vim/plugged"
fi
_vim_run +'PlugClean!' +qall || true  # remove plugins no longer in vimrc; ignore exit code (none expected)
_vim_run +'PlugInstall --sync' +qall || true  # fzf post-install hook may exit non-zero; harmless

_plug_count=$(find "$HOME/.vim/plugged" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
if [[ $_plug_count -eq 0 ]]; then
    die "Plugin installation failed — ~/.vim/plugged is empty. Check network and retry."
fi
ok "Plugins installed ($_plug_count)"

# ============================================================================
# 4. Module Selection
# ============================================================================

step "Select optional components"

_ITEMS=()
_idx=0

# Index map (-1 = not in menu / unavailable)
_I_RIPGREP=-1; _I_FZF=-1; _I_CTAGS=-1; _I_SHELLCHECK=-1
_I_HADOLINT=-1; _I_MARKSMAN=-1
_I_NPM=-1; _I_PYTHON=-1; _I_GO=-1; _I_TMUX=-1

# Is any package manager available?
HAS_PKG_MGR=0
if [[ $HAS_BREW -eq 1 ]] || \
   { [[ $HAS_APT -eq 1 || $HAS_PACMAN -eq 1 || $HAS_DNF -eq 1 ]] && [[ $HAS_SUDO -eq 1 ]]; }; then
    HAS_PKG_MGR=1
fi

# ── System tools ─────────────────────────────────────────────────────────────
if [[ $HAS_PKG_MGR -eq 1 ]]; then
    _I_RIPGREP=$_idx
    _ITEMS+=("ripgrep|,rg / ,rG project-wide search · powers Ctrl+p preview|1")
    : $(( _idx++ ))

    _I_FZF=$_idx
    _ITEMS+=("fzf|Ctrl+p fuzzy file search · ,b buffers · ,rt tag search|1")
    : $(( _idx++ ))

    _I_CTAGS=$_idx
    _ITEMS+=("universal-ctags|Optional symbol index for ,rt tag jumps|0")
    : $(( _idx++ ))

    _I_SHELLCHECK=$_idx
    _ITEMS+=("shellcheck|Optional shell script static analysis via ALE|0")
    : $(( _idx++ ))

    _I_HADOLINT=$_idx
    _ITEMS+=("hadolint|Optional Dockerfile linting via ALE|0")
    : $(( _idx++ ))

    _I_MARKSMAN=$_idx
    _ITEMS+=("marksman|Optional Markdown LSP — enable with g:chopsticks_markdown_lsp|0")
    : $(( _idx++ ))
else
    warn "No package manager available — system tools skipped"
fi

# ── npm tools ────────────────────────────────────────────────────────────────
if [[ $HAS_NODE -eq 1 ]]; then
    _I_NPM=$_idx
    _ITEMS+=("npm formatter suite|Optional prettier / eslint / markdownlint / stylelint / tsc|0")
    : $(( _idx++ ))
fi

# ── Python tools ─────────────────────────────────────────────────────────────
if [[ $HAS_PIP -eq 1 ]]; then
    _I_PYTHON=$_idx
    _ITEMS+=("Python tool suite|Optional black / isort / flake8 / pylint / yamllint / sqlfluff|0")
    : $(( _idx++ ))
fi

# ── Go tools ─────────────────────────────────────────────────────────────────
if [[ $HAS_GO -eq 1 ]]; then
    _I_GO=$_idx
    _ITEMS+=("Go tool suite|Optional gopls / goimports / staticcheck|0")
    : $(( _idx++ ))
fi

# ── tmux ─────────────────────────────────────────────────────────────────────
if command -v tmux >/dev/null 2>&1; then
    if ! grep -q 'vim-tmux-navigator' "$HOME/.tmux.conf" 2>/dev/null; then
        _I_TMUX=$_idx
        _ITEMS+=("tmux integration|Optional Ctrl+h/j/k/l navigation between vim and tmux panes|0")
        : $(( _idx++ ))
    else
        ok "tmux integration (vim-tmux-navigator already configured)"
    fi
fi

if [[ ${#_ITEMS[@]} -gt 0 ]]; then
    _menu_checkbox "Select components to install:" "${_ITEMS[@]}"
    echo -e "${BOLD}Install plan:${NC}"
    for ((_i = 0; _i < _MENU_N; _i++)); do
        if [[ ${MENU_SEL[$_i]:-0} -eq 1 ]]; then
            echo -e "  ${GREEN}✓${NC} ${_MENU_LABELS[$_i]}"
        else
            echo -e "  ${DIM}—${NC} ${_MENU_LABELS[$_i]}"
        fi
    done
    echo ""
else
    warn "No optional components available for this environment"
    MENU_SEL=()
fi

# ============================================================================
# 5. System Tools
# ============================================================================

step "System tools"

if [[ $HAS_PKG_MGR -eq 0 ]]; then
    skip "system tools (no package manager available)"
    SKIPPED+=("ripgrep" "fzf" "universal-ctags" "shellcheck" "hadolint" "marksman")
else

# _do_sys <name> <cmd_check> <idx> <brew_pkg> <apt_pkg> <pac_pkg> [dnf_pkg]
_do_sys() {
    local name="$1" check="$2" idx="$3"
    local brew_p="${4:-}" apt_p="${5:-}" pac_p="${6:-}" dnf_p="${7:-}"

    if [[ $idx -lt 0 ]] || ! _selected "$idx"; then
        skip "$name"; SKIPPED+=("$name"); return
    fi
    if command -v "$check" >/dev/null 2>&1; then
        ok "$name (already installed)"; return
    fi
    if pkg_install "$brew_p" "$apt_p" "$pac_p" "$dnf_p"; then
        ok "$name"; INSTALLED+=("$name")
    else
        fail "$name — could not install automatically (install manually)"
        FAILED+=("$name")
    fi
}

# _do_binary_apt: for tools with no apt/dnf package — download binary from GitHub
_do_binary_apt() {
    local name="$1" check="$2" idx="$3" url="$4" tmp="$5"
    if [[ $idx -lt 0 ]] || ! _selected "$idx"; then
        skip "$name"; SKIPPED+=("$name"); return
    fi
    if command -v "$check" >/dev/null 2>&1; then
        ok "$name (already installed)"; return
    fi
    if [[ $HAS_SUDO -ne 1 ]]; then
        fail "$name — sudo not available, cannot install to /usr/local/bin"
        FAILED+=("$name"); return
    fi
    if safe_download "$url" "$tmp"; then
        chmod +x "$tmp" && sudo mv "$tmp" /usr/local/bin/"$check"
        ok "$name"; INSTALLED+=("$name")
    else
        fail "$name — binary download failed (install manually)"
        FAILED+=("$name")
    fi
}

if [[ $OS == "macos" ]]; then
    _do_sys "ripgrep"         rg         "$_I_RIPGREP"    ripgrep          "" "" ""
    _do_sys "fzf"             fzf        "$_I_FZF"        fzf              "" "" ""
    _do_sys "universal-ctags" ctags      "$_I_CTAGS"      universal-ctags  "" "" ""
    _do_sys "shellcheck"      shellcheck "$_I_SHELLCHECK" shellcheck       "" "" ""
    _do_sys "hadolint"        hadolint   "$_I_HADOLINT"   hadolint         "" "" ""
    _do_sys "marksman"        marksman   "$_I_MARKSMAN"   marksman         "" "" ""

elif [[ $HAS_APT -eq 1 ]]; then
    [[ $HAS_SUDO -eq 1 ]] && sudo apt-get update -qq
    _do_sys "ripgrep"         rg         "$_I_RIPGREP"    "" ripgrep         "" ""
    _do_sys "fzf"             fzf        "$_I_FZF"        "" fzf             "" ""
    _do_sys "universal-ctags" ctags      "$_I_CTAGS"      "" universal-ctags "" ""
    _do_sys "shellcheck"      shellcheck "$_I_SHELLCHECK" "" shellcheck      "" ""

    # hadolint: no apt package — binary from GitHub releases
    if [[ $_I_HADOLINT -ge 0 ]] && _selected "$_I_HADOLINT"; then
        HARCH=$(arch_github)
        HVER=$(curl -fsSL https://api.github.com/repos/hadolint/hadolint/releases/latest \
               | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || HVER=""
        if [[ -z "$HVER" ]]; then
            fail "hadolint — could not determine latest release version"
            FAILED+=("hadolint")
        else
            _do_binary_apt "hadolint" hadolint "$_I_HADOLINT" \
                "https://github.com/hadolint/hadolint/releases/download/${HVER}/hadolint-Linux-${HARCH}" \
                "$_TMPDIR/hadolint"
        fi
    else
        skip "hadolint"; SKIPPED+=("hadolint")
    fi

    # marksman: no apt package — binary from GitHub releases
    if [[ $_I_MARKSMAN -ge 0 ]] && _selected "$_I_MARKSMAN"; then
        MARCH=$(arch_linux_x64)
        MVER=$(curl -fsSL https://api.github.com/repos/artempyanykh/marksman/releases/latest \
               | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || MVER=""
        if [[ -z "$MVER" ]]; then
            fail "marksman — could not determine latest release version"
            FAILED+=("marksman")
        else
            _do_binary_apt "marksman" marksman "$_I_MARKSMAN" \
                "https://github.com/artempyanykh/marksman/releases/download/${MVER}/marksman-linux-${MARCH}" \
                "$_TMPDIR/marksman"
        fi
    else
        skip "marksman"; SKIPPED+=("marksman")
    fi

elif [[ $HAS_PACMAN -eq 1 ]]; then
    _do_sys "ripgrep"         rg         "$_I_RIPGREP"    "" "" ripgrep    ""
    _do_sys "fzf"             fzf        "$_I_FZF"        "" "" fzf        ""
    _do_sys "universal-ctags" ctags      "$_I_CTAGS"      "" "" ctags      ""
    _do_sys "shellcheck"      shellcheck "$_I_SHELLCHECK" "" "" shellcheck ""
    _do_sys "hadolint"        hadolint   "$_I_HADOLINT"   "" "" hadolint   ""
    _do_sys "marksman"        marksman   "$_I_MARKSMAN"   "" "" marksman   ""

elif [[ $HAS_DNF -eq 1 ]]; then
    _do_sys "ripgrep"         rg         "$_I_RIPGREP"    "" "" "" ripgrep
    _do_sys "fzf"             fzf        "$_I_FZF"        "" "" "" fzf
    _do_sys "shellcheck"      shellcheck "$_I_SHELLCHECK" "" "" "" ShellCheck
    if [[ $_I_CTAGS -ge 0 ]]; then
        if _selected "$_I_CTAGS"; then
            skip "universal-ctags — Fedora: install manually: sudo dnf install ctags"
        fi
        SKIPPED+=("universal-ctags")
    fi
    if [[ $_I_HADOLINT -ge 0 ]]; then
        if _selected "$_I_HADOLINT"; then
            skip "hadolint — Fedora: install manually: https://github.com/hadolint/hadolint/releases"
        fi
        SKIPPED+=("hadolint")
    fi
    if [[ $_I_MARKSMAN -ge 0 ]]; then
        if _selected "$_I_MARKSMAN"; then
            skip "marksman — Fedora: install manually: https://github.com/artempyanykh/marksman/releases"
        fi
        SKIPPED+=("marksman")
    fi
else
    warn "Unknown distro — skipping system tools (install manually)"
    SKIPPED+=("ripgrep" "fzf" "universal-ctags" "shellcheck" "hadolint" "marksman")
fi

fi  # end HAS_PKG_MGR

# ============================================================================
# 6. npm Tools
# ============================================================================

step "npm tools (formatters + linters)"

if [[ $HAS_NODE -eq 0 ]]; then
    skip "npm tools (Node.js not installed)"
    SKIPPED+=("prettier" "markdownlint-cli" "stylelint" "eslint" "typescript")
elif [[ $_I_NPM -lt 0 ]] || ! _selected "$_I_NPM"; then
    skip "npm formatter suite (skipped by user)"
    SKIPPED+=("prettier" "markdownlint-cli" "stylelint" "eslint" "typescript")
else
    npm_install() {
        local pkg="$1" check="${2:-$1}"
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
fi

# ============================================================================
# 7. Python Tools
# ============================================================================

step "Python tools (formatters + linters)"

if [[ $HAS_PIP -eq 0 ]]; then
    skip "Python tools (pip3 not installed)"
    SKIPPED+=("black" "isort" "flake8" "pylint" "yamllint" "sqlfluff")
elif [[ $_I_PYTHON -lt 0 ]] || ! _selected "$_I_PYTHON"; then
    skip "Python tool suite (skipped by user)"
    SKIPPED+=("black" "isort" "flake8" "pylint" "yamllint" "sqlfluff")
else
    pip_install() {
        local pkg="$1" check="${2:-$1}"
        if command -v "$check" >/dev/null 2>&1; then
            ok "$pkg (already installed)"; return
        fi
        if pip3 install --quiet "$pkg" 2>/dev/null; then
            ok "$pkg"; INSTALLED+=("$pkg")
        elif pip3 install --quiet --break-system-packages "$pkg" 2>/dev/null; then
            warn "$pkg installed with --break-system-packages (consider using a virtualenv)"
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
fi

# ============================================================================
# 8. Go Tools
# ============================================================================

step "Go tools"

if [[ $HAS_GO -eq 0 ]]; then
    skip "Go tools (go not installed — see https://go.dev/dl/)"
    SKIPPED+=("gopls" "goimports" "staticcheck")
elif [[ $_I_GO -lt 0 ]] || ! _selected "$_I_GO"; then
    skip "Go tool suite (skipped by user)"
    SKIPPED+=("gopls" "goimports" "staticcheck")
else
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
    go_install gopls       "golang.org/x/tools/gopls@latest"           gopls
    go_install goimports   "golang.org/x/tools/cmd/goimports@latest"   goimports
    go_install staticcheck "honnef.co/go/tools/cmd/staticcheck@latest" staticcheck

    echo "$PATH" | grep -q "$GOBIN" || \
        warn "Add Go binaries to PATH: export PATH=\"\$PATH:$GOBIN\""
fi

# ============================================================================
# 9. tmux: vim-tmux-navigator integration
# ============================================================================

step "tmux: vim-tmux-navigator integration"

if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not found — skipping navigator config"
    SKIPPED+=("tmux-navigator-config")
elif [[ $_I_TMUX -lt 0 ]]; then
    :   # already configured — noted earlier
elif ! _selected "$_I_TMUX"; then
    skip "tmux navigator config (skipped by user)"
    SKIPPED+=("tmux-navigator-config")
else
    TMUX_CONF="$HOME/.tmux.conf"
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
fi

# ============================================================================
# 10. LSP language servers
# ============================================================================

step "LSP language servers"
info "vim-lsp installs language servers on demand — no action needed here."
info ""
info "To install a server: open a source file in Vim and run:"
info "  :LspInstallServer"
info ""
info "Supported: Python, JS/TS, Go, Rust, C/C++, Shell, HTML, CSS, JSON, YAML, Markdown, SQL"
info ""
info "For Markdown LSP (marksman), the installer already handled it above."

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
echo -e "  ${CYAN}vim .${NC}          Open dashboard in current directory"
echo -e "  ${CYAN}vim myfile${NC}     Edit a specific file"
echo ""
echo -e "${BOLD}  First steps inside Vim${NC}"
echo -e "  ${CYAN}Esc${NC} or ${CYAN}jk${NC}     Exit insert mode → back to Normal"
echo -e "  ${CYAN}:q!${NC} + Enter   Emergency quit without saving"
echo -e "  ${CYAN},x${NC}            Save and quit"
echo -e "  ${CYAN},?${NC}            Open cheat sheet"
echo -e "  ${CYAN}:LspInstallServer${NC}  Install LSP for current filetype"
echo ""
echo -e "${YELLOW}[!]${NC}  Ctrl+s is mapped to save in Vim."
echo    "     If it freezes your terminal, add this to ~/.bashrc or ~/.zshrc:"
echo -e "     ${CYAN}stty -ixon${NC}"
echo ""
