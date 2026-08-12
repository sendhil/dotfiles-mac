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
prohibited_pattern='/opt/homebrew|Library/|/Users/|defaults|osascript|Xcode|Hammerspoon|(^|[[:space:]])hs[[:space:]]+-c'
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

fake_bin="$tmp_dir/fake-bin"
empty_bin="$tmp_dir/empty-bin"
mkdir -p "$fake_bin" "$empty_bin"
cat >"$fake_bin/open" <<'FAKE_OPEN'
#!/bin/sh
printf 'open|%s\n' "$1" >>"$SHELL_COMMAND_LOG"
FAKE_OPEN
cat >"$fake_bin/xdg-open" <<'FAKE_XDG_OPEN'
#!/bin/sh
printf 'xdg-open|%s\n' "$1" >>"$SHELL_COMMAND_LOG"
FAKE_XDG_OPEN
cat >"$fake_bin/safe-browser" <<'FAKE_BROWSER'
#!/bin/sh
printf 'browser|%s\n' "$1" >>"$SHELL_COMMAND_LOG"
FAKE_BROWSER
cat >"$fake_bin/countdown" <<'FAKE_COUNTDOWN'
#!/bin/sh
printf 'countdown|%s\n' "$1" >>"$SHELL_COMMAND_LOG"
FAKE_COUNTDOWN
cat >"$fake_bin/notify-send" <<'FAKE_NOTIFY'
#!/bin/sh
printf 'notify|%s\n' "$1" >>"$SHELL_COMMAND_LOG"
FAKE_NOTIFY
chmod +x "$fake_bin"/*

: >"$tmp_dir/commands.log"
PATH="$fake_bin:/usr/bin:/bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" DOTFILES_UNAME=Darwin \
  /bin/bash --noprofile --norc -c '. "$1"; dotfiles_open_url "https://example.test/darwin"' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities"
assert_contains "$(cat "$tmp_dir/commands.log")" 'open|https://example.test/darwin' 'Darwin URL opener uses open'
assert_not_contains "$(cat "$tmp_dir/commands.log")" 'xdg-open|' 'Darwin URL opener does not use xdg-open'

: >"$tmp_dir/commands.log"
PATH="$fake_bin:/usr/bin:/bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" DOTFILES_UNAME=Linux BROWSER=safe-browser \
  /bin/bash --noprofile --norc -c '. "$1"; dotfiles_open_url "https://example.test/browser"' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities"
assert_contains "$(cat "$tmp_dir/commands.log")" 'browser|https://example.test/browser' 'Linux URL opener honors a literal browser executable'
assert_not_contains "$(cat "$tmp_dir/commands.log")" 'open|' 'Linux URL opener never uses macOS open'

: >"$tmp_dir/commands.log"
pwned="$tmp_dir/browser-injection"
PATH="$fake_bin:/usr/bin:/bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" DOTFILES_UNAME=Linux \
  BROWSER="safe-browser; touch $pwned" \
  /bin/bash --noprofile --norc -c '. "$1"; dotfiles_open_url "https://example.test/literal"' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities"
[ ! -e "$pwned" ] || fail 'BROWSER value executed shell syntax'
assert_contains "$(cat "$tmp_dir/commands.log")" 'xdg-open|https://example.test/literal' 'unsafe BROWSER value falls back to xdg-open'

repo_dir="$tmp_dir/repository"
mkdir -p "$repo_dir"
git -C "$repo_dir" init -q
git -C "$repo_dir" symbolic-ref HEAD refs/heads/main
git -C "$repo_dir" config user.name 'Dotfiles Test'
git -C "$repo_dir" config user.email 'dotfiles@example.test'
printf 'fixture\n' >"$repo_dir/README"
git -C "$repo_dir" add README
git -C "$repo_dir" commit -qm fixture
git -C "$repo_dir" remote add origin git@github.com:example/project.git
: >"$tmp_dir/commands.log"
PATH="$fake_bin:/usr/bin:/bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" DOTFILES_UNAME=Linux BROWSER=safe-browser \
  /bin/bash --noprofile --norc -c 'cd "$1"; . "$2"; repo docs/guide.md' \
  bash "$repo_dir" "$ROOT_DIR/bash-linux/.bash/utilities"
assert_contains "$(cat "$tmp_dir/commands.log")" \
  'browser|https://github.com/example/project/tree/main/docs/guide.md' \
  'repo sends its branch URL through the portable opener'

set +e
missing_opener_error=$(PATH="$empty_bin" DOTFILES_UNAME=Linux BROWSER=missing-browser \
  /bin/bash --noprofile --norc -c '. "$1"; dotfiles_open_url "https://example.test/missing"' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities" 2>&1)
missing_opener_status=$?
set -e
[ "$missing_opener_status" -ne 0 ] || fail 'missing URL opener reported success'
assert_contains "$missing_opener_error" 'no URL opener available' 'missing URL opener has a clear error'

: >"$tmp_dir/commands.log"
PATH="$fake_bin:/usr/bin:/bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" \
  /bin/bash --noprofile --norc -c '. "$1"; timer 5' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities"
timer_log=$(cat "$tmp_dir/commands.log")
assert_contains "$timer_log" 'countdown|5' 'timer runs countdown'
assert_contains "$timer_log" 'notify|Timer is done' 'timer uses the portable desktop notifier'

timer_bin="$tmp_dir/timer-bin"
mkdir -p "$timer_bin"
cp "$fake_bin/countdown" "$timer_bin/countdown"
set +e
timer_error=$(PATH="$timer_bin" SHELL_COMMAND_LOG="$tmp_dir/commands.log" \
  /bin/bash --noprofile --norc -c '. "$1"; timer 1' \
  bash "$ROOT_DIR/bash-linux/.bash/utilities" 2>&1)
timer_status=$?
set -e
[ "$timer_status" -ne 0 ] || fail 'timer without a notifier reported success'
assert_contains "$timer_error" 'notify-send is unavailable' 'timer without a notifier has a clear error'

pass 'portable URL and timer helpers select commands safely'
