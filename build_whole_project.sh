#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z ${CC+x} ]; then
  if [ -x /usr/bin/clang ]; then
    export CC=/usr/bin/clang
  else
    export CC=clang
  fi
fi
if [ -z ${DOOM_FOLDER+x} ]; then export DOOM_FOLDER="$(cd "$(dirname "$0")" && pwd)"; fi
if [ -z ${WAD_FILE+x} ]; then export WAD_FILE="$DOOM_FOLDER/wads/doom1.wad"; fi
if [ -z ${V_EXE+x} ]; then export V_EXE="$(command -v v)"; fi
if [ -z "$V_EXE" ]; then echo "Error: v compiler not found in PATH"; exit 1; fi

if [ -n "${DOOM_ENGINE_DIR:-}" ]; then
  ENGINE_DIR="$DOOM_ENGINE_DIR"
elif [ -d "$DOOM_FOLDER/crispy-doom" ]; then
  ENGINE_DIR="crispy-doom"
elif [ -d "$DOOM_FOLDER/chocolate-doom" ]; then
  ENGINE_DIR="chocolate-doom"
else
  echo "Error: Could not locate crispy-doom/ or chocolate-doom/ under $DOOM_FOLDER"
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
cd "$ENGINE_ROOT"
rm -rf src/doom/doom_v/
cmake -DCMAKE_BUILD_TYPE=Debug .
make "$TARGET"

PATH="/usr/local/bin:/usr/bin" "$V_EXE" translate src/doom

cat << EOF > src/doom/doom_v/vdoom_patch_linux.v
module main
const _is_space = 8192
type U16 = u16
fn C.__ctype_b_loc() &&U16
fn __ctype_b_loc() &&U16 { return C.__ctype_b_loc() }
EOF

cd "$ENGINE_ROOT/src/doom"
## compile the produced V source code to an .o file that can be linked to the rest:
v -cc "$CC" -o doom_v/doom.o -w -translated doom_v/

cd "$DOOM_FOLDER"
DOOM_ENGINE_DIR="$ENGINE_DIR" DOOM_TARGET="$TARGET" ./test_v_doom_build.sh

cp "$WAD_FILE" "$ENGINE_ROOT/src/doom/"

set +x
printf "\nRun doom with:\n%s\n" "$DOOM_FOLDER/doomv"
