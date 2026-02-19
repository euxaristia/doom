#!/usr/bin/env bash

set -euo pipefail
set -x

echo "Testing V Doom build..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOOM_FOLDER="${DOOM_FOLDER:-$ROOT_DIR}"
CC="${CC:-clang}"

if [ -n "${DOOM_ENGINE_DIR:-}" ]; then
  ENGINE_DIR="$DOOM_ENGINE_DIR"
elif [ -d "$DOOM_FOLDER/crispy-doom" ]; then
  ENGINE_DIR="crispy-doom"
elif [ -d "$DOOM_FOLDER/chocolate-doom" ]; then
  ENGINE_DIR="chocolate-doom"
else
  echo "ERROR: Could not locate crispy-doom/ or chocolate-doom/ under $DOOM_FOLDER"
  exit 1
fi

if [ -n "${DOOM_TARGET:-}" ]; then
  TARGET="$DOOM_TARGET"
elif [ "$ENGINE_DIR" = "crispy-doom" ]; then
  TARGET="crispy-doom"
else
  TARGET="chocolate-doom"
fi

ENGINE_ROOT="$DOOM_FOLDER/$ENGINE_DIR"
DOOM_OBJ_DIR="$ENGINE_ROOT/src/CMakeFiles/$TARGET.dir"
TEXTSCREEN_OBJ_DIR="$ENGINE_ROOT/textscreen/CMakeFiles/textscreen.dir"
PCSOUND_OBJ_DIR="$ENGINE_ROOT/pcsound/CMakeFiles/pcsound.dir"
OPL_OBJ_DIR="$ENGINE_ROOT/opl/CMakeFiles/opl.dir"

if [ ! -d "$DOOM_OBJ_DIR" ]; then
  echo "ERROR: $DOOM_OBJ_DIR does not exist. Build C objects first (run ./build_whole_project.sh)."
  exit 1
fi

if [ -f "$DOOM_FOLDER/doom_v/doom.o" ]; then
  DOOM_V_OBJECT="$DOOM_FOLDER/doom_v/doom.o"
elif [ -f "$ENGINE_ROOT/src/doom/doom_v/doom.o" ]; then
  DOOM_V_OBJECT="$ENGINE_ROOT/src/doom/doom_v/doom.o"
else
  echo "ERROR: translated V object not found (checked doom_v/doom.o and $ENGINE_ROOT/src/doom/doom_v/doom.o)"
  exit 1
fi

mapfile -d '' -t DOOM_OBJS < <(find "$DOOM_OBJ_DIR" -name '*.o' -print0)
mapfile -d '' -t TEXTSCREEN_OBJS < <(find "$TEXTSCREEN_OBJ_DIR" -name '*.o' -print0)
mapfile -d '' -t OPL_OBJS < <(find "$OPL_OBJ_DIR" -name '*.o' -print0)
PCSOUND_OBJS=()
if [ -d "$PCSOUND_OBJ_DIR" ]; then
  mapfile -d '' -t PCSOUND_OBJS < <(find "$PCSOUND_OBJ_DIR" -name '*.o' -print0)
fi

echo "Linking V Doom with C infrastructure..."
"$CC" -c "$DOOM_FOLDER/v_deh_init.c" -o "$DOOM_FOLDER/v_deh_init.o"
"$CC" -o "$DOOM_FOLDER/doomv" \
  "${DOOM_OBJS[@]}" \
  "${TEXTSCREEN_OBJS[@]}" \
  "${PCSOUND_OBJS[@]}" \
  "${OPL_OBJS[@]}" \
  "$DOOM_V_OBJECT" \
  "$DOOM_FOLDER/v_deh_init.o" \
  $(sdl2-config --libs) -lSDL2_mixer -lSDL2_net -lpng -lsamplerate -lm

echo "Build successful!"
ls -lh "$DOOM_FOLDER/doomv"
file "$DOOM_FOLDER/doomv"
