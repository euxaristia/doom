# DOOM.v - A V Language Reimplementation of DOOM

A ground-up rewrite of DOOM (based on crispy-doom) in the [V programming language](https://vlang.io/).

## Status

**In Progress** - This is an ongoing effort to translate crispy-doom from C to V.

Current capabilities:
- WAD file loading and parsing
- Basic frame rendering to PPM files
- Core game structures and types
- Player physics (movement, thrust, view height)
- Map object (Mobj) system
- Enemy AI stubs
- Sound/music enums defined

## Project Structure

```
doom/
├── vdoom/                  # Pure V implementation
│   ├── main.v             # Entry point
│   ├── core/              # Core game engine (105 .v files)
│   │   ├── p_user.v       # Player controls
│   │   ├── p_mobj.v       # Map objects
│   │   ├── p_enemy.v      # Enemy AI
│   │   ├── p_inter.v      # Game interactions
│   │   ├── r_main.v       # Rendering
│   │   └── ...
│   ├── engine/            # Rendering engine (empty)
│   ├── io/                # I/O stubs (empty)
│   └── platform/          # Platform code (empty)
├── wads/                  # Game WAD files
│   └── doom1.wad
└── crispy-doom/           # Original C implementation (reference)
```

## Building

### Prerequisites

- V compiler (latest version)
- SDL2 development libraries (for full DOOM)
- A DOOM WAD file (doom1.wad, doom.wad, etc.)

### Building the MVP

```bash
cd vdoom
v -enable-globals -o vdoom_test main.v
```

### Running

```bash
# Run with default WAD
./vdoom_test

# Specify a WAD file
./vdoom_test -iwad ./wads/doom1.wad

# Show help
./vdoom_test -help
```

Output frames are written to `out/vdoom_frame_*.ppm`.

## Why V?

V is a fast, compiled language with:
- C interoperability
- No null pointer exceptions
- Built-in serialization
- Cross-platform support
- 25x faster compilation than C

## Goals

The ultimate goal is a fully playable DOOM engine written entirely in V that is:
- Binary compatible with crispy-doom
- Feature-complete with all original DOOM functionality
- Easier to maintain and extend than the C original

## References

- [crispy-doom](https://github.com/fabiangreffrath/crispy-doom) - Original C source
- [V Programming Language](https://vlang.io/)
- [DOOM Wiki](https://doomwiki.org/)
