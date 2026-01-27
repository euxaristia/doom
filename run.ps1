#!/usr/bin/env pwsh

$DoomDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Executable = Join-Path $DoomDir "chocolate-doom\src\chocolate-doom.exe"
$WadFile = Join-Path $DoomDir "wads\doom1.wad"

if (-not (Test-Path $Executable)) {
    Write-Error "Game executable not found at $Executable"
    Write-Error "Please build the project first with: DOOM_FOLDER=$DoomDir .\build_whole_project.sh"
    exit 1
}

if (-not (Test-Path $WadFile)) {
    Write-Error "WAD file not found at $WadFile"
    exit 1
}

& $Executable -iwad $WadFile
