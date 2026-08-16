#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

readme=$(cat "$ROOT_DIR/README.md" 2>/dev/null || true)
checklist=$(cat "$ROOT_DIR/docs/ubuntu-first-login.md" 2>/dev/null || true)

for needle in \
  'cross-platform' \
  'mac-laptop-setup' \
  'linux-laptop-setup' \
  'bin/setup-work-laptop work "$HOME/src/dotfiles-mac"' \
  'rerun the same command inside Sway' \
  'git clone --recurse-submodules' \
  'TPM launcher is vendored' \
  'make preflight-macos' \
  'make stow-macos' \
  'make unstow-macos' \
  'make preflight-ubuntu' \
  'make stow-ubuntu' \
  'make unstow-ubuntu' \
  'Do not delete' \
  'local.sh' \
  'scripts/setup-local-laptop.sh' \
  '~/.config/sway/local.d/laptop.conf' \
  '~/.config/wezterm/local.lua' \
  'font size 17' \
  'selected built-in keyboard' \
  'built-in touchpad' \
  'external keyboards' \
  'natural scrolling' \
  'two-finger tap for right-click' \
  'current workspace' \
  'Super+T' \
  'Super+N' \
  'Super+W' \
  'Super+C' \
  'Super+V' \
  'Super+F' \
  'Ctrl remains terminal input' \
  'OSC 52' \
  'GNOME' \
  'GDM' \
  'NVIDIA' \
  'Wofi' \
  'stock i3' \
  'swaymsg -t get_tree' \
  'pre-linux-2026-08-11'
do
  assert_contains "$readme" "$needle" "README is missing required cross-platform guidance: $needle"
done

for package_group in 'Common packages' 'macOS packages' 'Ubuntu packages'; do
  assert_contains "$readme" "$package_group" "README does not explain package ownership: $package_group"
done

first_bootstrap=$(printf '%s\n' "$readme" | grep -n -m1 'bin/bootstrap' | cut -d: -f1 || true)
first_doctor=$(printf '%s\n' "$readme" | grep -n -m1 'bin/doctor work' | cut -d: -f1 || true)
first_preflight=$(printf '%s\n' "$readme" | grep -n -m1 'make preflight-ubuntu' | cut -d: -f1 || true)
[ -n "$first_bootstrap" ] && [ -n "$first_doctor" ] && [ -n "$first_preflight" ] || \
  fail 'README does not contain the Ubuntu setup and dotfiles handoff commands'
[ "$first_bootstrap" -lt "$first_doctor" ] && [ "$first_doctor" -lt "$first_preflight" ] || \
  fail 'README must run linux-laptop-setup before the dotfiles Ubuntu preflight'
setup_sequence='bin/bootstrap
bin/install-wezterm
bin/audit work
bin/apply work
bin/audit work
bin/doctor work'
assert_contains "$readme" "$setup_sequence" \
  'README does not show the complete supported linux-laptop-setup command order'

for check in \
  'Sway reaches a stable desktop' \
  'GNOME can still be selected' \
  'Alt+Enter' \
  'Alt+Space' \
  'Super+T' \
  'Super+V' \
  'focus' \
  'move' \
  'workspaces 1–20' \
  'back-and-forth' \
  'scratchpad' \
  'resize' \
  'output' \
  'routing' \
  'Waybar' \
  'Mako' \
  'clipboard' \
  'screenshots' \
  'brightness' \
  'locking' \
  'idle locking' \
  'audio' \
  'Network' \
  'Bluetooth' \
  'Policy prompts' \
  'Slack and Zoom launch' \
  'screen sharing' \
  'SSH session from the work Mac' \
  'Logout works'
do
  assert_contains "$checklist" "$check" "Ubuntu first-login checklist is missing a physical check: $check"
done

assert_contains "$checklist" 'Wofi launcher' \
  'Ubuntu first-login checklist does not identify the Wofi launcher'
case "$readme
$checklist" in
  *'Alt+d'*) fail 'supported documentation still advertises the retired Alt-d launcher binding' ;;
esac
case "$readme
$checklist" in
  *Fuzzel*|*fuzzel*) fail 'supported documentation still references unavailable Fuzzel' ;;
esac

pass 'cross-platform workflow and physical Sway checks are documented'
