#!/bin/bash

set -e;
set -x;

if [ -z ${CC+x} ]; then
  if [ -x /usr/bin/clang ]; then
    export CC=/usr/bin/clang;
  else
    export CC=clang;
  fi
fi
if [ -z ${DOOM_FOLDER+x} ]; then export DOOM_FOLDER="$(cd "$(dirname "$0")" && pwd)"; fi
if [ -z ${WAD_FILE+x} ]; then export WAD_FILE="$DOOM_FOLDER/wads/doom1.wad"; fi
if [ -z ${V_EXE+x} ]; then export V_EXE="$(command -v v)"; fi
if [ -z "$V_EXE" ]; then echo "Error: v compiler not found in PATH"; exit 1; fi

cd "$DOOM_FOLDER/chocolate-doom" ;
git clean -xf ;
rm -rf src/doom/doom_v/ ;
cmake -DCMAKE_BUILD_TYPE=Debug . ;
make chocolate-doom ;

PATH="/usr/local/bin:/usr/bin" "$V_EXE" translate src/doom ;

cat << EOF > src/doom/doom_v/vdoom_patch_linux.v
module main
const _is_space = 8192
type U16 = u16
fn C.__ctype_b_loc() &&U16
fn __ctype_b_loc() &&U16 { return C.__ctype_b_loc() }
EOF

cd $DOOM_FOLDER/chocolate-doom/src/doom ;
## compile the produced V source code to an .o file that can be linked to the rest:
v -cc $CC -o doom_v/doom.o -w -translated doom_v/

PCSOUND_DIR="$DOOM_FOLDER/chocolate-doom/pcsound/CMakeFiles/pcsound.dir"
PCSOUND_OBJS=()
if [ -d "$PCSOUND_DIR" ]; then
  PCSOUND_OBJS=("$PCSOUND_DIR"/*.o)
fi

$CC -o doomv \
  "$DOOM_FOLDER"/chocolate-doom/src/CMakeFiles/chocolate-doom.dir/*.o \
  "$DOOM_FOLDER"/chocolate-doom/textscreen/CMakeFiles/textscreen.dir/*.o \
  "${PCSOUND_OBJS[@]}" \
  "$DOOM_FOLDER"/chocolate-doom/opl/CMakeFiles/opl.dir/*.o \
  "$DOOM_FOLDER"/chocolate-doom/src/doom/doom_v/doom.o \
  $(sdl2-config --libs) -lSDL2_mixer -lSDL2_net -lpng -lsamplerate -lm

cp "$WAD_FILE" .

set +x
printf "\nRun doom with:\n%s\n" "$DOOM_FOLDER/chocolate-doom/src/doom/doomv"
