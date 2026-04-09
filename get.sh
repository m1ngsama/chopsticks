#!/usr/bin/env bash
# get.sh - One-command bootstrap for chopsticks vim config
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes

set -eo pipefail

REPO="https://github.com/m1ngsama/chopsticks.git"
DEST="$HOME/.vim"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }
die()  { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }
step() { echo -e "\n${BOLD}==> $1${NC}"; }

echo -e "${BOLD}chopsticks — One-command installer${NC}"
echo "----------------------------------"
echo "  Repo: $REPO"
echo "  Dest: $DEST"

# ── git ───────────────────────────────────────────────────────────────────────
step "Checking for git"

if ! command -v git >/dev/null 2>&1; then
    warn "git not found — attempting to install"
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y git >/dev/null 2>&1
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm git >/dev/null 2>&1
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y git >/dev/null 2>&1
    elif command -v brew    >/dev/null 2>&1; then brew install git >/dev/null 2>&1
    else die "git is required. Install it manually then re-run."; fi
    command -v git >/dev/null 2>&1 || die "git install failed. Try: sudo apt install git"
fi
ok "git $(git --version | awk '{print $3}')"

# ── Clone or update ───────────────────────────────────────────────────────────
step "Setting up $DEST"

if [[ -d "$DEST/.git" ]]; then
    warn "$DEST already exists — pulling latest changes"
    git -C "$DEST" pull --ff-only origin main 2>/dev/null || \
        warn "Could not pull latest — using existing version (run: git -C ~/.vim pull)"
    ok "Repository updated"
elif [[ -d "$DEST" ]]; then
    die "$HOME/.vim exists but is not a chopsticks git repo.
  Back it up first:  mv ~/.vim ~/.vim.bak
  Then re-run:       curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash"
else
    git clone --depth=1 "$REPO" "$DEST" || \
        die "Clone failed — check your network connection"
    ok "Cloned to $DEST"
fi

# ── Run installer ─────────────────────────────────────────────────────────────
step "Running installer"

cd "$DEST"

# exec replaces this process with install.sh and reconnects stdin to /dev/tty
# so interactive prompts work correctly even when this script was piped from curl.
# Use a test-open to check /dev/tty is actually accessible (it may exist but be
# unusable in non-interactive SSH sessions or container environments).
if { true </dev/tty; } 2>/dev/null; then
    exec bash install.sh "$@" </dev/tty
else
    exec bash install.sh "$@"
fi
