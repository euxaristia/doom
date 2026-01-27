#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Prefer DOOM_WAD if provided; otherwise let vdoom pick defaults.
exec v run vdoom/main.v "$@"
