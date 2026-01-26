#!/bin/bash

set -e
set -x

echo "Testing V Doom build..."

# Set environment variables
DOOM_FOLDER=/home/euxaristia/Documents/Projects/doom
CC=clang

# Try to link the V object with the C infrastructure
echo "Linking V Doom with C infrastructure..."

# Compile the wrapper
$CC -c v_deh_init.c -o v_deh_init.o

$CC -o doomv \
  $DOOM_FOLDER/chocolate-doom/src/CMakeFiles/chocolate-doom.dir/*.o \
  $DOOM_FOLDER/chocolate-doom/textscreen/CMakeFiles/textscreen.dir/*.o \
  $DOOM_FOLDER/chocolate-doom/pcsound/CMakeFiles/pcsound.dir/*.o \
  $DOOM_FOLDER/chocolate-doom/opl/CMakeFiles/opl.dir/*.o \
  $DOOM_FOLDER/doom_v/doom.o \
  v_deh_init.o \
  $(sdl2-config --libs) -lSDL2_mixer -lSDL2_net -lpng -lsamplerate -lm

echo "Build successful!"

# Check if the executable was created
if [ -f "doomv" ]; then
    echo "doomv executable created successfully"
    ls -lh doomv
    file doomv
else
    echo "ERROR: doomv executable was not created"
    exit 1
fi