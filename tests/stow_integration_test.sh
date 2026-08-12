#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

if ! command -v stow >/dev/null 2>&1; then
  printf 'ok - SKIP: GNU Stow is unavailable; end-to-end link test not run\n'
  exit 0
fi

fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-stow-test.XXXXXX")
trap 'rm -rf -- "$fixture_root"' EXIT HUP INT TERM
test_root="$fixture_root/path with spaces"
mac_home="$test_root/mac home"
ubuntu_home="$test_root/ubuntu home"
mkdir -p "$mac_home" "$ubuntu_home"

printf 'mac marker\n' >"$mac_home/.dotfiles-test-marker"
printf 'ubuntu marker\n' >"$ubuntu_home/.dotfiles-test-marker"

run_make() {
  target=$1
  shift
  make --no-print-directory -s -C "$ROOT_DIR" TARGET="$target" "$@"
}

run_make "$mac_home" preflight-macos
run_make "$mac_home" stow-macos
run_make "$ubuntu_home" preflight-ubuntu
run_make "$ubuntu_home" stow-ubuntu

for linked_path in \
  "$mac_home/.zshrc" \
  "$mac_home/.config/dotfiles/platform.sh" \
  "$mac_home/.config/aerospace/aerospace.toml" \
  "$ubuntu_home/.zshrc" \
  "$ubuntu_home/.config/dotfiles/platform.sh" \
  "$ubuntu_home/.config/sway/config" \
  "$ubuntu_home/.config/waybar/config.jsonc"
do
  [ -L "$linked_path" ] || fail "representative path is not a Stow link: $linked_path"
done

[ ! -e "$mac_home/.config/sway/config" ] || fail 'macOS home contains Sway configuration'
[ ! -e "$mac_home/.hammerspoon" ] || fail 'macOS home contains retired automation configuration'
[ ! -e "$ubuntu_home/.config/aerospace/aerospace.toml" ] || fail 'Ubuntu home contains AeroSpace configuration'
[ ! -e "$ubuntu_home/.config/karabiner/karabiner.json" ] || fail 'Ubuntu home contains Karabiner configuration'

minimal_path=/usr/bin:/bin
for home_dir in "$mac_home" "$ubuntu_home"; do
  PATH=$minimal_path HOME="$home_dir" \
    /bin/bash --noprofile --norc -c 'source "$HOME/.bashrc"'
  if command -v zsh >/dev/null 2>&1; then
    PATH=$minimal_path HOME="$home_dir" ZDOTDIR="$home_dir" \
      zsh -dfc 'source "$HOME/.zshrc"'
  else
    printf 'ok - SKIP: Zsh is unavailable; startup check not run for %s\n' "$home_dir"
  fi
done

run_make "$mac_home" unstow-macos
run_make "$ubuntu_home" unstow-ubuntu

for home_dir in "$mac_home" "$ubuntu_home"; do
  remaining=$(find "$home_dir" -mindepth 1 \( -type f -o -type l \) -print | LC_ALL=C sort)
  [ "$remaining" = "$home_dir/.dotfiles-test-marker" ] || fail "Stow removal left non-test files in $home_dir:
$remaining"
done

pass 'real Stow links and unlinks both platforms in isolated homes'
