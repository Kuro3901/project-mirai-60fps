#!/usr/bin/env bash
# install the 60 fps patch for Zakuro (Linux)
set -euo pipefail
cd "$(dirname "$0")"

MODS="${XDG_DATA_HOME:-$HOME/.local/share}/zakuro/mods/0004000000148C00"
mkdir -p "$MODS"
cp patches/mirai-60fps-v3-camera.ips "$MODS/code.ips"
echo "Installed the 60 fps patch -> $MODS/code.ips"
echo
echo "Requirements:"
echo "  - the IPS works on any Zakuro build"
echo "  - more than 60 fps needs the patched Zakuro build - see the README"
echo "  - launch: ~/.local/share/zakuro or your own zakuro build with the .cci"
