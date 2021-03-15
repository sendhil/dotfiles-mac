#!/bin/bash -e

if [ "$EUID" -ne 0 ]; then
  echo "$HOME"
else
  echo $(getent passwd $SUDO_USER | cut -d: -f6)
fi
