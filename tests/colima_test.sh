#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fake_bin="$tmp_dir/fake bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/colima" <<'FAKE_COLIMA'
#!/bin/sh

{
  printf 'colima'
  for arg do
    printf ' <%s>' "$arg"
  done
  printf '\n'
} >>"$COLIMA_LOG"

command_name=${1-}
case $command_name in
  list)
    printf '%s\n' 'PROFILE STATUS ARCH CPUS MEMORY DISK RUNTIME ADDRESS'
    if [ "${COLIMA_PROFILE_PRESENT:-1}" -eq 1 ]; then
      printf '%s\n' 'neovim-dev Running aarch64 2 4GiB 20GiB docker 127.0.0.1'
    fi
    ;;
  ssh)
    shift
    [ "${1-}" = -p ] || exit 91
    [ "${2-}" = neovim-dev ] || exit 92
    shift 2
    if [ "${1-}" = -- ]; then
      shift
      if [ "$#" -eq 3 ] && [ "$1" = command ] && [ "$2" = -v ] && [ "$3" = nvim ]; then
        exit "${COLIMA_NVIM_STATUS:-0}"
      fi
      if [ "$#" -eq 3 ] && [ "$1" = test ] && [ "$2" = -d ] && \
        [ "$3" = /home/dotfiles/neovim/.config/nvim ]; then
        exit "${COLIMA_MOUNT_STATUS:-0}"
      fi
      if [ "$#" -eq 4 ] && [ "$1" = sh ] && [ "$2" = -eu ] && [ "$3" = -c ]; then
        HOME="$COLIMA_GUEST_HOME" /bin/sh -eu -c "$4"
        exit $?
      fi
      exit 93
    fi
    [ "$#" -eq 0 ] || exit 97
    cat >"$COLIMA_GUEST_CONFIG_LOG"
    printf '%s\n' guest-config >>"$COLIMA_MUTATION_LOG"
    HOME="$COLIMA_GUEST_HOME" PATH="$COLIMA_GUEST_BIN:/usr/bin:/bin" \
      /bin/sh "$COLIMA_GUEST_CONFIG_LOG"
    ;;
  start|stop|delete)
    printf '%s\n' "$command_name" >>"$COLIMA_MUTATION_LOG"
    ;;
  *)
    exit 98
    ;;
esac
FAKE_COLIMA

chmod +x "$fake_bin/colima"

guest_bin="$tmp_dir/guest bin"
mkdir -p "$guest_bin"
cat >"$guest_bin/nvim" <<'FAKE_NVIM'
#!/bin/sh
printf '%s\n' nvim >>"$COLIMA_MUTATION_LOG"
exit "${COLIMA_GUEST_NVIM_STATUS:-0}"
FAKE_NVIM
chmod +x "$guest_bin/nvim"

setup_script="$ROOT_DIR/scripts/setup-colima-neovim.sh"
absent_home="$tmp_dir/absent guest home"
mkdir -p "$absent_home"
: >"$tmp_dir/absent colima log"
: >"$tmp_dir/absent mutation log"
: >"$tmp_dir/absent guest config"
set +e
absent_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$absent_home" \
  COLIMA_LOG="$tmp_dir/absent colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/absent mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/absent guest config" \
  COLIMA_PROFILE_PRESENT=0 \
  "$setup_script" 2>&1)
absent_status=$?
set -e
[ "$absent_status" -ne 0 ] || fail 'Colima setup created a guest owned by external provisioning'
assert_contains "$absent_output" pre-provisioned \
  'absent-profile error does not explain the external ownership boundary'
[ ! -s "$tmp_dir/absent mutation log" ] || \
  fail 'absent Colima profile triggered lifecycle or guest mutation'
[ ! -e "$absent_home/.local/bin/colima-nvim" ] || \
  fail 'absent Colima profile installed a local helper'

readme=$(cat "$ROOT_DIR/README.md")
assert_contains "$readme" 'pre-provisioned `neovim-dev`' \
  'README does not state the Colima guest ownership prerequisite'
