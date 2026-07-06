#!/usr/bin/env bash
# Extract the CHANGELOG section for a stable release tag.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: scripts/release-notes.sh vX.Y.Z" >&2
    exit 2
fi

tag="$1"

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected a stable semver tag like v2.3.0, got: $tag" >&2
    exit 2
fi

version="${tag#v}"

awk -v version="$version" '
    BEGIN {
        found = 0
        printing = 0
        heading = "^## " version "([[:space:]]|$)"
    }
    $0 ~ /^## / {
        if (printing) {
            exit
        }
        if ($0 ~ heading) {
            found = 1
            printing = 1
        }
    }
    printing {
        print
    }
    END {
        if (!found) {
            exit 1
        }
    }
' CHANGELOG.md || {
    echo "Missing CHANGELOG.md section for $version" >&2
    exit 1
}
