#!/bin/bash

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

common_packages='bash-linux bat bin direnv fd neovim prezto sesh tmux zellij'
macos_packages='aerospace bin-macos ccstatusline cmux devservices ghostty herdr karabiner kitty kitty-macos shell-macos skhd wezterm yabai'
ubuntu_packages='kitty kitty-ubuntu shell-ubuntu sway waybar fuzzel mako swaylock xdg-portal'

packages_for() {
  case ${1-} in
    macos) printf '%s %s\n' "$common_packages" "$macos_packages" ;;
    ubuntu) printf '%s %s\n' "$common_packages" "$ubuntu_packages" ;;
    *) printf 'error: unsupported platform: %s\n' "${1-}" >&2; return 2 ;;
  esac
}

validate_packages() {
  for package in $1; do
    if [ ! -d "$ROOT_DIR/$package" ]; then
      printf 'error: package directory does not exist: %s\n' "$package" >&2
      return 2
    fi
  done
}

main() {
  if [ "$#" -ne 1 ]; then
    printf 'usage: %s PLATFORM\n' "$0" >&2
    return 2
  fi

  packages=$(packages_for "$1") || return 2
  validate_packages "$packages" || return 2
  printf '%s\n' "$packages"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
