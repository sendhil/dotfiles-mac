#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"
cd "$ROOT_DIR"

[ -f .gitmodules ] || fail 'tracked gitlinks require a .gitmodules file'

gitlink_paths=$(git ls-files --stage | awk '$1 == "160000" {print $4}' | LC_ALL=C sort)
module_entries=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null || true)
module_paths=$(printf '%s\n' "$module_entries" | awk 'NF {print $2}' | LC_ALL=C sort)

[ -n "$gitlink_paths" ] || fail 'submodule metadata test expected at least one tracked gitlink'
[ "$module_paths" = "$gitlink_paths" ] || fail "gitlink paths and .gitmodules paths differ:
gitlinks:
$gitlink_paths
.gitmodules:
$module_paths"

duplicate_paths=$(printf '%s\n' "$module_paths" | uniq -d)
[ -z "$duplicate_paths" ] || fail "duplicate .gitmodules paths:
$duplicate_paths"

printf '%s\n' "$module_entries" | while IFS=' ' read -r path_key module_path; do
  [ -n "$path_key" ] && [ -n "$module_path" ] || fail 'invalid empty submodule path entry'
  section=${path_key%.path}
  url_count=$(git config -f .gitmodules --get-all "$section.url" | awk 'END {print NR}')
  [ "$url_count" -eq 1 ] || fail "$module_path must have exactly one submodule URL"
  url=$(git config -f .gitmodules --get "$section.url")
  case $url in
    https://*/*|http://*/*|ssh://*/*|git://*/*|git@*:* ) ;;
    *) fail "$module_path has an invalid submodule URL: $url" ;;
  esac
done

set +e
submodule_status=$(git submodule status 2>&1)
submodule_rc=$?
set -e
[ "$submodule_rc" -eq 0 ] || fail "git submodule status cannot parse local metadata:
$submodule_status"

tmux_config=$(cat tmux/.tmux.conf)
assert_contains "$tmux_config" "run '~/.tmux/plugins/tpm/tpm'" \
  'tmux configuration does not initialize its plugin manager'
tpm_index_entry=$(git ls-files --stage -- tmux/.tmux/plugins/tpm/tpm)
case $tpm_index_entry in
  '100755 '*) ;;
  *) fail 'the TPM launcher must be a tracked executable regular file' ;;
esac
[ -x tmux/.tmux/plugins/tpm/tpm ] || fail 'the vendored TPM launcher is not executable in the checkout'

pass 'every gitlink has one complete, parseable submodule mapping'
