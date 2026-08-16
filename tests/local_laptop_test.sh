#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

script="$ROOT_DIR/scripts/setup-local-laptop.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fake_bin="$tmp_dir/fake bin"
mkdir -p "$fake_bin"
jq_dir=$(dirname -- "$(command -v jq)")
cat >"$fake_bin/swaymsg" <<'FAKE_SWAYMSG'
#!/bin/sh
[ "$#" -eq 3 ] && [ "$1" = -t ] && [ "$2" = get_inputs ] && [ "$3" = -r ] || exit 91
printf '%s\n' "$SWAY_INPUTS_JSON"
FAKE_SWAYMSG
chmod +x "$fake_bin/swaymsg"

inputs='[
  {"identifier":"0:1:Power_Button","name":"Power Button","type":"keyboard"},
  {"identifier":"1:1:AT_Translated_Set_2_keyboard","name":"AT Translated Set 2 keyboard","type":"keyboard"},
  {"identifier":"1234:5678:External_Mechanical_Keyboard","name":"External Mechanical Keyboard","type":"keyboard"},
  {"identifier":"1267:12371:DELL0A78:00_04F3:3053_Touchpad","name":"DELL0A78:00 04F3:3053 Touchpad","type":"pointer"},
  {"identifier":"4321:8765:External_Mouse","name":"External Mouse","type":"pointer"}
]'
internal='1:1:AT_Translated_Set_2_keyboard'
external='1234:5678:External_Mechanical_Keyboard'
touchpad='1267:12371:DELL0A78:00_04F3:3053_Touchpad'
external_pointer='4321:8765:External_Mouse'
marker='# Managed by dotfiles scripts/setup-local-laptop.sh.'

run_setup() {
  setup_home=$1
  shift
  HOME="$setup_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
    "$script" "$@"
}

explicit_home="$tmp_dir/explicit home"
run_setup "$explicit_home" --keyboard "$internal"
sway_local="$explicit_home/.config/sway/local.d/laptop.conf"
wezterm_local="$explicit_home/.config/wezterm/local.lua"
[ -f "$sway_local" ] || fail 'laptop setup did not create the Sway local fragment'
[ -f "$wezterm_local" ] || fail 'laptop setup did not create the WezTerm local override'
sway_contents=$(cat "$sway_local")
wezterm_contents=$(cat "$wezterm_local")
assert_contains "$sway_contents" "$marker" 'Sway local fragment lacks its ownership marker'
assert_contains "$sway_contents" "input \"$internal\"" 'Sway local fragment does not target the selected keyboard exactly'
assert_contains "$sway_contents" 'xkb_options altwin:swap_lalt_lwin' 'Sway local fragment does not swap left Alt and Windows'
assert_not_contains "$sway_contents" "$external" 'Sway local fragment also targets the external keyboard'
assert_not_contains "$sway_contents" 'type:keyboard' 'Sway local fragment applies the swap to every keyboard'
assert_contains "$sway_contents" "input \"$touchpad\"" 'Sway local fragment does not target the built-in touchpad exactly'
assert_contains "$sway_contents" 'tap enabled' 'Sway local fragment does not enable touchpad tapping'
assert_contains "$sway_contents" 'tap_button_map lrm' 'Sway local fragment does not map two-finger tap to right-click'
assert_contains "$sway_contents" 'natural_scroll enabled' 'Sway local fragment does not enable natural scrolling'
assert_not_contains "$sway_contents" "$external_pointer" 'Sway local fragment also targets an external pointer'
assert_not_contains "$sway_contents" 'type:touchpad' 'Sway local fragment applies touchpad settings globally'
assert_contains "$wezterm_contents" "$marker" 'WezTerm local override lacks its ownership marker'
assert_contains "$wezterm_contents" 'font_size = 17' 'WezTerm local override does not use the laptop default font size'

