# Ubuntu Laptop Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the obsolete Ubuntu install scripts with a tested, additive `bootstrap`/`audit`/`apply`/`doctor` workflow for a workplace-managed Ubuntu laptop.

**Architecture:** `linux-laptop-setup` will use reviewed line manifests, small shared Bash libraries, and command-specific entry points. APT owns system and Sway packages, npm and uv are optional user-scoped managers, and external workplace assumptions are diagnostic-only. Tests run every command against isolated fake managers so destructive or IT-owned actions are observable.

**Tech Stack:** Bash, APT/dpkg, npm, uv, shell integration tests, ShellCheck

## Global Constraints

- Work in `/Users/sendhil/src/linux-laptop-setup`; preserve the user's untracked `.DS_Store`, `fedora/.DS_Store`, and `ALTERNATE_README.md`.
- Keep `pre-modernization-2026-08-11` resolving to `98c6248d673755db2888b6ac217323e0a4cf3fec`.
- Accept Ubuntu detected through `/etc/os-release`; reject other distributions before mutation.
- Audit is read-only. Apply and bootstrap are additive and never remove or upgrade software.
- Never install or configure Slack, Zoom, container/Kubernetes runtimes, GPU drivers, VPNs, security agents, or workplace services.
- Do not seed manifests from the historical Ubuntu or Fedora package lists.
- Do not add PPAs, execute remote shell scripts, or compile desktop components from source.
- Sway and companions come from the Ubuntu release's configured APT repositories.
- Exit `0` means success, `1` means declared drift or a failed owned doctor check, and `2` means invalid input/configuration, unsupported platform, unavailable manager, or inventory failure.
- Use red-green-refactor and one focused commit per task.

---

## Planned file map

- `lib/common.sh`: manifest normalization, validation, profile loading, and output helpers.
- `lib/platform.sh`: Ubuntu, architecture, GPU, and privilege detection without mutation.
- `lib/inventory.sh`: read-only APT, npm, uv, and external-command inventory.
- `bin/bootstrap`, `bin/audit`, `bin/apply`, `bin/doctor`: public commands.
- `manifests/*.txt`, `profiles/work.*.txt`: reviewed desired state and diagnostic-only assumptions.
- `tests/*.sh`: isolated fake-manager integration tests; `tests/run` is the entry point.
- `README.md`, `docs/first-sway-login.md`: supported workflow and physical smoke checklist.

### Task 1: Manifest and platform foundation

**Files:**
- Create: `lib/common.sh`
- Create: `lib/platform.sh`
- Create: `manifests/apt-common.txt`
- Create: `manifests/apt-sway.txt`
- Create: `manifests/npm.txt`
- Create: `manifests/uv-tools.txt`
- Create: `profiles/work.apt.txt`
- Create: `profiles/work.external.txt`
- Create: `tests/test_helper.sh`
- Create: `tests/common_test.sh`
- Create: `tests/platform_test.sh`
- Create: `tests/manifest_hygiene_test.sh`
- Create: `tests/run`

**Interfaces:**
- Produces `validate_profile PROFILE`, `read_lines FILE`, `read_apt_file FILE`, `load_apt_requirements PROFILE`, `load_external_assumptions PROFILE`, `validate_tool_id TYPE ID`, `append_line VALUES VALUE`, `print_section TITLE VALUES`, `load_ubuntu_info FILE`, `detect_arch`, `graphics_summary`, and `has_sudo`.
- `read_apt_file` prints `PACKAGE<TAB>MIN_VERSION`; the version column is empty when no floor is declared.
- `load_external_assumptions` prints `command<TAB>NAME`.

- [ ] **Step 1: Write failing helper tests**

Create `tests/test_helper.sh`:

```bash
#!/bin/bash
fail() { printf 'not ok - %s\n' "$1" >&2; return 1; }
assert_eq() {
  expected=$1 actual=$2 description=$3
  [ "$expected" = "$actual" ] || fail "$description (expected '$expected', got '$actual')"
}
assert_status() {
  expected=$1; shift
  set +e
  "$@"
  actual=$?
  set -e
  [ "$expected" -eq "$actual" ] || fail "expected status $expected, got $actual: $*"
}
assert_contains() { case $1 in *"$2"*) : ;; *) fail "$3 (missing '$2')" ;; esac; }
```