assert_contains "$readme" '/home/dotfiles' \
  'README does not document the required dotfiles guest mount'

missing_home="$tmp_dir/missing nvim home"
mkdir -p "$missing_home"
: >"$tmp_dir/missing colima log"
: >"$tmp_dir/missing mutation log"
: >"$tmp_dir/missing guest config"
set +e
missing_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$missing_home" \
  COLIMA_LOG="$tmp_dir/missing colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/missing mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/missing guest config" \
  COLIMA_NVIM_STATUS=1 \
  "$setup_script" 2>&1)
missing_status=$?
set -e
[ "$missing_status" -ne 0 ] || fail 'Colima setup accepted a guest without Neovim'
assert_contains "$missing_output" neovim-dev 'missing-prerequisite error does not name the expected guest'
assert_contains "$missing_output" nvim 'missing-prerequisite error does not name Neovim'
assert_contains "$missing_output" pre-provisioned \
  'missing-prerequisite error does not explain the external ownership boundary'
[ ! -s "$tmp_dir/missing mutation log" ] || \
  fail 'missing guest Neovim triggered Colima or guest mutation'
[ ! -e "$missing_home/.local/bin/colima-nvim" ] || \
  fail 'missing guest Neovim installed a local helper before preflight passed'

missing_mount_home="$tmp_dir/missing mount home"
mkdir -p "$missing_mount_home"
: >"$tmp_dir/missing mount colima log"
: >"$tmp_dir/missing mount mutation log"
: >"$tmp_dir/missing mount guest config"
set +e
missing_mount_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$missing_mount_home" \
  COLIMA_LOG="$tmp_dir/missing mount colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/missing mount mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/missing mount guest config" \
  COLIMA_NVIM_STATUS=0 COLIMA_MOUNT_STATUS=1 \
  "$setup_script" 2>&1)
missing_mount_status=$?
set -e
[ "$missing_mount_status" -ne 0 ] || fail 'Colima setup accepted a guest without its dotfiles mount'
assert_contains "$missing_mount_output" /home/dotfiles \
  'missing-mount error does not name the required guest mount'
[ ! -s "$tmp_dir/missing mount mutation log" ] || \
  fail 'missing dotfiles guest mount triggered Colima or guest mutation'
[ ! -e "$missing_mount_home/.local/bin/colima-nvim" ] || \
  fail 'missing dotfiles guest mount installed a local helper before preflight passed'

local_conflict_home="$tmp_dir/local conflict home"
local_conflict_guest="$tmp_dir/local conflict guest"
mkdir -p "$local_conflict_home/.local/bin" "$local_conflict_guest"
printf '%s\n' 'preserve this file' >"$tmp_dir/helper sentinel"
ln -s "$tmp_dir/helper sentinel" "$local_conflict_home/.local/bin/colima-nvim"
: >"$tmp_dir/local conflict colima log"
: >"$tmp_dir/local conflict mutation log"
: >"$tmp_dir/local conflict guest config"
set +e
local_conflict_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$local_conflict_home" \
  COLIMA_LOG="$tmp_dir/local conflict colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/local conflict mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/local conflict guest config" \
  COLIMA_GUEST_HOME="$local_conflict_guest" COLIMA_GUEST_BIN="$guest_bin" \
  "$setup_script" 2>&1)
local_conflict_status=$?
set -e
[ "$local_conflict_status" -ne 0 ] || fail 'Colima setup overwrote a symlinked local helper destination'
[ "$(cat "$tmp_dir/helper sentinel")" = 'preserve this file' ] || \
  fail 'Colima setup followed and overwrote a local helper symlink'
[ ! -s "$tmp_dir/local conflict mutation log" ] || \
  fail 'local helper conflict was detected after guest mutation'
assert_contains "$local_conflict_output" colima-nvim \
  'local helper conflict error does not name its destination'

