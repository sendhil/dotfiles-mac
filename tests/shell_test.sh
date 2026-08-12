#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
mac_home="$tmp_dir/mac-home"
ubuntu_home="$tmp_dir/ubuntu-home"
mkdir -p "$mac_home" "$ubuntu_home"

stow_platform() {
  platform=$1
  target=$2
  packages=$($ROOT_DIR/scripts/package-set.sh "$platform")
  # shellcheck disable=SC2086
  stow --dir "$ROOT_DIR" --no-folding --target "$target" $packages
}

stow_platform macos "$mac_home"
stow_platform ubuntu "$ubuntu_home"

minimal_path=/usr/bin:/bin

PATH=$minimal_path HOME="$mac_home" ZDOTDIR="$mac_home" \
  /bin/zsh -dfc 'source "$HOME/.zshrc"'
PATH=$minimal_path HOME="$ubuntu_home" ZDOTDIR="$ubuntu_home" \
  /bin/zsh -dfc 'source "$HOME/.zshrc"; test "$EDITOR" = nvim; test "$LESS" = FRX; test "$TERMINAL" = kitty'
PATH=$minimal_path HOME="$ubuntu_home" \
  /bin/bash --noprofile --norc -c 'source "$HOME/.bashrc"; test "$EDITOR" = nvim; test "$LESS" = FRX; test "$TERMINAL" = kitty'

PATH=$minimal_path HOME="$ubuntu_home" WAYLAND_DISPLAY= \
  /bin/bash --noprofile --norc -c '
    source "$HOME/.bashrc"
    test -z "${MOZ_ENABLE_WAYLAND:-}"
    test -z "${QT_QPA_PLATFORM:-}"
  '

shell_paths='bash-linux shell-ubuntu'
prohibited_pattern='/opt/homebrew|Library/|/Users/|defaults|osascript|Xcode'
if rg -n --hidden -e "$prohibited_pattern" $shell_paths >"$tmp_dir/prohibited"; then
  cat "$tmp_dir/prohibited" >&2
  fail 'Ubuntu shell packages contain macOS-only configuration'
fi

pbcopy_hits=$(rg -l --hidden '\bpbcopy\b' $shell_paths bin/.local/bin/dotfiles-copy 2>/dev/null || true)
case "$pbcopy_hits" in
  '') ;;
  'bin/.local/bin/dotfiles-copy') ;;
  *) fail "pbcopy appears outside dotfiles-copy: $pbcopy_hits" ;;
esac

mac_platform=$(cat shell-macos/.config/dotfiles/platform.sh 2>/dev/null || true)
assert_contains "$mac_platform" 'command -v brew' 'macOS Homebrew setup is conditional'

[ ! -e "$mac_home/.config/dotfiles/local.sh" ] || fail 'macOS Stow created local.sh'
[ ! -e "$ubuntu_home/.config/dotfiles/local.sh" ] || fail 'Ubuntu Stow created local.sh'

if rg -n --hidden '/Users/sendhil/Projects|alias projects=' bash-linux shell-macos shell-ubuntu >"$tmp_dir/projects"; then
  cat "$tmp_dir/projects" >&2
  fail 'shell configuration retains a hardcoded personal project alias'
fi

zshenv=$(cat bash-linux/.zshenv)
assert_not_contains "$zshenv" 'zoxide init' '.zshenv initializes zoxide'
assert_not_contains "$zshenv" 'zprezto' '.zshenv initializes Prezto'
assert_not_contains "$zshenv" 'p10k' '.zshenv initializes Powerlevel10k'

case $(git check-ignore -v bash-linux/.config/dotfiles/local.sh 2>/dev/null || true) in
  '') fail 'package-local local.sh is not ignored' ;;
esac

pass 'shell entry points are portable and local overrides remain local'
