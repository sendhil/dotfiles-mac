# JankyBorders Omarchy Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the selected Omarchy-inspired amber appearance to the existing
local trial, then obtain visual feedback before syncing.

**Architecture:** Send one documented JankyBorders runtime update to the owned
primary process. Keep installation, runtime config files, AeroSpace and startup
unchanged. Separate command/process checks from user-visible rendering checks.

**Tech Stack:** JankyBorders 1.9.0, macOS, shell smoke checks, existing managed
trial `b0de2a0e9`.

## Global Constraints

- Use `style=square width=4.0 hidpi=on ax_focus=off`.
- Use `active_color=0xffe68e0d inactive_color=0xaa595959`.
- Do not create a config file, enable a service, edit AeroSpace, change permissions,
  install another package, push, or run commands on other Macs.
- Preserve unrelated concurrent AeroSpace/Sketchybar edits in the working tree.
- Stop and reconcile if the sole owned primary process is no longer PID 34556.
- A runtime IPC update does not change the primary process's startup command line.
- Sync and autostart remain deferred until the user accepts the appearance and
  approves the later rollout.

Execute inline, as the user authorized Apply now. No delegation is authorized or
needed; the superpowers execution skills in the standard header are unavailable
here. No application code or config file is authored by this operator task.

---

### Task 1: Send and smoke-test the approved appearance update

**Files:** Documentation only. No runtime files created or edited.

**Interfaces:** Consume `/opt/homebrew/bin/borders` and sole owned PID 34556;
produce a successful update request and the same living primary process.

- [x] **Step 1: Confirm the user-approved appearance and preflight.**

The user reported the blue trial hard to see, chose Amber outline, and approved
`docs/superpowers/specs/2026-10-12-jankyborders-omarchy-style-design.md` with
Apply now. The current process preflight shows sole PID 34556 with original
startup arguments. Repeat the ownership check immediately before the update.

- [x] **Step 2: Run one guarded update and technical smoke checks.**

From `/Users/sendhil/src/dotfiles-mac`, execute this as one shell command:

```sh
set -eu
pid="$(pgrep -x borders)"
if [ "$pid" != 34556 ]; then
  printf 'Unexpected Borders ownership: %s\n' "$pid" >&2
  exit 1
fi
kill -0 "$pid"
test -x /opt/homebrew/bin/borders
make_before="$(shasum -a 256 Makefile)"
aero_before="$(shasum -a 256 aerospace/.config/aerospace/aerospace.toml)"

printf 'Sending square/4-point/amber/gray runtime update.\n'
/opt/homebrew/bin/borders style=square width=4.0 hidpi=on ax_focus=off \
  active_color=0xffe68e0d inactive_color=0xaa595959
printf 'Update command returned 0.\n'

test "$(pgrep -x borders)" = "$pid"
kill -0 "$pid"
test "$(shasum -a 256 Makefile)" = "$make_before"
test "$(shasum -a 256 aerospace/.config/aerospace/aerospace.toml)" = "$aero_before"
for p in "$HOME/.config/borders" \
  "$HOME/Library/LaunchAgents/homebrew.mxcl.borders.plist" \
  /Library/LaunchDaemons/homebrew.mxcl.borders.plist; do
  if test -e "$p" || test -L "$p"; then
    printf 'Unexpected Borders config/service path: %s\n' "$p" >&2
    exit 1
  fi
done
git diff --check
printf 'Same primary PID %s; technical smoke checks passed.\n' "$pid"
printf '%s\n%s\n' "$make_before" "$aero_before"
```

Expected: command exit 0, no update errors, same primary process, unchanged
runtime-file fingerprints, no Borders config/login agent. If any check fails,
inspect and reconcile; do not revert unrelated concurrent edits or assume the
new appearance rendered correctly. `ps` will still show the old startup colors.

- [ ] **Step 3: Record the checkpoint and request desktop acceptance.**

Record the request result and process identity in this plan. Ask whether the
amber outline is clearly visible and follows focus when switching windows and
workspaces. Rendering, contrast and clipping remain unverified until user
feedback; command success is not visual acceptance.

If the user wants rollback, guard sole ownership again and restore:

```sh
/opt/homebrew/bin/borders style=round width=3.0 hidpi=on ax_focus=off \
  active_color=0xff7aa2f7 inactive_color=0x00000000
```

Alternatively, stop the verified owned trial with `bg_kill` for `b0de2a0e9` or
`kill 34556` after confirming identity. Do not uninstall without a user request.

## Execution checkpoint: 2026-10-12

The guarded update returned 0 without errors. The original sole Borders primary
PID 34556 remained alive; its managed task is still `b0de2a0e9`. Requested live
appearance is square, 4.0 points, active `0xffe68e0d`, inactive `0xaa595959`,
with `hidpi=on` and `ax_focus=off` preserved. Startup arguments are not a query of
this newly requested runtime appearance.

Makefile SHA-256 remained
`36caa35c019890731f4cf5144b0865181946c7f31bf1a9c7b6ae2d6482c4b37b`;
AeroSpace SHA-256 remained
`6515e37c829b8ea8189e90a8d9c1a66b963a6be1bb6160c783b117a88bca9fa2`.
The latter includes unrelated concurrent AeroSpace/Sketchybar changes that this
update preserved. No Borders config or login agent appeared; diff checks passed.

Desktop acceptance is pending. No cross-Mac, startup, security or installation
changes were made by this appearance update.