guest_parent_conflict_home="$tmp_dir/guest parent conflict home"
guest_parent_conflict_guest="$tmp_dir/guest parent conflict guest"
mkdir -p "$guest_parent_conflict_home/.local/bin" "$guest_parent_conflict_guest"
printf '%s\n' keep >"$guest_parent_conflict_guest/.config"
: >"$tmp_dir/guest parent conflict colima log"
: >"$tmp_dir/guest parent conflict mutation log"
: >"$tmp_dir/guest parent conflict guest config"
set +e
guest_parent_conflict_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$guest_parent_conflict_home" \
  COLIMA_LOG="$tmp_dir/guest parent conflict colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/guest parent conflict mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/guest parent conflict guest config" \
  COLIMA_GUEST_HOME="$guest_parent_conflict_guest" COLIMA_GUEST_BIN="$guest_bin" \
  "$setup_script" 2>&1)
guest_parent_conflict_status=$?
set -e
[ "$guest_parent_conflict_status" -ne 0 ] || \
  fail 'Colima setup accepted a conflicting guest ~/.config parent'
[ "$(cat "$guest_parent_conflict_guest/.config")" = keep ] || \
  fail 'guest parent conflict preflight damaged existing state'
[ ! -s "$tmp_dir/guest parent conflict mutation log" ] || \
  fail 'guest parent conflict was detected after guest mutation'
[ ! -e "$guest_parent_conflict_home/.local/bin/colima-nvim" ] || \
  fail 'guest parent conflict installed the local helper'
assert_contains "$guest_parent_conflict_output" '.config' \
  'guest parent conflict error does not name its destination'

guest_conflict_home="$tmp_dir/guest conflict home"
guest_conflict_guest="$tmp_dir/guest conflict guest"
mkdir -p "$guest_conflict_home/.local/bin" "$guest_conflict_guest/.config/nvim"
printf '%s\n' keep >"$guest_conflict_guest/.config/nvim/user-file"
: >"$tmp_dir/guest conflict colima log"
: >"$tmp_dir/guest conflict mutation log"
: >"$tmp_dir/guest conflict guest config"
set +e
guest_conflict_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$guest_conflict_home" \
  COLIMA_LOG="$tmp_dir/guest conflict colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/guest conflict mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/guest conflict guest config" \
  COLIMA_GUEST_HOME="$guest_conflict_guest" COLIMA_GUEST_BIN="$guest_bin" \
  "$setup_script" 2>&1)
guest_conflict_status=$?
set -e
[ "$guest_conflict_status" -ne 0 ] || fail 'Colima setup accepted a conflicting guest Neovim directory'
[ -f "$guest_conflict_guest/.config/nvim/user-file" ] || \
  fail 'guest conflict preflight damaged the existing Neovim directory'
[ ! -s "$tmp_dir/guest conflict mutation log" ] || \
  fail 'guest destination conflict was detected after guest mutation'
[ ! -e "$guest_conflict_home/.local/bin/colima-nvim" ] || \
  fail 'guest destination conflict installed the local helper'
assert_contains "$guest_conflict_output" '.config/nvim' \
  'guest destination conflict error does not name its destination'

nvim_failure_home="$tmp_dir/nvim failure home"
nvim_failure_guest="$tmp_dir/nvim failure guest"
mkdir -p "$nvim_failure_home/.local/bin" "$nvim_failure_guest"
: >"$tmp_dir/nvim failure colima log"
: >"$tmp_dir/nvim failure mutation log"
: >"$tmp_dir/nvim failure guest config"
set +e
nvim_failure_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$nvim_failure_home" \
  COLIMA_LOG="$tmp_dir/nvim failure colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/nvim failure mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/nvim failure guest config" \
  COLIMA_GUEST_HOME="$nvim_failure_guest" COLIMA_GUEST_BIN="$guest_bin" \
  COLIMA_GUEST_NVIM_STATUS=47 \
  "$setup_script" 2>&1)
