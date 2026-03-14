#!/usr/bin/env bash

set -e

DOOM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAD_FILE="$DOOM_DIR/wads/doom1.wad"

if [ -f "$DOOM_DIR/doomv" ]; then
    EXECUTABLE="$DOOM_DIR/doomv"
elif [ -f "$DOOM_DIR/crispy-doom/src/crispy-doom" ]; then
    EXECUTABLE="$DOOM_DIR/crispy-doom/src/crispy-doom"
elif [ -f "$DOOM_DIR/chocolate-doom/src/chocolate-doom" ]; then
    EXECUTABLE="$DOOM_DIR/chocolate-doom/src/chocolate-doom"
else
    EXECUTABLE="$DOOM_DIR/crispy-doom/src/crispy-doom"
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Game executable not found at $EXECUTABLE"
    echo "Please build the project first with: DOOM_FOLDER=$DOOM_DIR ./build_whole_project.sh"
    exit 1
fi

if [ ! -f "$WAD_FILE" ]; then
    echo "Error: WAD file not found at $WAD_FILE"
    exit 1
fi

exec "$EXECUTABLE" -iwad "$WAD_FILE"
