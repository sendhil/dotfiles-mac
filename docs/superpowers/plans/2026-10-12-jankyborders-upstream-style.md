# JankyBorders Upstream Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restart only the owned local trial with the README-derived rounded
neutral appearance and obtain a fresh visual check.

**Architecture:** Verify and stop the original managed process, require no
remaining Borders instance, then launch one managed process with explicit startup
arguments. Check the new PID/arguments and unchanged runtime-file fingerprints.

**Tech Stack:** Existing JankyBorders 1.9.0, macOS, Pi background task management,
shell smoke checks.

## Global Constraints

- Use `style=round width=5.0 hidpi=on ax_focus=off`.
- Use `active_color=0xffe1e3e4 inactive_color=0xff494d64`.
- Keep installed Borders 1.9.0.
- Do not create a config file, start a login service, change permissions, edit
  AeroSpace/gaps, upgrade or patch the tool, push, or touch other Macs.
- Preserve unrelated concurrent AeroSpace/Sketchybar changes.
- Stop only the verified owned original task `b0de2a0e9`, sole PID 34556.
- Sync and autostart remain deferred until visual acceptance and rollout approval.
- Do not claim an underlying renderer bug is fixed.

Execute inline; Restart trial is authorized. No delegation is authorized or
needed. The standard header's superpowers execution skills are unavailable here.
No application source or runtime configuration is authored by this operator task.

---

### Task 1: Perform a clean owned restart and startup smoke check

**Files:** Documentation only. Runtime configuration files remain untouched.

**Interfaces:** Consume original task `b0de2a0e9` / sole PID 34556 and installed
`/opt/homebrew/bin/borders`; produce one new managed trial task/PID.

- [ ] **Step 1: Verify ownership/version and capture runtime-file baselines.**

```sh
set -eu
test "$(pgrep -x borders)" = 34556
kill -0 34556
ps -ww -p 34556 -o pid=,args=
/opt/homebrew/bin/borders --version
shasum -a 256 Makefile aerospace/.config/aerospace/aerospace.toml
```

Expected: original process and `borders-v1.9.0`. The version option is safe here
because the complete version 1.9.0 startup source was inspected; it exits before
initialization. Record the two hashes for a before/after comparison.

- [ ] **Step 2: Stop only the owned original task.**

Call `bg_kill` with `taskId: "b0de2a0e9"`. Treat its old-process killed terminal
notification as an expected consequence of the authorized restart, not a failure
of the new trial. Do not inspect/poll background state merely to wait.

- [ ] **Step 3: Require absence and start one explicit reference-style process.**

Use `bg_run`, name `Upstream Borders style trial`, `isAgent: false`, with:

```sh
if pgrep -x borders >/dev/null 2>&1; then
  printf 'A Borders process remains; refusing to alter it.\n' >&2
  exit 1
fi
exec /opt/homebrew/bin/borders style=round width=5.0 hidpi=on ax_focus=off \
  active_color=0xffe1e3e4 inactive_color=0xff494d64
```

Record its new task ID, PID and output path. Leave automatic exit notifications
enabled. If it exits unexpectedly, inspect its terminal output rather than
blindly relaunching or changing settings.

- [ ] **Step 4: Check the new owned process and unchanged scope.**

Require that `pgrep -x borders` returns exactly the new task's recorded PID,
different from 34556. Check `kill -0` and `ps -ww -p` for the complete intended
startup arguments, and read the new startup-output file once for errors.
Recompute both hashes and compare to Step 1. Confirm `~/.config/borders`,
`~/Library/LaunchAgents/homebrew.mxcl.borders.plist`, and
`/Library/LaunchDaemons/homebrew.mxcl.borders.plist` remain absent. Run
`git diff --check`. Preserve unrelated changes; report a concurrent fingerprint
change rather than revert another owner's work.

- [ ] **Step 5: Record the checkpoint and request a fresh visual check.**

Record the new task/PID and technical results in this plan. Ask the user whether
the rounded neutral border now matches their reference and follows focus cleanly.
Request a fresh corner crop if the doubled/clipped edge remains. Startup health
and arguments are not visual proof.

If this third appearance is also unacceptable, stop and reassess geometry/focus
and whether JankyBorders fits the desktop rather than continue blind palettes.
On user request, stop the verified new managed task; give its actual PID as the
manual stop command. Do not uninstall without approval.
