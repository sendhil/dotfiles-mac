# JankyBorders Local Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install and temporarily run JankyBorders on this Mac before any shared
runtime configuration or cross-Mac rollout.

**Architecture:** Install the upstream stable Homebrew formula, then launch one
managed process with explicit appearance options. Keep configuration files,
AeroSpace, and login services unchanged. Validate installation/process health
separately from the user's visual acceptance.

**Tech Stack:** macOS, Homebrew, JankyBorders, existing AeroSpace, Pi background
process management.

## Global Constraints

- Install the stable `felixkratz/formulae/borders` formula, not the HEAD build.
- Do not perform a general Homebrew upgrade or start a Homebrew service.
- Use `style=round width=3.0 hidpi=on ax_focus=off`.
- Use `active_color=0xff7aa2f7 inactive_color=0x00000000`.
- Do not change macOS permissions or security settings.
- Do not create `~/.config/borders/bordersrc` or change AeroSpace or window gaps.
- No push, remote-Mac commands, or autostart changes.
- Do not remove the pre-existing Homebrew tap or unrelated packages.

Execution is inline in the current session, as installation has already been
authorized. No subagents are authorized or needed. The named superpowers
execution skills in the standard header are unavailable in this installation;
execute the explicit steps below directly. No production code or runtime config
is being authored, so these are real installation/process checks rather than
application unit tests.

---

### Task 1: Install and launch the temporary trial

**Files:** No product/runtime files are created or edited. Homebrew owns its
installed formula. This plan and the design spec are local documentation only.

**Interfaces:** Consume the existing `/opt/homebrew/bin/brew` and installed tap;
produce `/opt/homebrew/bin/borders`, one managed trial task, and its process ID.

- [x] **Step 1: Confirm the pre-install baseline.**

Run `command -v borders` and `pgrep -x borders`. Both must show that Borders is
absent; if an existing process or install appears, stop and reconcile ownership
before installing/launching. Confirm that `~/.config/borders` and
`~/Library/LaunchAgents/homebrew.mxcl.borders.plist` are absent. Record SHA-256
fingerprints for `Makefile` and `aerospace/.config/aerospace/aerospace.toml`.

- [ ] **Step 2: Install only the stable formula.**

Use `bg_run` (`isAgent: false`, automatic completion notification enabled):

```sh
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 \
  brew install felixkratz/formulae/borders
```

Expected: exit 0. If installation fails, inspect the terminal output and diagnose
it before changing anything. Do not install a HEAD build or bypass security.

- [ ] **Step 3: Check the installed executable.**

```sh
brew list --versions borders
test -x /opt/homebrew/bin/borders
```

Expected: a stable version (the inspected local formula is 1.9.0), and an
executable. Do not assume undocumented `--version` or `--help` flags are safe.

- [ ] **Step 4: Launch one temporary managed process.**

Recheck `pgrep -x borders` first. If still absent, call `bg_run` with name
`Local JankyBorders trial`, `isAgent: false`, and this command:

```sh
exec /opt/homebrew/bin/borders style=round width=3.0 hidpi=on ax_focus=off \
  active_color=0xff7aa2f7 inactive_color=0x00000000
```

Record the task ID and output path returned by the tool. Leave notifications
enabled, so unexpected exit is reported automatically.

- [ ] **Step 5: Run the process and scope smoke checks.**

Run `pgrep -x borders`, then `ps -p "$(pgrep -x borders)" -o pid=,comm=,args=`;
require one matching process and the intended options. Read its startup-output
file once for errors. Do not poll background task state
or logs merely to wait. Confirm the config and login-agent paths remain absent,
the two runtime-config fingerprints are unchanged, and `git diff --check`
passes. Record the PID and a concrete stop command for the user.

### Task 2: Obtain visual acceptance before sync

**Files:** None.

**Interfaces:** Consume the running trial/PID from Task 1; produce the user's
acceptance or a specific adjustment request. No automatic rollout follows.

- [ ] **Step 1: Ask the user to test their desktop.**

Switch focus with clicks and AeroSpace shortcuts, change workspace, and use the
usual monitor setup. Confirm that the blue outline follows focus, inactive
windows have no visible outline, and borders do not obscure content or clip
unacceptably at screen edges. Do not infer rendering success from process health.

- [ ] **Step 2: Respond to acceptance or rejection.**

If accepted, ask about the later Stow/autostart rollout before implementing it.
If rejected, stop the recorded managed task with `bg_kill`, or send `kill` to its
verified PID, then check that the process exited. Uninstall with
`brew uninstall borders` only if the user requests removal of the installed
binary. Do not remove the pre-existing tap.
