#!/bin/bash

set -euo pipefail

PROGRAM=${0##*/}
MARKER='# Managed by dotfiles scripts/setup-local-laptop.sh.'

usage() {
	cat <<EOF
usage: $PROGRAM [--keyboard IDENTIFIER] [--font-size NUMBER]

Create ignored, machine-local Sway and WezTerm overrides.
When --keyboard is omitted, select a physical keyboard from the live Sway session.
The default laptop font size is 17.
EOF
}

input_error() {
	printf 'error: %s\n' "$1" >&2
	usage >&2
	exit 2
}

operational_error() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

keyboard_id=
font_size=17

while [ "$#" -gt 0 ]; do
	case $1 in
		--keyboard)
			[ "$#" -ge 2 ] || input_error '--keyboard requires an identifier'
			keyboard_id=$2
			shift 2
			;;
		--font-size)
			[ "$#" -ge 2 ] || input_error '--font-size requires a number'
			font_size=$2
			shift 2
			;;
		--help)
			[ "$#" -eq 1 ] || input_error '--help does not accept additional arguments'
			usage
			exit 0
			;;
		*) input_error "unknown argument: $1" ;;
	esac
done

if [[ ! $font_size =~ ^[0-9]+([.][0-9]+)?$ ]] ||
	! awk -v value="$font_size" 'BEGIN { exit !(value >= 6 && value <= 72) }'; then
	input_error 'font size must be a number from 6 through 72'
fi

case ${HOME:-} in
	/*) ;;
	*) input_error 'HOME must be an absolute path' ;;
esac

command -v swaymsg >/dev/null 2>&1 || operational_error 'swaymsg is required'
command -v jq >/dev/null 2>&1 || operational_error 'jq is required'

if ! inputs_json=$(swaymsg -t get_inputs -r); then
	operational_error 'unable to read inputs from the active Sway session'
fi
if ! printf '%s\n' "$inputs_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
	operational_error 'Sway returned an invalid input inventory'
fi

if [ -z "$keyboard_id" ]; then
	candidate_lines=$(printf '%s\n' "$inputs_json" | jq -r '
		.[]
		| select(.type == "keyboard")
		| select((.name | test("Power Button|Sleep Button|Video Bus|Lid Switch|WebCam"; "i")) | not)
		| [.identifier, .name]
		| @tsv
	')

	candidate_ids=()
	candidate_names=()
	while IFS=$'\t' read -r candidate_id candidate_name; do
		[ -n "$candidate_id" ] || continue
		candidate_ids[${#candidate_ids[@]}]=$candidate_id
		candidate_names[${#candidate_names[@]}]=$candidate_name
	done < <(printf '%s\n' "$candidate_lines")

	case ${#candidate_ids[@]} in
		0) operational_error 'no physical keyboards were reported by Sway' ;;
		1) keyboard_id=${candidate_ids[0]} ;;
		*)
			printf 'Select the built-in keyboard:\n' >&2
			index=0
			while [ "$index" -lt "${#candidate_ids[@]}" ]; do
				printf '  %d) %s [%s]\n' "$((index + 1))" "${candidate_names[$index]}" "${candidate_ids[$index]}" >&2
				index=$((index + 1))
			done
			printf 'Keyboard [1-%d]: ' "${#candidate_ids[@]}" >&2
			IFS= read -r selection || input_error 'keyboard selection was cancelled'
			case $selection in
				''|*[!0-9]*) input_error 'keyboard selection must be a listed number' ;;
			esac
			[ "$selection" -ge 1 ] && [ "$selection" -le "${#candidate_ids[@]}" ] ||
				input_error 'keyboard selection is outside the listed range'
			keyboard_id=${candidate_ids[$((selection - 1))]}
			;;
	esac
fi

case $keyboard_id in
	''|*[!A-Za-z0-9_.:-]*) input_error 'keyboard identifier contains unsafe characters' ;;
esac

keyboard_count=$(printf '%s\n' "$inputs_json" | jq -r --arg identifier "$keyboard_id" \
	'[.[] | select(.type == "keyboard" and .identifier == $identifier)] | length')
[ "$keyboard_count" -eq 1 ] || input_error 'keyboard identifier is not present exactly once in Sway'
keyboard_name=$(printf '%s\n' "$inputs_json" | jq -r --arg identifier "$keyboard_id" \
	'.[] | select(.type == "keyboard" and .identifier == $identifier) | .name')

sway_target="$HOME/.config/sway/local.d/laptop.conf"
wezterm_target="$HOME/.config/wezterm/local.lua"

require_owned_or_absent() {
	target=$1
	label=$2
	if [ -e "$target" ] || [ -L "$target" ]; then
		[ -f "$target" ] && [ ! -L "$target" ] || input_error "$label target is not a regular file: $target"
		first_line=$(sed -n '1p' "$target" 2>/dev/null || true)
		[ "$first_line" = "$MARKER" ] || input_error "$label target already exists and is not managed by this script: $target"
	fi
}

require_owned_or_absent "$sway_target" 'Sway local fragment'
require_owned_or_absent "$wezterm_target" 'WezTerm local override'

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-local-laptop.XXXXXX") ||
	operational_error 'unable to create a staging directory'
sway_temp=
wezterm_temp=
cleanup() {
	[ -z "$sway_temp" ] || rm -f "$sway_temp"
	[ -z "$wezterm_temp" ] || rm -f "$wezterm_temp"
	rm -rf "$stage_dir"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

cat >"$stage_dir/laptop.conf" <<EOF
$MARKER
# $keyboard_name
input "$keyboard_id" {
    xkb_options altwin:swap_lalt_lwin
}
EOF

cat >"$stage_dir/local.lua" <<EOF
$MARKER
return {
  font_size = $font_size,
}
EOF

sway_parent=${sway_target%/*}
wezterm_parent=${wezterm_target%/*}
mkdir -p "$sway_parent" "$wezterm_parent"
sway_temp=$(mktemp "$sway_parent/.laptop.conf.XXXXXX")
wezterm_temp=$(mktemp "$wezterm_parent/.local.lua.XXXXXX")
install -m 0644 "$stage_dir/laptop.conf" "$sway_temp"
install -m 0644 "$stage_dir/local.lua" "$wezterm_temp"
mv -f "$sway_temp" "$sway_target"
sway_temp=
mv -f "$wezterm_temp" "$wezterm_target"
wezterm_temp=

printf 'configured built-in keyboard: %s [%s]\n' "$keyboard_name" "$keyboard_id"
printf 'configured WezTerm font size: %s\n' "$font_size"
printf 'reload Sway and restart WezTerm to apply the local laptop profile\n'
