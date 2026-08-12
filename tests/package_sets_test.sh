#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"
cd "$ROOT_DIR"

expected_common='bash-linux bat bin direnv fd neovim prezto sesh tmux zellij'
expected_macos="$expected_common aerospace bin-macos ccstatusline cmux devservices ghostty herdr karabiner kitty kitty-macos shell-macos skhd wezterm yabai"
expected_ubuntu="$expected_common kitty kitty-ubuntu shell-ubuntu sway waybar fuzzel mako swaylock xdg-portal"

macos=$(scripts/package-set.sh macos)
ubuntu=$(scripts/package-set.sh ubuntu)

[ "$macos" = "$expected_macos" ] || fail 'macOS package set is not canonical'
[ "$ubuntu" = "$expected_ubuntu" ] || fail 'Ubuntu package set is not canonical'
assert_contains "$macos" aerospace 'macOS includes AeroSpace'
assert_contains "$macos" karabiner 'macOS includes Karabiner'
assert_contains "$macos" shell-macos 'macOS includes its shell fragment'
case $macos in *sway*|*hammerspoon*) fail 'macOS contains retired/wrong platform package' ;; esac
assert_contains "$ubuntu" sway 'Ubuntu includes Sway'
assert_contains "$ubuntu" shell-ubuntu 'Ubuntu includes its shell fragment'
case $ubuntu in *aerospace*|*karabiner*|*hammerspoon*) fail 'Ubuntu contains a Mac package' ;; esac
assert_status 2 scripts/package-set.sh windows

for package in $macos $ubuntu; do
  [ -d "$package" ] || fail "selected package directory does not exist: $package"
done

pass 'platform package sets are exact and valid'
