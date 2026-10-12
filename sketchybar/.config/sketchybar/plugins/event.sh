#!/bin/bash
# AeroSpace callbacks also work before SketchyBar has been installed/started.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --trigger "$1" >/dev/null 2>&1 || true
fi
