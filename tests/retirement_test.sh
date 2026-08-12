#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"
cd "$ROOT_DIR"

macos=$(scripts/package-set.sh macos)

for package in aerospace karabiner skhd yabai ghostty cmux kitty kitty-macos wezterm; do
  case " $macos " in
    *" $package "*) ;;
    *) fail "macOS package set lost retained automation or terminal package: $package" ;;
  esac
done

case " $macos " in
  *' hammerspoon '*) fail 'macOS package set still selects Hammerspoon' ;;
esac

retired_paths='hammerspoon/.hammerspoon/init.lua
hammerspoon/.hammerspoon/.gitignore
scripts/clear-out-files-before-stow.sh
scripts/setup-neovim-deps-linux.sh
scripts/check-neovim-deps-linux.sh
scripts/setup-stackline.sh
scripts/toggle-stackline-icons.sh'

tracked_retired=$(git ls-files --cached -- $retired_paths)
[ -z "$tracked_retired" ] || fail "retired paths remain tracked:
$tracked_retired"

[ -z "$(git ls-files --cached -- hammerspoon)" ] || \
  fail 'the retired Hammerspoon package still contains tracked files'

probe_dir="$ROOT_DIR/hammerspoon"
probe_relative="hammerspoon/.retirement-test-untracked-$$"
probe="$ROOT_DIR/$probe_relative"
created_probe_dir=0
if [ ! -d "$probe_dir" ]; then
  mkdir "$probe_dir"
  created_probe_dir=1
fi
cleanup_probe() {
  rm -f "$probe"
  if [ "$created_probe_dir" -eq 1 ]; then
    rmdir "$probe_dir" 2>/dev/null || true
  fi
}
trap cleanup_probe EXIT HUP INT TERM
printf '%s\n' 'user-owned Hammerspoon notes: hs -c is retired' >"$probe"
[ -z "$(git ls-files --cached -- "$probe_relative")" ] || \
  fail 'retirement probe unexpectedly entered tracked state'

help_output=$(make --no-print-directory -s help)
if printf '%s\n' "$help_output" | grep -Eiq 'prestow|hammerspoon'; then
  fail 'Make help still exposes prestow or Hammerspoon'
fi

makefile=$(cat Makefile)
assert_not_contains "$makefile" prestow 'Makefile still exposes the retired prestow target'

readme=$(cat README.md)
if printf '%s\n' "$readme" | grep -Eiq 'prestow|hammerspoon'; then
  fail 'README still advertises prestow or Hammerspoon'
fi

set +e
legacy_references=$(git grep --cached -n -I -E \
  'clear-out-files-before-stow|setup-neovim-deps-linux|check-neovim-deps-linux' \
  -- README.md Makefile scripts 2>&1)
legacy_reference_status=$?
set -e
[ "$legacy_reference_status" -eq 1 ] || fail "supported tracked files reference retired Linux installers:
$legacy_references"

set +e
hammerspoon_references=$(git grep --cached -n -I -i -E \
  'hammerspoon|(^|[[:space:]])hs[[:space:]]+-c' \
  -- ':!docs/superpowers/**' ':!tests/**' 2>&1)
hammerspoon_reference_status=$?
set -e
[ "$hammerspoon_reference_status" -eq 1 ] || fail "supported tracked files reference retired Hammerspoon automation:
$hammerspoon_references"
[ -f "$probe" ] || fail 'tracked-content scan removed user-owned untracked content'

for retained_path in \
  aerospace/.config/aerospace/aerospace.toml \
  karabiner/.config/karabiner/karabiner.json \
  skhd/.config/skhd/skhdrc \
  yabai/.yabairc \
  ghostty/.config/ghostty/config \
  cmux/.config/cmux/cmux.json \
  kitty/.config/kitty/kitty.conf \
  kitty-macos/.config/kitty/platform.conf \
  wezterm/.wezterm.lua \
  scripts/setup-colima-neovim.sh \
  docker/neovim/Dockerfile
do
  [ "$(git ls-files --cached -- "$retained_path")" = "$retained_path" ] || \
    fail "cleanup removed retained Mac automation, terminal, or Docker Neovim state: $retained_path"
done

pass 'retired Hammerspoon and duplicate Linux setup ownership are absent'
