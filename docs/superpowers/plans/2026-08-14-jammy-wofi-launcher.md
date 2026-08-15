# Jammy-Compatible Wofi Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace unavailable Fuzzel with Ubuntu 22.04's official Wofi launcher across Linux package ownership and Sway dotfiles.

**Architecture:** `linux-laptop-setup` owns the `wofi` APT package and checks its executable. `dotfiles-mac` owns one Wofi Stow package, a Tokyo Night configuration, and the unchanged `Alt+d` interface. Both repositories reject live Fuzzel references.

**Tech Stack:** Bash, APT manifests, GNU Stow, Sway, Wofi, CSS

## Global Constraints

- Use Wofi on every supported Ubuntu release.
- Add no PPA, vendor repository, source build, or version-specific launcher.
- Preserve `Alt+d` and all IT-owned boundaries.
- Preserve complete candidate validation before package-manager mutation.
- Use strict red-green-refactor and focused commits.

---

### Task 1: Make Linux package ownership Jammy-compatible

**Files:**
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/manifests/apt-sway.txt`
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/bin/doctor`
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/tests/manifest_hygiene_test.sh`
- Modify: `/Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup/tests/doctor_test.sh`

**Interfaces:**
- Consumes: normalized APT records from `read_apt_file`.
- Produces: one owned `wofi` package and command check; no supported `fuzzel` package.

- [ ] **Step 1: Write failing tests**

Change the reviewed Sway expectation and fake command set to Wofi. Add:

```bash
assert_contains "$(read_apt_file manifests/apt-sway.txt)" $'wofi\t' \
  'Sway manifest owns the Jammy-compatible Wofi launcher'
case $(read_apt_file manifests/apt-sway.txt) in
  *$'fuzzel\t'*) fail 'Sway manifest contains unavailable Fuzzel' ;;
esac
```

Require the healthy doctor output to contain `PASS command: wofi` and no
`command: fuzzel` result.

- [ ] **Step 2: Verify red**

Run `bash tests/manifest_hygiene_test.sh` and `bash tests/doctor_test.sh`.
Expected: FAIL because the manifest and doctor still declare Fuzzel.

- [ ] **Step 3: Implement minimal Linux change**

Replace `fuzzel` with `wofi` in `manifests/apt-sway.txt`, the doctor's direct
executable case list, and the doctor fixture. Do not alter apply preflight.

- [ ] **Step 4: Verify green**

Run:

```bash
bash tests/manifest_hygiene_test.sh
bash tests/doctor_test.sh
bash tests/run
bash -n bin/doctor tests/manifest_hygiene_test.sh tests/doctor_test.sh
git diff --check
```

Expected: all Linux suites pass and no live manifest contains Fuzzel.

- [ ] **Step 5: Commit**

```bash
git add manifests/apt-sway.txt bin/doctor tests/manifest_hygiene_test.sh tests/doctor_test.sh
git commit -m "fix: use Jammy-compatible Wofi launcher"
```

### Task 2: Replace the Fuzzel Stow package with Wofi

**Files:**
- Delete: `fuzzel/.config/fuzzel/fuzzel.ini`
- Delete: `fuzzel/.stow-local-ignore`
- Create: `wofi/.stow-local-ignore`
- Create: `wofi/.config/wofi/config`
- Create: `wofi/.config/wofi/style.css`
- Modify: `scripts/package-set.sh`
- Modify: `sway/.config/sway/config`
- Modify: `tests/package_sets_test.sh`
- Modify: `tests/sway_config_test.sh`
- Modify: `tests/sway_desktop_test.sh`

**Interfaces:**
- Consumes: `packages_for ubuntu` and Sway's `$menu` command.
- Produces: a `wofi` Stow package and `Alt+d` execution of Wofi in `drun` mode.

- [ ] **Step 1: Write failing tests**

Require the Ubuntu package set to contain `wofi` and reject `fuzzel`. Require:

```text
set $menu wofi --show drun
bindsym $mod+d exec $menu
```

Require `wofi/.config/wofi/config`, `wofi/.config/wofi/style.css`, Tokyo Night
background `#1a1b26`, and no selected Fuzzel package.

- [ ] **Step 2: Verify red**

Run the package-set, Sway-config, and Sway-desktop focused tests. Expected:
FAIL because the package, files, and binding still use Fuzzel.

- [ ] **Step 3: Implement the Wofi package**

Create this config:

```ini
show=drun
width=50%
height=40%
allow_images=true
image_size=24
prompt=Search applications
term=kitty
insensitive=true
```

Create a stylesheet with `#1a1b26` background, `#7aa2f7` border,
`#33467c` selection, `#c0caf5` text, `#ff9e64` selected text, and
JetBrainsMono Nerd Font with a monospace fallback. Replace the package-set
entry, remove tracked Fuzzel configuration, and update the exact Sway lines.

- [ ] **Step 4: Verify green**

Run:

```bash
bash tests/package_sets_test.sh
bash tests/sway_config_test.sh
bash tests/sway_desktop_test.sh
bash tests/stow_integration_test.sh
bash tests/run
git diff --check
```

Expected: all tests pass and isolated Ubuntu Stow links Wofi.

- [ ] **Step 5: Commit**

```bash
git add scripts/package-set.sh sway wofi fuzzel tests
git commit -m "fix: replace Fuzzel with Wofi on Ubuntu"
```

### Task 3: Update documentation and publish

**Files:**
- Modify: `README.md`
- Modify: `docs/ubuntu-first-login.md`
- Modify: `tests/docs_test.sh`

**Interfaces:**
- Consumes: the Wofi package and unchanged `Alt+d` interface.
- Produces: supported laptop instructions naming Wofi.

- [ ] **Step 1: Write failing docs test**

Require README and checklist to mention Wofi and `Alt+d`, and reject Fuzzel
from supported documentation.

- [ ] **Step 2: Verify red**

Run `bash tests/docs_test.sh`. Expected: FAIL on current Fuzzel wording.

- [ ] **Step 3: Update docs**

Replace supported Fuzzel references with Wofi and state that Wofi comes from
the official Ubuntu archive. Add no manual installer or PPA instruction.

- [ ] **Step 4: Final validation**

Run both complete repository suites, relevant Bash syntax checks, real Stow
integration, and `git diff --check`. Confirm only `.nvimlog` remains untracked
in the dotfiles worktree.

- [ ] **Step 5: Commit and push**

```bash
git add README.md docs/ubuntu-first-login.md tests/docs_test.sh
git commit -m "docs: document Wofi launcher on Ubuntu"
git push
git -C /Users/sendhil/src/linux-laptop-setup/.worktrees/ubuntu-cross-platform-setup push
```

Expected: both remote `ubuntu-cross-platform-setup` branches contain the
Jammy-compatible Wofi change.
