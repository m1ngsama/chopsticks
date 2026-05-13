#!/usr/bin/env bash
# get.sh - One-command bootstrap for chopsticks vim config
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash -s -- --yes
#   CHOPSTICKS_DEST=/absolute/path bash get.sh --dry-run

set -eo pipefail

REPO="https://github.com/m1ngsama/chopsticks.git"
DEST="${CHOPSTICKS_DEST:-$HOME/.vim}"
DRY_RUN=0
INSTALLER_ARGS=()

usage() {
    cat <<'EOF'
Usage: get.sh [OPTIONS] [INSTALLER_OPTIONS]

Options:
  --dry-run        Show what would happen without cloning, pulling, or installing
  --help, -h       Show this help and exit

Environment:
  CHOPSTICKS_DEST  Absolute install path (default: ~/.vim)

All other options are passed to install.sh after clone/update.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *) INSTALLER_ARGS+=("$arg") ;;
    esac
done

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; BOLD=''; NC=''
fi
ok()   { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }
die()  { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }
step() { echo -e "\n${BOLD}==> $1${NC}"; }
info() { echo "     $1"; }

case "$DEST" in
    /*) ;;
    *) die "CHOPSTICKS_DEST must be an absolute path: $DEST" ;;
esac

repo_origin() {
    git -C "$DEST" config --get remote.origin.url 2>/dev/null || true
}

is_chopsticks_repo() {
    local origin="$1"
    origin="${origin%/}"
    origin="${origin%.git}"
    case "$origin" in
        https://github.com/m1ngsama/chopsticks|\
        git@github.com:m1ngsama/chopsticks|\
        ssh://git@github.com/m1ngsama/chopsticks)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

echo -e "${BOLD}chopsticks — One-command installer${NC}"
echo "----------------------------------"
echo "  Repo: $REPO"
echo "  Dest: $DEST"
[[ $DRY_RUN -eq 1 ]] && echo "  Mode: dry-run"

# ── git ───────────────────────────────────────────────────────────────────────
step "Checking for git"

HAS_GIT=0
command -v git >/dev/null 2>&1 && HAS_GIT=1

if [[ $HAS_GIT -eq 0 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
        warn "git not found — would need to install git before a real install"
    else
        warn "git not found — attempting to install"
        if   command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y git >/dev/null 2>&1
        elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm git >/dev/null 2>&1
        elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y git >/dev/null 2>&1
        elif command -v brew    >/dev/null 2>&1; then brew install git >/dev/null 2>&1
        else die "git is required. Install it manually then re-run."; fi
        command -v git >/dev/null 2>&1 || die "git install failed. Try: sudo apt install git"
        HAS_GIT=1
    fi
fi
if [[ $HAS_GIT -eq 1 ]]; then
    ok "git $(git --version | awk '{print $3}')"
elif [[ $DRY_RUN -eq 1 ]]; then
    info "Would require: git"
else
    die "git is required. Install it manually then re-run."
fi

if [[ $DRY_RUN -eq 1 && $HAS_GIT -eq 0 ]]; then
    step "Setting up $DEST"
    if [[ -d "$DEST/.git" ]]; then
        info "Would inspect existing git repo at $DEST"
        info "Would update it only if its origin is $REPO"
    elif [[ -d "$DEST" ]]; then
        die "$DEST exists but git is unavailable, so dry-run cannot verify whether it is chopsticks.
  Install git and re-run dry-run for the full safety check."
    else
        info "Would clone $REPO to $DEST"
    fi
    info "Would run: bash install.sh ${INSTALLER_ARGS[*]:-(no installer options)}"
    exit 0
fi

# ── Clone or update ───────────────────────────────────────────────────────────
step "Setting up $DEST"

if [[ -d "$DEST/.git" ]]; then
    ORIGIN="$(repo_origin)"
    if ! is_chopsticks_repo "$ORIGIN"; then
        die "$DEST is a git repo, but it does not look like chopsticks.
  origin: ${ORIGIN:-none}
  Back it up first:  mv \"$DEST\" \"$DEST.bak\"
  Then re-run:       curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash"
    fi
    [[ -f "$DEST/install.sh" && -f "$DEST/.vimrc" ]] || \
        die "$DEST looks incomplete. Expected install.sh and .vimrc.
  Back it up first:  mv \"$DEST\" \"$DEST.bak\"
  Then re-run:       curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash"
    if [[ $DRY_RUN -eq 1 ]]; then
        info "Would update existing chopsticks repo at $DEST"
        info "Would run: bash install.sh ${INSTALLER_ARGS[*]:-(no installer options)}"
        exit 0
    fi
    warn "$DEST already exists — pulling latest changes"
    git -C "$DEST" pull --ff-only origin main 2>/dev/null || \
        warn "Could not pull latest — using existing version (run: git -C ~/.vim pull)"
    ok "Repository updated ($(git -C "$DEST" describe --tags 2>/dev/null || git -C "$DEST" rev-parse --short HEAD))"
elif [[ -d "$DEST" ]]; then
    die "$DEST exists but is not a chopsticks git repo.
  Back it up first:  mv \"$DEST\" \"$DEST.bak\"
  Then re-run:       curl -fsSL https://raw.githubusercontent.com/m1ngsama/chopsticks/main/get.sh | bash"
else
    if [[ $DRY_RUN -eq 1 ]]; then
        info "Would clone $REPO to $DEST"
        info "Would run: bash install.sh ${INSTALLER_ARGS[*]:-(no installer options)}"
        exit 0
    fi
    git clone --depth=1 "$REPO" "$DEST" || \
        die "Clone failed — check your network connection"
    ok "Cloned to $DEST ($(git -C "$DEST" describe --tags 2>/dev/null || git -C "$DEST" rev-parse --short HEAD))"
fi

# ── Run installer ─────────────────────────────────────────────────────────────
step "Running installer"

cd "$DEST"

# exec replaces this process with install.sh and reconnects stdin to /dev/tty
# so interactive prompts work correctly even when this script was piped from curl.
# Use a test-open to check /dev/tty is actually accessible (it may exist but be
# unusable in non-interactive SSH sessions or container environments).
if { true </dev/tty; } 2>/dev/null; then
    exec bash install.sh "${INSTALLER_ARGS[@]}" </dev/tty
else
    exec bash install.sh "${INSTALLER_ARGS[@]}"
fi