In `tests/common_test.sh`, create a temporary profile and assert that comments/blanks/duplicates normalize, `neovim 0.9.0` becomes a tab-separated record, `libfoo:amd64 1.2.0` is valid, unsafe whitespace or shell punctuation exits `2`, and a profile requires both files.

In `tests/platform_test.sh`, inject this fixture through `load_ubuntu_info`:

```text
ID=ubuntu
VERSION_ID="24.04"
VERSION_CODENAME=noble
```

Assert exported values `ubuntu`, `24.04`, and `noble`; a Debian fixture must exit `2`.

- [ ] **Step 2: Run tests to verify red**

```bash
bash tests/common_test.sh
bash tests/platform_test.sh
```

Expected: both fail because the libraries do not exist.

- [ ] **Step 3: Implement shared contracts**

Implement these core functions in `lib/common.sh`; do not use `eval`:

```bash
sorted_unique() {
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' -e '/^#/d' | LC_ALL=C sort -u
}
read_lines() { sorted_unique <"$1"; }
validate_profile() {
  profile=$1
  [ -f "profiles/$profile.apt.txt" ] && [ -f "profiles/$profile.external.txt" ] && return 0
  printf 'error: unknown profile: %s\n' "$profile" >&2
  return 2
}
validate_apt_entry() {
  line=$1
  set -- $line
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || return 2
  case $1 in ''|*[!a-z0-9+.-:]*|:*|*:) return 2 ;; esac
  if [ "$#" -eq 2 ]; then case $2 in ''|*[!A-Za-z0-9.+:~_-]*) return 2 ;; esac; fi
  printf '%s\t%s\n' "$1" "${2:-}"
}
read_apt_file() {
  read_lines "$1" | while IFS= read -r line; do validate_apt_entry "$line" || exit 2; done | LC_ALL=C sort -u
}
load_apt_requirements() {
  profile=$1
  validate_profile "$profile" || return 2
  { read_apt_file manifests/apt-common.txt; read_apt_file manifests/apt-sway.txt; read_apt_file "profiles/$profile.apt.txt"; } | LC_ALL=C sort -u
}
```

Implement `lib/platform.sh` with `load_ubuntu_info`, using `sed` rather than sourcing the file, `detect_arch` via `dpkg --print-architecture`, `has_sudo` via `command -v sudo`, and `graphics_summary` via read-only `lspci -nnk` when available.

- [ ] **Step 4: Add conservative manifests and hygiene tests**

Use this exact `apt-common` set:

```text
bash-completion
bat
build-essential
ca-certificates
curl
direnv
fd-find
fzf
git
jq
kitty
neovim 0.9.0
pipx
python3
ripgrep
shellcheck
stow
tmux
tree
zoxide
zsh
```

Use this exact `apt-sway` set:

```text
blueman
brightnessctl
dbus-user-session
fuzzel
grim
libnotify-bin
mako-notifier
network-manager-gnome
pipewire
playerctl
policykit-1-gnome
slurp
sway
swayidle
swaylock
waybar
wireplumber
wl-clipboard
xdg-desktop-portal
xdg-desktop-portal-gtk
xdg-desktop-portal-wlr
xwayland
```

Leave npm, uv, and work APT manifests empty except comments. Put only these records in `profiles/work.external.txt`:

```text
command docker
command kubectl
command slack
command zoom
```

