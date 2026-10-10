# Herdr automatic rule updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable and publish automatic Herdr detection-rule updates using the existing Stow configuration.

**Architecture:** Change one boolean in the tracked Herdr TOML; the existing local Stow symlink makes it immediately available here. Validate the real Stow installation path in a disposable home, reload existing local servers, and publish through Git.

**Tech Stack:** TOML, Python 3.11+ standard library for validation, GNU Stow, Make, Herdr CLI, Git.

## Global Constraints

- Preserve every unrelated setting and the existing symlink.
- This enables rule checks only, not a new binary-update policy.
- Do not stop servers, recreate panes, or restart agents.
- Reload the running `default`, `jarvis`, `lanes`, and `phone` servers using their existing sockets.
- The user approved including existing unpushed merge commit `a453007` in the normal push to `origin/master`.
- Other machines apply the setting after pulling and reloading; Git itself is not being made to pull automatically.

---

### Task 1: Enable, validate, activate, and publish the shared policy

**Files:**
- Modify: `herdr/.config/herdr/config.toml` (`[update].manifest_check` only).
- Reference: `Makefile` (`stow-herdr` already exists; no edit).
- Test: temporary `check_policy.py` and `before.toml` outside the repository.

**Interfaces:**
- Consumes: existing `make stow-herdr`, Herdr `server reload-config`, and the four sockets returned by `herdr session list`.
- Produces: shared `manifest_check = true`, validated Stow installation, successful live reloads, and a commit published on `origin/master`.

- [ ] **Step 1: Snapshot the original configuration and write the focused tests.**

```sh
repo=/Users/sendhil/src/dotfiles-mac
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-auto-rules.XXXXXX")
git -C "$repo" show HEAD:herdr/.config/herdr/config.toml > "$work/before.toml"
```

Write this complete test to `$work/check_policy.py`:

```python
import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

repo = Path(sys.argv[1]).resolve()
before = tomllib.loads(Path(sys.argv[2]).read_text())
shared = repo / "herdr/.config/herdr/config.toml"
local = Path.home() / ".config/herdr/config.toml"

class HerdrPolicyTests(unittest.TestCase):
    def test_shared_policy_enables_rule_updates(self):
        current = tomllib.loads(shared.read_text())
        self.assertIs(current["update"]["manifest_check"], True)

    def test_unrelated_settings_are_preserved(self):
        expected = copy.deepcopy(before)
        expected["update"]["manifest_check"] = True
        self.assertEqual(tomllib.loads(shared.read_text()), expected)

    def test_local_stow_link_is_preserved(self):
        self.assertTrue(local.is_symlink())
        self.assertEqual(local.resolve(), shared)
        self.assertIs(tomllib.loads(local.read_text())["update"]["manifest_check"], True)

    def test_existing_make_target_installs_shared_policy(self):
        with tempfile.TemporaryDirectory(prefix="herdr-stow-test-") as target:
            env = dict(os.environ, HOME=target)
            result = subprocess.run(
                ["make", "--no-print-directory", "-C", str(repo), "stow-herdr"],
                env=env, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            installed = Path(target) / ".config/herdr/config.toml"
            self.assertEqual(installed.resolve(), shared)
            self.assertIs(tomllib.loads(installed.read_text())["update"]["manifest_check"], True)

if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]], verbosity=2)
```

- [ ] **Step 2: Run the tests against the disabled policy.**

```sh
python3 "$work/check_policy.py" "$repo" "$work/before.toml"
```

Expected: assertion failures because the actual policy is `false`, without TOML parsing, Make, or Stow errors.

- [ ] **Step 3: Change only the shared TOML value.**

Replace the exact line `manifest_check = false` with `manifest_check = true` under `[update]`, using a targeted edit on `herdr/.config/herdr/config.toml`.

- [ ] **Step 4: Rerun all four focused tests and check diagnostics.**

```sh
python3 "$work/check_policy.py" "$repo" "$work/before.toml"
git -C "$repo" diff --check
git -C "$repo" diff -- herdr/.config/herdr/config.toml
```

Expected: four passing tests and a one-line TOML change. Probe active LSP diagnostics for the changed TOML if a server is configured; explicit parsing and Herdr's reload response remain required.

- [ ] **Step 5: Reload every running local server without restarts.**

```sh
for name in default jarvis lanes phone; do
  if [ "$name" = default ]; then
    socket="$HOME/.config/herdr/herdr.sock"
  else
    socket="$HOME/.config/herdr/sessions/$name/herdr.sock"
  fi
  HERDR_SESSION="$name" HERDR_SOCKET_PATH="$socket" herdr server reload-config || exit 1
done
```

Expected: applied configuration with no errors or restart requirements. Verify server process IDs remain unchanged and inspect per-session `herdr server agent-manifests` for successful background checks; do not issue another manual manifest update as proof of automatic checking.

- [ ] **Step 6: Commit and push the scoped change and plan.**

```sh
git -C "$repo" add herdr/.config/herdr/config.toml docs/superpowers/plans/2026-10-10-herdr-auto-rule-updates.md
git -C "$repo" commit -m "fix: enable automatic Herdr detection rule updates"
git -C "$repo" push origin master
git -C "$repo" status --short --branch
git -C "$repo" ls-remote origin refs/heads/master
```

Expected: a clean working tree and the local HEAD matching the remote master hash. If the remote has advanced, inspect changes before reconciling and never force-push. Remove only the two temporary validation files and their containing directory after successful verification.
