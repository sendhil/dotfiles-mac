# Ubuntu 22.04 Wofi Launcher Design

## Problem

The supported Linux setup accepts Ubuntu 22.04, but its Sway manifest declares
Fuzzel. Fuzzel has no install candidate in the official Jammy archive, so
`bin/apply work` correctly stops during candidate preflight. The workplace
laptop does have an official Jammy candidate for Wofi.

## Decision

Use Wofi as the single Sway application launcher on every supported Ubuntu
release. Do not add a PPA, vendor repository, source build, or version-specific
launcher selection. A single launcher keeps package ownership, Stow selection,
bindings, documentation, and diagnostics consistent across Jammy and newer
Ubuntu releases.

## Linux Setup Changes

- Replace `fuzzel` with `wofi` in the Sway APT manifest.
- Make `bin/doctor` map the `wofi` package to the `wofi` executable.
- Update manifest and doctor tests so Jammy-compatible ownership is explicit.
- Add regression coverage that the supported Sway manifest contains Wofi and
  does not contain Fuzzel.

The existing apply preflight remains unchanged: every APT candidate must exist
before the first package-manager mutation.

## Dotfiles Changes

- Replace the `fuzzel` Stow package with a `wofi` Stow package.
- Configure Wofi in `drun` mode with the existing Tokyo Night palette and no
  host-specific paths.
- Change the Sway menu command and `Alt+d` binding to `wofi --show drun`.
- Update the canonical Ubuntu package set, companion tests, documentation, and
  first-login checklist.
- Remove tracked Fuzzel configuration and supported references.

The user-visible binding remains `Alt+d`; only the launcher implementation
changes.

## Safety and Validation

- No driver, service, runtime, Slack, Zoom, or GNOME ownership changes.
- No external package source is introduced.
- Linux tests must prove candidate validation and Wofi ownership.
- Dotfiles tests must prove the Wofi package is selected, the Sway binding is
  exact, no supported Fuzzel references remain, and real Stow integration still
  links and unlinks isolated Ubuntu homes.
- Both complete suites, Bash syntax checks, Stow integration, and diff checks
  must pass before the branches are pushed.

## Laptop Handoff

After pulling both branches, the laptop reruns `bash tests/run`, then
`bin/audit work` and `bin/apply work`. The audit should report Wofi instead of
Fuzzel, and apply should find an official Jammy candidate before installing
anything.