`tests/manifest_hygiene_test.sh` must reject `slack`, `zoom`, `docker`, `containerd`, `kubelet`, and `minikube` from every APT manifest and verify normalized uniqueness.

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/run
bash -n lib/common.sh lib/platform.sh tests/*.sh
git diff --check
git add lib manifests profiles tests
git commit -m "feat: add Ubuntu setup manifest foundation"
```

Expected: tests pass and syntax/diff checks are silent.

### Task 2: Read-only audit and inventories

**Files:**
- Create: `lib/inventory.sh`
- Create: `bin/audit`
- Create: `tests/audit_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Consumes Task 1 functions.
- Produces `apt_installed_version PACKAGE`, `apt_candidate_version PACKAGE`, `npm_inventory`, `uv_inventory`, `external_command_state NAME`, and `bin/audit PROFILE`.

- [ ] **Step 1: Write failing fake-manager cases**

In a temporary copied repository, prepend `fake-bin` and inject `SETUP_OS_RELEASE`. Test:

- exact state exits `0` with empty `Missing` and `Incompatible`;
- missing declared `tree` exits `1`, while an unrelated installed package never appears;
- Neovim `0.8.3` against `0.9.0` exits `1` and prints installed/required versions;
- a candidate below the floor prints `no automatic vendor substitution configured`;
- missing Slack appears as an external assumption without owned drift;
- a needed unavailable npm or uv manager exits `2`;
- repository and fake-home checksums do not change.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/audit_test.sh`.

Expected: FAIL because `bin/audit` and `lib/inventory.sh` do not exist.

- [ ] **Step 3: Implement inventories**

```bash
apt_installed_version() {
  dpkg-query -W -f='${db:Status-Abbrev}\t${Version}\n' "$1" 2>/dev/null | sed -n 's/^ii[[:space:]]*\t//p'
}
apt_candidate_version() {
  apt-cache policy "$1" 2>/dev/null | sed -n 's/^[[:space:]]*Candidate:[[:space:]]*//p'
}
npm_inventory() {
  npm_config_update_notifier=false npm_config_audit=false npm list --global --depth=0 --parseable 2>/dev/null | sed -n 's|^.*node_modules/||p'
}
uv_inventory() {
  UV_NO_CACHE=1 UV_NO_PROGRESS=1 uv tool list 2>/dev/null | sed -n '/^[^[:space:]-]/ { s/[[:space:]].*$//; p; }'
}
external_command_state() { command -v "$1" >/dev/null 2>&1; }
```

- [ ] **Step 4: Implement stable audit output**

Print sections in this order:

```text
Platform
Missing
Incompatible
Substitutions
External assumptions
Manager errors
Suggested actions
```

Compare floors with `dpkg --compare-versions`. Query npm or uv only when its manifest is non-empty. Missing/incompatible owned requirements exit `1`; manager/inventory/platform errors exit `2`; external absences are informational.

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/audit_test.sh
bash tests/run
bash -n bin/audit lib/inventory.sh
git diff --check
git add bin/audit lib/inventory.sh tests/audit_test.sh tests/run
git commit -m "feat: add read-only Ubuntu software audit"
```

### Task 3: Additive apply

**Files:**
- Create: `bin/apply`
- Replace: `install-software.sh`
- Create: `tests/apply_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Consumes normalized manifests and Task 2 inventories.
- Produces `bin/apply PROFILE`; `install-software.sh PROFILE` delegates exactly to it.

- [ ] **Step 1: Write failing apply cases**

Record fake `sudo`, `apt-get`, `dpkg-query`, `apt-cache`, `npm`, and `uv` calls. Assert one APT metadata update when work exists, individual missing installs, no reinstall of satisfied items, optional npm/uv installs, safe rerun, and complete preflight. Reject an unsafe ID, unavailable needed manager, insufficient candidate, and unavailable `sudo` before any mutation. Assert logs contain none of `remove`, `purge`, `autoremove`, `upgrade`, `dist-upgrade`, `full-upgrade`, `slack`, or `zoom`.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/apply_test.sh`.

Expected: FAIL because `bin/apply` does not exist.

- [ ] **Step 3: Implement validation-before-mutation**

