# Cross-platform dotfiles and Ubuntu/Sway setup design

## Summary

Modernize the user's Ubuntu laptop setup without reviving the 2019 installer verbatim. The result will use two repositories with clear ownership:

- `dotfiles-mac` becomes a cross-platform dotfiles repository for shared user configuration plus explicit macOS, Ubuntu, and Sway layers.
- `linux-laptop-setup` owns Ubuntu software declarations and safe `bootstrap`, `audit`, `apply`, and `doctor` workflows.

The Ubuntu laptop will use Sway as the intended graphical session while retaining the complete workplace-provided GNOME environment as a fallback. The same shared shell and development configuration must work locally, over SSH from a work Mac, and in non-graphical sessions.

The old Ubuntu scripts are historical evidence only. No legacy package is carried forward unless required by the current dotfiles, the selected Sway environment, or an explicit current request.

## Goals

- Bootstrap a newly issued, workplace-managed Ubuntu laptop incrementally.
- Preserve the current macOS experience while making shared dotfiles genuinely portable.
- Keep SSH and terminal workflows independent from the graphical desktop.
- Make Sway the preferred login session without removing or altering GNOME.
- Mirror the current AeroSpace window-management muscle memory in Sway where practical.
- Make all setup operations reviewed, additive, repeatable, and non-destructive.
- Diagnose workplace-owned software and services without taking ownership of them.
- Preserve exact pre-migration recovery points in both changed repositories.

## Non-goals

- Reproducing every package from the historical Ubuntu installer.
- Removing packages or reconciling the complete Ubuntu package inventory.
- Installing or configuring Docker, Kubernetes runtimes, Minikube, VM stacks, GPU drivers, VPNs, security agents, or other privileged workplace services.
- Installing, updating, or configuring Slack or Zoom; they are assumed to be workplace-provided.
- Replacing GNOME, GDM, or workplace desktop policy.
- Compiling Sway, a desktop portal, or another major desktop component from source.
- Introducing Ansible, Nix, chezmoi, or another configuration framework in this migration.
- Renaming either repository as part of the first implementation.

## Recovery baseline

Before any migration edits, create annotated tags at the original repository heads:

| Repository | Tag | Tagged commit |
| --- | --- | --- |
| `dotfiles-mac` | `pre-linux-2026-08-11` | `01b0c7035e39f481a0d87ff2e3976c15716cb411` |
| `linux-laptop-setup` | `pre-modernization-2026-08-11` | `98c6248d673755db2888b6ac217323e0a4cf3fec` |

Both tags must be verified locally before edits. They should be pushed with the eventual implementation so recovery does not depend on one machine.

## Repository ownership

### Cross-platform dotfiles repository

The dotfiles repository owns user configuration and symlink selection. It does not install system software.

Its Stow packages will be classified as:

- `common`: portable configuration for Neovim, tmux, Zsh/Prezto, Git aliases, bat, fd, direnv, sesh, and other supported CLI tools.
- `macos`: AeroSpace, Karabiner, skhd, macOS-specific shell behavior, Command-key terminal behavior, and remaining Mac-only automation.
- `ubuntu`: Linux-specific shell, clipboard, terminal, and desktop integration.
- `sway`: Sway and configuration for its companion desktop components.

The active package set must be selected explicitly:

- `make stow-macos` links `common + macos`.
- `make stow-ubuntu` links `common + ubuntu + sway`.
- Matching unstow and preflight operations act on the same explicit sets.

The current unconditional `make stow` must not remain an ambiguous cross-platform operation. It may become a detected-platform convenience only if it prints the selected target and fails on unsupported platforms; the explicit targets remain the documented interface.

Hammerspoon is no longer used. Remove it from the active Mac package set and delete its retired configuration during implementation.

### Ubuntu laptop setup repository

The Ubuntu setup repository owns desired software and machine-level diagnostics. It will adopt the safety model of the current macOS laptop setup without copying Homebrew-specific semantics.

It provides four primary commands:

- `bootstrap`: establish only the prerequisites needed to run the repository's management workflow.
- `audit work`: read-only comparison of declared requirements with the current machine.
- `apply work`: additive installation of missing owned requirements.
- `doctor work`: operational checks spanning the shell, development tools, Sway session, and external assumptions.

The repository must not label every unlisted APT package as unmanaged. Ubuntu and workplace IT own most of the base system. Audit only the requirements declared by this setup.

## Clean-machine workflow

The supported first-run flow is:

