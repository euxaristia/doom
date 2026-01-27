#!/bin/bash

set -e

DOOM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTABLE="$DOOM_DIR/chocolate-doom/src/chocolate-doom"
WAD_FILE="$DOOM_DIR/wads/doom1.wad"

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
