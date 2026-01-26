#!/bin/bash

# Fix deprecated V syntax from [attr] to @[attr]
# This script updates all .v files in the doom_v directory

echo "Fixing deprecated V syntax..."

# Find all .v files and fix the syntax
# Replace [c:'something'] with @[c:'something']
find doom_v -name "*.v" -exec sed -i 's/\[\(c:[^]]*\)\]/@[\1]/g' {} +

echo "Syntax update complete. Fixed [attr] to @[attr] in all .v files."