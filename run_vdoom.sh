#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

WAD="${1:-$ROOT/wads/doom1.wad}"

exec "$ROOT/vdoom/vdoom" "$WAD" --window --loop