before=$(shasum "$sway_local" "$wezterm_local")
run_setup "$explicit_home" --keyboard "$internal" >/dev/null
after=$(shasum "$sway_local" "$wezterm_local")
[ "$before" = "$after" ] || fail 'laptop setup is not idempotent'

printf '%s\n' "$marker" >"$sway_local"
printf '%s\n' "$marker" >"$wezterm_local"
run_setup "$explicit_home" --keyboard "$internal" >/dev/null
assert_contains "$(cat "$sway_local")" 'tap_button_map lrm' \
  'laptop setup did not upgrade its legacy managed Sway fragment'
assert_contains "$(cat "$wezterm_local")" 'font_size = 17' \
  'laptop setup did not upgrade its legacy managed WezTerm override'

custom_home="$tmp_dir/custom home"
run_setup "$custom_home" --keyboard "$external" --font-size 15.5 >/dev/null
custom_sway=$(cat "$custom_home/.config/sway/local.d/laptop.conf")
custom_wezterm=$(cat "$custom_home/.config/wezterm/local.lua")
assert_contains "$custom_sway" "input \"$external\"" 'explicit external identifier was not preserved literally'
assert_contains "$custom_wezterm" 'font_size = 15.5' 'explicit font size was not preserved'

interactive_home="$tmp_dir/interactive home"
printf '1\n' | HOME="$interactive_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
  "$script" >/dev/null
interactive_sway=$(cat "$interactive_home/.config/sway/local.d/laptop.conf")
assert_contains "$interactive_sway" "input \"$internal\"" 'interactive selection did not choose the first physical keyboard'
assert_not_contains "$interactive_sway" 'Power_Button' 'interactive selection offered a pseudo-keyboard device'
assert_contains "$interactive_sway" "input \"$touchpad\"" 'automatic touchpad selection did not choose the built-in touchpad'

for bad_font in zero 0 5 73 17px; do
  bad_home="$tmp_dir/bad font $bad_font"
  assert_status 2 env HOME="$bad_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
    "$script" --keyboard "$internal" --font-size "$bad_font"
  [ ! -e "$bad_home/.config" ] || fail "invalid font size wrote local state: $bad_font"
done

unknown_home="$tmp_dir/unknown home"
assert_status 2 env HOME="$unknown_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
  "$script" --keyboard '9:9:Not_A_Keyboard'
[ ! -e "$unknown_home/.config" ] || fail 'unknown keyboard identifier wrote local state'

unknown_touchpad_home="$tmp_dir/unknown touchpad home"
assert_status 2 env HOME="$unknown_touchpad_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
  "$script" --keyboard "$internal" --touchpad '9:9:Not_A_Touchpad'
[ ! -e "$unknown_touchpad_home/.config" ] || fail 'unknown touchpad identifier wrote local state'

unsafe_home="$tmp_dir/unsafe home"
assert_status 2 env HOME="$unsafe_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
  "$script" --keyboard '1:1:keyboard";exec_pwn'
[ ! -e "$unsafe_home/.config" ] || fail 'unsafe keyboard identifier wrote local state'

conflict_home="$tmp_dir/conflict home"
mkdir -p "$conflict_home/.config/wezterm"
printf '%s\n' 'return { font_size = 12 }' >"$conflict_home/.config/wezterm/local.lua"
assert_status 2 env HOME="$conflict_home" PATH="$fake_bin:$jq_dir:/usr/bin:/bin" SWAY_INPUTS_JSON="$inputs" \
  "$script" --keyboard "$internal"
[ ! -e "$conflict_home/.config/sway/local.d/laptop.conf" ] || \
  fail 'conflicting WezTerm override allowed a partial Sway write'
[ "$(cat "$conflict_home/.config/wezterm/local.lua")" = 'return { font_size = 12 }' ] || \
  fail 'laptop setup overwrote an unowned WezTerm override'

assert_status 2 "$script" --help unexpected

pass 'laptop-local setup targets one keyboard and writes safe local overrides'
