#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

base_config="$ROOT_DIR/kitty/.config/kitty/kitty.conf"
mac_config="$ROOT_DIR/kitty-macos/.config/kitty/platform.conf"
ubuntu_config="$ROOT_DIR/kitty-ubuntu/.config/kitty/platform.conf"

base=$(cat "$base_config")
mac=$(cat "$mac_config" 2>/dev/null || true)
ubuntu=$(cat "$ubuntu_config" 2>/dev/null || true)

assert_contains "$base" 'include platform.conf' 'Kitty base includes its selected platform fragment'
assert_not_contains "$base" 'macos_colorspace' 'Kitty base contains a macOS colorspace setting'
assert_not_contains "$base" 'cmd+' 'Kitty base contains Command-key mappings'

assert_contains "$mac" 'macos_colorspace srgb' 'macOS Kitty fragment owns its colorspace'
assert_contains "$mac" 'map cmd+shift+c  copy_to_clipboard' 'macOS Kitty fragment owns Command-copy'
assert_contains "$mac" 'map cmd+shift+v  paste_from_clipboard' 'macOS Kitty fragment owns Command-paste'
assert_contains "$mac" 'map cmd+c copy_or_interrupt' 'macOS Kitty fragment owns copy-or-interrupt'

assert_contains "$ubuntu" 'map ctrl+shift+c copy_to_clipboard' 'Ubuntu Kitty fragment owns Ctrl-Shift-copy'
assert_contains "$ubuntu" 'map ctrl+shift+v paste_from_clipboard' 'Ubuntu Kitty fragment owns Ctrl-Shift-paste'
if rg -ni '^[[:space:]]*map[[:space:]]+[^[:space:]#]*alt' "$ubuntu_config" >/dev/null 2>&1; then
  fail 'Ubuntu Kitty fragment contains a global Alt mapping that conflicts with Sway'
fi
assert_not_contains "$ubuntu" 'cmd+' 'Ubuntu Kitty fragment contains Command-key mappings'
assert_not_contains "$ubuntu" 'macos_' 'Ubuntu Kitty fragment contains a macOS-only option'

for platform in macos ubuntu; do
  home="$tmp_dir/$platform home"
  mkdir -p "$home"
  stow --dir "$ROOT_DIR" --no-folding --target "$home" kitty "kitty-$platform"
  [ -L "$home/.config/kitty/kitty.conf" ] || fail "$platform Kitty base was not linked"
  [ -L "$home/.config/kitty/platform.conf" ] || fail "$platform Kitty fragment was not linked"
  linked_platform=$(cat "$home/.config/kitty/platform.conf")
  expected_platform=$(cat "$ROOT_DIR/kitty-$platform/.config/kitty/platform.conf")
  [ "$linked_platform" = "$expected_platform" ] || fail "$platform Kitty fragment linked the wrong content"
done

[ -f "$ROOT_DIR/bin-macos/.local/bin/cmux-scratch" ] || fail 'CMUX executable was not moved to bin-macos'
[ -f "$ROOT_DIR/bin-macos/.local/bin/cmux-scratch.swift" ] || fail 'CMUX source was not moved to bin-macos'
[ ! -e "$ROOT_DIR/bin/.local/bin/cmux-scratch" ] || fail 'CMUX executable remains in common bin'
[ ! -e "$ROOT_DIR/bin/.local/bin/cmux-scratch.swift" ] || fail 'CMUX source remains in common bin'
[ -f "$ROOT_DIR/bin/.local/bin/opencode-sessions" ] || fail 'portable opencode-sessions helper left common bin'

if find "$ROOT_DIR/bin/.local/bin" -type f -exec file {} + | rg -n 'Mach-O'; then
  fail 'common bin contains a Mach-O executable'
fi
if find "$ROOT_DIR/bin/.local/bin" -type f -name '*.swift' | grep -q .; then
  fail 'common bin contains Swift source'
fi
if rg -ni 'cmux|aerospace' "$ROOT_DIR/bin/.local/bin" >/dev/null; then
  fail 'common bin contains a CMUX or AeroSpace reference'
fi

compiler_bin="$tmp_dir/fake compiler"
mkdir -p "$compiler_bin"
cat >"$compiler_bin/swiftc" <<'FAKE_SWIFTC'
#!/bin/sh
printf '%s\n' "$@" >"$SWIFTC_ARGV_LOG"
FAKE_SWIFTC
chmod +x "$compiler_bin/swiftc"
PATH="$compiler_bin:/usr/bin:/bin" SWIFTC_ARGV_LOG="$tmp_dir/swiftc argv" \
  make --no-print-directory -s -C "$ROOT_DIR" build-bin
swiftc_argv=$(cat "$tmp_dir/swiftc argv")
expected_swiftc_argv=$(printf '%s\n' \
  -O \
  -o \
  bin-macos/.local/bin/cmux-scratch \
  bin-macos/.local/bin/cmux-scratch.swift)
[ "$swiftc_argv" = "$expected_swiftc_argv" ] || fail 'build-bin does not compile exclusively within bin-macos'
assert_not_contains "$swiftc_argv" 'bin/.local/bin/cmux-scratch' 'build-bin still references common bin'

pass 'Kitty and common bin are cleanly split by platform'
