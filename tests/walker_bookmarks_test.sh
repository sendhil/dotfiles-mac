#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

assert_eq() {
  expected=$1
  actual=$2
  message=$3
  [ "$expected" = "$actual" ] || fail "$message (expected '$expected', got '$actual')"
}

bridge="$ROOT_DIR/bin/.local/bin/walker-chrome-bookmarks"
walker_config="$ROOT_DIR/walker/.config/walker/config.toml"
elephant_config="$ROOT_DIR/walker/.config/elephant/elephant.toml"
elephant_menu="$ROOT_DIR/walker/.config/elephant/menus/chrome-bookmarks.lua"

[ -x "$bridge" ] || fail 'Chrome bookmark bridge is absent or not executable'
[ -f "$walker_config" ] || fail 'Walker configuration is absent'
[ -f "$elephant_config" ] || fail 'Elephant configuration is absent'
[ -f "$elephant_menu" ] || fail 'Elephant Chrome bookmark menu is absent'

assert_contains "$(cat "$walker_config")" '"desktopapplications"' \
  'Walker does not search desktop applications by default'
assert_contains "$(cat "$walker_config")" '"clipboard"' \
  'Walker does not expose clipboard history'
assert_contains "$(cat "$walker_config")" '"snippets"' \
  'Walker does not expose snippets'
assert_contains "$(cat "$walker_config")" 'provider = "menus:chrome-bookmarks"' \
  'Walker does not expose Chrome bookmarks through its menu provider'
assert_contains "$(cat "$elephant_config")" 'clipboard' \
  'Elephant configuration does not enable clipboard provider'
assert_contains "$(cat "$elephant_config")" 'snippets' \
  'Elephant configuration does not enable snippets provider'
assert_contains "$(cat "$elephant_menu")" 'walker-chrome-bookmarks' \
  'Chrome bookmark menu does not use the safe bridge'

fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/walker-bookmarks-test.XXXXXX")
trap 'rm -rf -- "$fixture_root"' EXIT HUP INT TERM
fake_home="$fixture_root/home"
fake_bin="$fixture_root/bin"
chrome_root="$fake_home/.config/google-chrome"
mkdir -p "$chrome_root/Default" "$chrome_root/Profile 1" "$chrome_root/Profile 2" "$fake_bin"

cat >"$chrome_root/Default/Bookmarks" <<'JSON'
{
  "roots": {
    "bookmark_bar": {
      "children": [
        {"type": "url", "name": "Example", "url": "https://example.test/"}
      ]
    }
  }
}
JSON
cat >"$chrome_root/Profile 1/Bookmarks" <<'JSON'
{
  "roots": {
    "other": {
      "children": [
        {"type": "url", "name": "Docs", "url": "https://docs.example.test/"}
      ]
    }
  }
}
JSON
printf '{malformed\n' >"$chrome_root/Profile 2/Bookmarks"
cp "$chrome_root/Default/Bookmarks" "$fixture_root/default.before"
cp "$chrome_root/Profile 1/Bookmarks" "$fixture_root/profile.before"

cat >"$fake_bin/xdg-open" <<'FAKE_XDG_OPEN'
#!/bin/bash
printf '%s\n' "$*" >>"${WALKER_XDG_OPEN_LOG:?}"
FAKE_XDG_OPEN
chmod +x "$fake_bin/xdg-open"

output=$(HOME="$fake_home" PATH="$fake_bin:$PATH" "$bridge")
assert_contains "$output" $'Example\thttps://example.test/' \
  'bookmark bridge did not find the Default Chrome profile'
assert_contains "$output" $'Docs\thttps://docs.example.test/' \
  'bookmark bridge did not find the additional Chrome profile'

WALKER_XDG_OPEN_LOG="$fixture_root/xdg-open.log" \
  HOME="$fake_home" PATH="$fake_bin:$PATH" "$bridge" --open 'https://example.test/' \
  >/dev/null 2>&1 || fail 'bookmark bridge rejected a discovered URL'
assert_eq 'https://example.test/' "$(cat "$fixture_root/xdg-open.log")" \
  'bookmark bridge did not pass the selected URL to xdg-open'

if WALKER_XDG_OPEN_LOG="$fixture_root/xdg-open.log" \
  HOME="$fake_home" PATH="$fake_bin:$PATH" "$bridge" --open 'https://not-bookmarked.test/' \
  >/dev/null 2>&1; then
  fail 'bookmark bridge opened a URL that was not discovered from Chrome'
fi
assert_eq 'https://example.test/' "$(cat "$fixture_root/xdg-open.log")" \
  'bookmark bridge attempted to open an untrusted URL'

cmp -s "$chrome_root/Default/Bookmarks" "$fixture_root/default.before" || \
  fail 'bookmark bridge modified the Default Chrome profile'
cmp -s "$chrome_root/Profile 1/Bookmarks" "$fixture_root/profile.before" || \
  fail 'bookmark bridge modified the additional Chrome profile'

pass 'Walker configuration and read-only Chrome bookmark bridge are wired'