nvim_failure_status=$?
set -e
[ "$nvim_failure_status" -eq 47 ] || \
  fail "guest Neovim failure status was not propagated (got $nvim_failure_status)"
[ ! -e "$nvim_failure_home/.local/bin/colima-nvim" ] || \
  fail 'guest Neovim failure installed the local helper'
assert_not_contains "$nvim_failure_output" 'Colima VM setup complete' \
  'guest Neovim failure reported false overall success'
assert_not_contains "$nvim_failure_output" 'VM setup complete' \
  'guest Neovim failure reported false guest success'

configured_home="$tmp_dir/configured guest home"
configured_guest="$tmp_dir/configured guest"
mkdir -p "$configured_home/.local/bin" "$configured_guest"
: >"$tmp_dir/configured colima log"
: >"$tmp_dir/configured mutation log"
: >"$tmp_dir/configured guest config"
configured_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$configured_home" \
  COLIMA_LOG="$tmp_dir/configured colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/configured mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/configured guest config" \
  COLIMA_GUEST_HOME="$configured_guest" COLIMA_GUEST_BIN="$guest_bin" \
  COLIMA_NVIM_STATUS=0 \
  "$setup_script" 2>&1)

if grep -Eq '^(start|stop|delete)$' "$tmp_dir/configured mutation log"; then
  fail 'configured existing Colima guest was stopped, deleted, or recreated'
fi
[ "$(cat "$tmp_dir/configured mutation log")" = "guest-config
nvim" ] || \
  fail 'configured guest did not proceed to Neovim configuration'
guest_config=$(cat "$tmp_dir/configured guest config")
assert_contains "$guest_config" \
  'ln -s /home/dotfiles/neovim/.config/nvim "$destination"' \
  'configured guest did not link the mounted Neovim configuration'
[ "$(readlink "$configured_guest/.config/nvim")" = /home/dotfiles/neovim/.config/nvim ] || \
  fail 'configured guest did not create the exact intended Neovim symlink'
[ -x "$configured_home/.local/bin/colima-nvim" ] || \
  fail 'configured guest did not install the local Colima helper'
helper=$(cat "$configured_home/.local/bin/colima-nvim")
if printf '%s\n' "$helper" | grep -Eq \
  '(^|[[:space:]|])(start|stop|delete)([[:space:]|)]|$)|colima[[:space:]]+(start|stop|delete)'; then
  fail 'generated helper exposes Colima lifecycle ownership'
fi
assert_contains "$helper" 'set -eu' 'generated helper does not fail closed'
assert_contains "$helper" 'profile_running' \
  'generated helper does not preflight the exact running profile'
assert_contains "$helper" 'colima ssh -p "$VM_NAME"' \
  'generated helper does not attach to the exact provisioned profile'
assert_contains "$configured_output" 'Colima VM setup complete' \
  'configured guest did not report successful completion'

configured_calls=$(cat "$tmp_dir/configured colima log")
assert_contains "$configured_calls" 'colima <list>' 'Colima setup did not inspect existing profiles'
assert_contains "$configured_calls" \
  'colima <ssh> <-p> <neovim-dev> <--> <command> <-v> <nvim>' \
  'Colima setup did not preflight guest Neovim with literal arguments'
assert_contains "$configured_calls" \
  'colima <ssh> <-p> <neovim-dev> <--> <test> <-d> </home/dotfiles/neovim/.config/nvim>' \
  'Colima setup did not preflight its required guest mount with literal arguments'
assert_contains "$configured_calls" \
  'colima <ssh> <-p> <neovim-dev> <--> <sh> <-eu> <-c>' \
  'Colima setup did not run a read-only guest destination preflight'
if printf '%s\n' "$configured_calls" | grep -Eq \
  'colima <(start|stop|delete)>|<--force>'; then
  fail 'Colima setup contains a destructive existing-profile lifecycle'
fi

pass 'Colima setup preserves provisioned guests and preflights Neovim before mutation'
