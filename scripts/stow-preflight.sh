#!/bin/bash

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

[ "$#" -eq 2 ] || {
  printf 'usage: %s PLATFORM TARGET\n' "$0" >&2
  exit 2
}

platform=$1
target=$2
[ -d "$target" ] || {
  printf 'error: target is not a directory: %s\n' "$target" >&2
  exit 2
}

packages=$("$SCRIPT_DIR/package-set.sh" "$platform") || exit 2
cd "$ROOT_DIR"
# The selected package names are controlled, whitespace-free directory names.
# shellcheck disable=SC2086
exec stow --simulate --no-folding --target "$target" $packages