1. Clone or otherwise obtain `linux-laptop-setup`.
2. Run `bootstrap`.
3. Run `audit work` and review its complete proposed state.
4. Run `apply work` to add missing owned packages.
5. Clone the cross-platform dotfiles repository including its submodules.
6. Run the dotfiles Ubuntu preflight and resolve any existing-file conflicts explicitly.
7. Run `make stow-ubuntu`.
8. Run `doctor work`.
9. Log out, select Sway in GDM, and complete the first-session smoke test.
10. Select GNOME from GDM immediately if the Sway smoke test reveals GPU, portal, or workplace-application problems.

Every step must be safe to rerun. No normal workflow deletes existing configuration to make Stow succeed.

## Ubuntu software model

### Manifests

Use small reviewed line manifests separated by ownership, not one monolithic install script:

- `manifests/apt-common.txt`: common command-line requirements;
- `manifests/apt-sway.txt`: Sway desktop requirements;
- `profiles/work.apt.txt`: work-profile APT additions;
- `manifests/npm.txt`: user-scoped npm tools;
- `manifests/uv-tools.txt`: user-scoped uv tools;
- `profiles/work.external.txt`: external assumptions owned by IT or workplace provisioning.

A profile exists when both `profiles/<profile>.apt.txt` and `profiles/<profile>.external.txt` exist. The `work` profile always combines `apt-common`, `apt-sway`, `work.apt`, and both user-scoped tool manifests. External entries are diagnostic-only and never part of an apply plan.

Only current requirements enter these manifests. The historical Ubuntu and Fedora scripts are not seed lists.

### Package-source policy

Use package sources in this order:

1. Ubuntu repositories for system packages and desktop integration.
2. User-scoped language/tool managers for fast-moving developer tools when they are already part of the declared model.
3. An official vendor artifact only when the Ubuntu release cannot meet a documented minimum version.

The workflow must not silently:

- add a PPA;
- execute a downloaded shell script;
- compile a major desktop component from source;
- replace an IT-managed driver or service;
- perform a distribution upgrade.

Any release-specific substitution must appear in audit output before apply.

### External assumptions

Treat the following as externally owned:

- Slack and Zoom;
- Docker and Kubernetes runtimes;
- GPU drivers;
- VPN and endpoint-security software;
- workplace agents and policy services.

`doctor` may report whether an assumption is present and whether it affects the intended workflow. Neither `bootstrap` nor `apply` may install, enable, disable, reconfigure, or upgrade it.

Client-only developer tools may be managed when explicitly declared. Their presence must not imply ownership of the corresponding privileged runtime.

## Command contracts

### `bootstrap`

`bootstrap` supports Ubuntu and must:

- read `/etc/os-release` and reject unsupported distributions;
- detect Ubuntu version, architecture, GPU devices, active graphics driver when discoverable, and available `sudo` access;
- install only the prerequisites needed by the repository workflow;
- avoid changing the login shell, desktop session, drivers, or IT-owned services;
- be idempotent and explain manual prerequisites when privilege is unavailable.

### `audit work`

`audit` is read-only. It must report stable sections for:

- missing declared packages and tools;
- declared requirements whose installed version is incompatible;
- unavailable required package managers;
- external assumptions and their observed state;
- release- or architecture-specific substitutions;
- suggested next actions.

It must not update APT metadata, create caches intentionally, install software, or modify repository files.

### `apply work`

`apply` is additive. It must:

- validate the profile, manifests, identifiers, operating system, and needed managers before installation;
- calculate the full intended plan before making changes;
- update APT metadata only when APT packages are actually missing;
- install only missing owned requirements;
- skip already satisfied requirements;
- stop cleanly when a manager operation fails and remain safe to resume.

It must never remove packages, act on unrelated installed packages, upgrade the distribution, replace drivers, or mutate external assumptions.

### `doctor work`

`doctor` validates the working experience rather than package ownership. It checks:

- non-interactive and interactive shell startup;
- required PATH entries and optional-tool guards;
- Neovim runtime prerequisites;
- Sway, XWayland, Waybar, launcher, notifications, lock/idle, clipboard, screenshots, audio, networking integration, and policy agent;
- PipeWire and desktop-portal readiness for workplace screen sharing;
- GPU and driver combinations known to be risky for Sway;
- presence of declared external assumptions without changing them.

Checks must distinguish failure, warning, skipped, and success so an optional or externally owned component does not masquerade as a setup failure.

## Sway desktop

Install Sway and its companions from the supported Ubuntu repositories. The baseline desktop consists of:

- Sway as the compositor;
- Waybar for workspaces and status;
- Fuzzel as the launcher;
- Mako for notifications;
- Swaylock and Swayidle for lock and idle behavior;
- Kitty as the packaged baseline terminal;
- `wl-clipboard` for native Wayland clipboard operations;
- Grim and Slurp for screenshots;
- XWayland for non-native applications;
- PipeWire and the appropriate XDG desktop portals;
- integration with NetworkManager, Bluetooth, audio, brightness, and a graphical policy agent.

Ghostty or WezTerm may remain optional. The initial working Sway session must not depend on a terminal that is difficult to obtain on the workplace Ubuntu release.

GNOME and GDM remain installed and unmodified. The setup does not enable automatic login or remove session choices. Sway is "primary" by user choice at login, not by destructive system replacement.

### Graphics policy

Sway works best with open-source graphics drivers and does not officially support the proprietary NVIDIA driver. `bootstrap` and `doctor` therefore detect the available GPU/driver state and emit a prominent warning for proprietary NVIDIA.

The workflow may install the distribution's Sway packages, but it must not declare the desktop ready until the first-login smoke test succeeds. It must not replace the workplace-provided NVIDIA driver with Nouveau or another driver.

### Output policy

Do not copy hardcoded macOS monitor names or workspace-to-monitor assignments. The baseline must work on the laptop panel and use adaptive output configuration. Dock and monitor profiles can be added after observing the actual Dell hardware and output identifiers.

## Sway bindings and window rules

Mirror the current AeroSpace muscle memory where Sway supports the same concept:

- `Alt+h/j/k/l`: focus left/down/up/right;
- `Alt+Shift+h/j/k/l`: move the focused container;
- `Alt+1` through `Alt+0`: workspaces 1 through 10;
- a secondary-workspace mode for workspaces 11 through 20;
- `Alt+Shift+number`: move a container to the corresponding workspace;
- `Alt+Tab`: workspace back-and-forth;
- `Alt+Backtick`: a native Sway scratchpad terminal;
- `Alt+r`: resize mode using `h/j/k/l`;
- a monitor mode for focusing outputs and moving containers between outputs;
- `Alt+Shift+Space`: toggle floating;
- app-to-workspace routing using observed Wayland application IDs or XWayland classes.

Add conventional discoverability bindings:

- `Alt+Enter`: launch the baseline terminal;
- `Alt+d`: open the launcher;
- `Alt+f`: toggle fullscreen.

Retain `Alt+Shift+f` as a fullscreen compatibility alias during migration. Preserve the current Vim-style `h/j/k/l` navigation intentionally even though stock i3 uses `j/k/l/;`.

Do not blindly translate macOS bundle IDs. Initial application rules should cover only applications whose Linux `app_id` or XWayland class is known, and `doctor` or documentation should explain how to inspect new identifiers.

## Dotfile portability

### Shell configuration

Decompose the current mixed shell files into shared and platform-owned fragments.

Shared configuration contains portable aliases, editor preferences, tool initialization, and PATH construction. Platform fragments contain:

- macOS: `/opt/homebrew`, `~/Library`, Xcode, `defaults`, and other Darwin behavior;
- Ubuntu: Linux-specific paths, clipboard behavior, and graphical-session integration.

Remove hardcoded usernames and personal absolute paths from shared configuration. Host- or employer-specific values belong in a documented, ignored local override.

Guard optional initialization with command or file existence checks. A local or SSH shell must not print errors merely because a graphical or optional tool is absent.

Zsh remains the primary interactive shell. Bash remains usable for recovery and for scripts. Changing the account's login shell is a documented manual action rather than an implicit bootstrap side effect.

### Clipboard behavior

- macOS uses `pbcopy`.
- Sway uses `wl-copy` when a Wayland display is available.
- SSH and tmux use terminal clipboard integration where supported and do not assume a local graphical display.

Shared tmux and Zellij configuration must not hardcode `pbcopy`. Prefer a small selected helper or platform fragment so copy bindings remain readable and testable.

### Neovim ownership

Neovim configuration remains shared. The dotfiles repository configures and diagnoses Neovim; software installation belongs to the laptop setup repositories.

Retire or redirect overlapping Linux dependency installers such as `scripts/setup-neovim-deps-linux.sh` once the Ubuntu apply workflow owns those dependencies. Avoid two scripts that can install different versions of the same tool.

### Terminal configuration

Preserve portable themes, fonts where available, and general behavior. Split modifier-specific bindings:

- Command-key behavior remains macOS-only.
- Ubuntu uses Linux-appropriate modifiers without shadowing Sway's window-manager bindings unnecessarily.

Mac-only CMUX/AeroSpace helpers, Swift binaries, AppleScript, and application paths must not be linked on Ubuntu.

## Conflict and safety policy

Before Stow writes symlinks, a read-only preflight reports:

- existing regular files at managed destinations;
- symlinks owned by another checkout;
- missing submodules or required package directories;
- a package requested for the wrong platform.

The normal workflow must not use the existing destructive `prestow` cleanup that deletes shell files. Conflicts require an explicit user decision: preserve, back up, adopt, or remove the exact file outside the automated link command.

All file operations must remain scoped to declared dotfile destinations. No command performs broad recursive deletion in the home directory.

## Error handling

- Validate all manifests and platform assumptions before mutating machine state.
- Stop a package manager's apply on its first failed install and print the failed item plus a safe rerun command.
- Preserve completed additive work; reruns detect and skip it.
- Report unavailable privilege as an actionable prerequisite rather than attempting workarounds.
- Treat Sway GPU incompatibility, missing portals, and missing external assumptions as explicit doctor findings.
- Keep GNOME recovery instructions available in both the README and first-login checklist.

## Testing and verification

### Ubuntu setup repository

Use isolated fake-manager integration tests modeled on the macOS setup repository. Cover:

- audit success, missing requirements, incompatible versions, unavailable managers, and read-only behavior;
- apply validation-before-mutation, additive installs, skipped satisfied entries, failure propagation, and safe reruns;
- release and architecture detection fixtures;
- external assumptions that are reported but never installed;
- proof that unrelated APT packages are not classified as unmanaged;
- proof that IT-owned services, drivers, and runtimes are never mutated;
- bootstrap behavior with and without usable `sudo`;
- doctor success, warnings, skips, and failures.

Run shell syntax checks, ShellCheck for touched shell files when available, and `git diff --check`.

Exercise the non-desktop setup flow in a disposable supported Ubuntu container where practical. Container validation does not replace the physical Sway smoke test.

### Dotfiles repository

Add tests or dry-run fixtures for:

- correct `common + macos` and `common + ubuntu + sway` package selection;
- rejection of unsupported or cross-platform package combinations;
- non-mutating conflict preflight;
- clean Zsh and Bash startup with optional tools absent;
- platform clipboard selection;
- Sway configuration validation with `sway --validate` when available;
- absence of Hammerspoon from active packages;
- absence of Mac-only paths and commands from Ubuntu-linked files.

Verify the current macOS target still links correctly in a temporary home directory. Run relevant existing Neovim tests, shell syntax checks, and `git diff --check`.

### Physical laptop smoke test

The first Sway login checklist validates:

- session startup and exit back to GDM;
- terminal and launcher;
- mirrored focus, movement, workspace, resize, monitor, fullscreen, and scratchpad bindings;
- laptop panel and attached display behavior;
- Waybar, notifications, clipboard, screenshots, lock, idle, audio, network, brightness, and policy prompts;
- Slack and Zoom launch as externally installed applications;
- screen sharing through PipeWire and desktop portals;
- an SSH login from the work Mac with no graphical-session errors;
- GNOME login remains available and functional.

## Migration sequence

1. Create and verify both recovery tags.
2. Implement the Ubuntu manifest and command framework with tests first.
3. Introduce explicit cross-platform dotfile package selection with tests first.
4. Extract macOS-only shell, clipboard, terminal, and keybinding behavior.
5. Add Ubuntu and Sway packages plus mirrored bindings.
6. Remove Hammerspoon and retire overlapping Linux dependency installers.
7. Run repository-level tests and disposable Ubuntu validation.
8. Review diffs in both repositories and push implementation commits plus both recovery tags.
9. Run the clean-machine workflow on the workplace laptop.
10. Complete the Sway and GNOME physical smoke tests, then record any hardware-specific output profile separately.

## Acceptance criteria

- Both recovery tags resolve to the exact original commits listed above.
- The current macOS configuration links successfully without Ubuntu or Sway files.
- A clean supported Ubuntu system can be bootstrapped through a reviewed, incremental workflow.
- Local and SSH shells start without graphical-session assumptions or missing-tool noise.
- Sway provides launch, navigation, workspaces, notifications, clipboard, lock/idle, screenshots, audio, networking integration, and policy prompts.
- The approved AeroSpace muscle memory is represented in Sway, with documented intentional differences from stock i3.
- GNOME and GDM remain installed, selectable, and unmodified by this setup.
- No legacy package appears without a current requirement.
- No IT-owned runtime, driver, workplace application, or service is modified.
- Slack and Zoom are neither installed nor updated by this setup.
- Repeated bootstrap, audit, apply, doctor, and dotfile-link runs are safe and converge without destructive cleanup.
- Relevant automated tests, syntax checks, configuration validation, and physical smoke tests pass.
