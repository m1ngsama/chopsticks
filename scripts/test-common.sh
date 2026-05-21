#!/usr/bin/env bash
# Shared setup for chopsticks test scripts.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/chopsticks-test-XXXXXX")"
EMPTY_XDG="$TMP_ROOT/xdg-empty"
STARTUP_LIMIT_MS="${STARTUP_LIMIT_MS:-150}"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

cd "$ROOT"
mkdir -p "$EMPTY_XDG"

step() {
    printf '\n==> %s\n' "$1"
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}