Build complete `apt_missing`, `npm_missing`, and `uv_missing` newline sets first. After all validation, use only:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends "$package"
npm_config_update_notifier=false npm_config_audit=false npm install --global "$package"
UV_NO_PROGRESS=1 uv tool install "$package"
```

Update APT once only when needed. Stop on first failed install with exit `1`. Never load or act on external assumptions during apply.

- [ ] **Step 4: Replace compatibility wrapper**

```bash
#!/bin/bash
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ "$#" -eq 1 ] || { printf 'usage: %s PROFILE\n' "$0" >&2; exit 2; }
exec "$SCRIPT_DIR/bin/apply" "$1"
```

- [ ] **Step 5: Verify green and commit**

```bash
bash tests/apply_test.sh
bash tests/run
bash -n bin/apply install-software.sh
git diff --check
git add bin/apply install-software.sh tests/apply_test.sh tests/run
git commit -m "feat: add additive Ubuntu software apply"
```

### Task 4: Minimal bootstrap

**Files:**
- Create: `bin/bootstrap`
- Replace: `init/ubuntu.sh`
- Create: `tests/bootstrap_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Consumes platform and APT inventory helpers.
- Produces `bin/bootstrap`; `init/ubuntu.sh` becomes a local deprecation wrapper.

- [ ] **Step 1: Write failing bootstrap cases**

Assert:

- Ubuntu version, codename, architecture, and read-only GPU summary are printed;
- the exact prerequisite set is `ca-certificates git`;
- APT metadata updates only when one is missing;
- both installed means no `sudo` requirement and no APT call;
- non-Ubuntu exits `2` before mutation;
- missing privilege prints the exact manual command;
- logs contain no `curl`, `git clone`, driver command, or service action.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/bootstrap_test.sh`.

Expected: FAIL because `bin/bootstrap` does not exist.

- [ ] **Step 3: Implement minimal bootstrap**

Use `SETUP_OS_RELEASE=${SETUP_OS_RELEASE:-/etc/os-release}`. Check `ca-certificates` and `git` through `apt_installed_version`. If missing, require `sudo`, run one update, and install each missing item with `--no-install-recommends`. Print `graphics_summary` but never mutate drivers.

Replace `init/ubuntu.sh` with:

```bash
#!/bin/bash
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
printf 'note: init/ubuntu.sh is deprecated; delegating to bin/bootstrap\n' >&2
exec "$SCRIPT_DIR/bin/bootstrap" "$@"
```

- [ ] **Step 4: Verify green and commit**

```bash
bash tests/bootstrap_test.sh
bash tests/run
bash -n bin/bootstrap init/ubuntu.sh
git diff --check
git add bin/bootstrap init/ubuntu.sh tests/bootstrap_test.sh tests/run
git commit -m "feat: add minimal Ubuntu bootstrap"
```

### Task 5: Operational doctor

**Files:**
- Create: `bin/doctor`
- Create: `tests/doctor_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Consumes manifests, platform detection, and external assumptions.
- Produces `bin/doctor PROFILE` with `PASS`, `WARN`, `SKIP`, and `FAIL` records.

- [ ] **Step 1: Write failing doctor cases**

Use fake commands and `systemctl` to assert:

- healthy owned commands exit `0`;
- missing `nvim` prints `FAIL command: nvim` and exits `1`;
- missing Slack prints `WARN external command: slack` without failure;
- no Sway environment prints `SKIP Sway session checks: not running under Sway`;
- a Sway session with inactive portal fails;
- proprietary NVIDIA prints a prominent warning;
- no call enables, starts, stops, or configures a service.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/doctor_test.sh`.

Expected: FAIL because `bin/doctor` does not exist.

- [ ] **Step 3: Implement result accounting**

```bash
failures=0
pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
skip() { printf 'SKIP %s\n' "$1"; }
fail_check() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
check_command() { command -v "$1" >/dev/null 2>&1 && pass "command: $1" || fail_check "command: $1"; }
check_external() { command -v "$1" >/dev/null 2>&1 && pass "external command: $1" || warn "external command: $1"; }
```

Check owned CLI and Sway commands from the manifests, accepting `fd` or `fdfind`. Run `timeout 10 bash -lic exit` and `timeout 10 zsh -lic exit`. Only in a Sway session query read-only user services for PipeWire, WirePlumber, and both portals. Detect proprietary NVIDIA via `nvidia-smi` or loaded module and warn; never invoke a driver-management command.

- [ ] **Step 4: Verify green and commit**

```bash
bash tests/doctor_test.sh
bash tests/run
bash -n bin/doctor
git diff --check
git add bin/doctor tests/doctor_test.sh tests/run
git commit -m "feat: add Ubuntu setup doctor"
```

### Task 6: Retire obsolete Ubuntu scripts and document the workflow

**Files:**
- Rewrite: `README.md`
- Create: `docs/first-sway-login.md`
- Delete: tracked files under `ubuntu/`
- Create: `tests/docs_test.sh`
- Modify: `tests/run`

**Interfaces:**
- Consumes all public commands.
- Produces one supported Ubuntu path and a physical-laptop checklist.

- [ ] **Step 1: Write failing documentation tests**

Assert README contains `bin/bootstrap`, `bin/audit work`, `bin/apply work`, `bin/doctor work`, GNOME fallback, externally managed ownership, and `pre-modernization-2026-08-11`. Assert tracked `ubuntu/` is gone and supported docs contain none of curl-pipe-shell, `i3-gaps`, `apt-key`, Minikube, or Dropbox instructions.

- [ ] **Step 2: Run test to verify red**

Run `bash tests/docs_test.sh`.

Expected: FAIL against the old README and `ubuntu/` directory.

- [ ] **Step 3: Rewrite docs and remove tracked legacy scripts**

Document the clean workflow, exit codes, manifest ownership, package-source policy, external assumptions, dotfiles handoff, GDM session selection, proprietary NVIDIA warning, and recovery with the tag. Create checklist boxes for Sway/GNOME login, launchers, bindings, displays, Waybar, Mako, clipboard, screenshots, lock/idle, audio, network, Bluetooth, policy prompts, Slack/Zoom launch, screen sharing, SSH, and logout.

Remove only tracked `ubuntu/` files. Leave Fedora, Lima, and all user-untracked files untouched; label Fedora/Lima material unsupported historical content.

- [ ] **Step 4: Run complete validation and commit**

```bash
bash tests/run
for file in bin/* lib/*.sh tests/*.sh init/ubuntu.sh install-software.sh; do bash -n "$file"; done
if command -v shellcheck >/dev/null 2>&1; then shellcheck bin/* lib/*.sh tests/*.sh init/ubuntu.sh install-software.sh; fi
git diff --check
git rev-list -n 1 pre-modernization-2026-08-11
git add README.md docs tests/docs_test.sh tests/run ubuntu
git commit -m "docs: replace legacy Ubuntu setup workflow"
```

Expected tag output: `98c6248d673755db2888b6ac217323e0a4cf3fec`.

### Task 7: Disposable Ubuntu smoke test

**Files:**
- Create: `tests/container-smoke.sh`
- Modify: `README.md`
- Modify: `tests/docs_test.sh`

**Interfaces:**
- Consumes the completed repository.
- Produces a developer-side portability smoke test; it does not replace the physical Sway checklist.

- [ ] **Step 1: Write failing smoke contract test**

Assert the script accepts an optional image, mounts the repository read-only, runs `bash tests/run`, and does not run laptop `apply` or install Docker.

- [ ] **Step 2: Implement smoke script**

```bash
#!/bin/bash
set -eu
image=${1:-ubuntu:24.04}
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
docker run --rm -v "$repo:/repo:ro" -w /repo "$image" bash -lc '
  apt-get update >/dev/null
  apt-get install -y bash coreutils grep sed >/dev/null
  bash tests/run
  bash -n bin/bootstrap bin/audit bin/apply bin/doctor
'
```

Document that Docker is only a local test harness. If unavailable, skip rather than install or start it.

- [ ] **Step 3: Validate and commit**

```bash
bash tests/container-smoke.sh ubuntu:24.04
bash tests/run
git diff --check
git add tests/container-smoke.sh tests/docs_test.sh README.md
git commit -m "test: add Ubuntu container smoke coverage"
```

Expected: host and container tests pass, or the implementation handoff explicitly records the Docker-dependent smoke as skipped.

## Plan completion checks

```bash
bash tests/run
git diff --check
git status --short --branch
git log --oneline pre-modernization-2026-08-11..HEAD
```

Expected: tests pass, only the user's known untracked files remain, and the focused Task 1–7 commits are present.
