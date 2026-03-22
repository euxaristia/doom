#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "Compiling vdoom..."
v -enable-globals vdoom/ -o vdoom/vdoom

WAD="${1:-$ROOT/wads/doom1.wad}"

exec "$ROOT/vdoom/vdoom" "$WAD" --window --loop
