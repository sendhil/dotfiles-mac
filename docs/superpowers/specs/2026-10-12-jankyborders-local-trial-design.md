# JankyBorders: local-first trial

Date: 2026-10-12
Status: Temporary-run approach approved; written-spec review pending.

## Goal

Try [JankyBorders](https://github.com/FelixKratz/JankyBorders) on this Mac before
adding its configuration to the shared dotfiles or rolling it out to other Macs.
The user selected a temporary run rather than a login service.

## Existing setup

- This machine runs macOS 26.6.2 on Apple Silicon; upstream requires macOS 14+.
- AeroSpace is running, and its configuration is already linked through GNU Stow.
- Homebrew and the `felixkratz/formulae` tap are present.
- Borders is not installed or running; there is no existing Borders config or
  Homebrew Borders login agent.
- Ghostty uses Tokyo Night Storm, including the accent `#7aa2f7`.

## Trial design

Install the stable `felixkratz/formulae/borders` formula, not the HEAD build.
Do not perform a general Homebrew upgrade or start a Homebrew service.

Run the installed executable manually with explicit options:

```sh
borders style=round width=3.0 hidpi=on ax_focus=off \
  active_color=0xff7aa2f7 inactive_color=0x00000000
```

The focused window gets a rounded, opaque blue 3-point border; inactive windows
have transparent borders. Retina rendering is enabled. Explicitly disable
accessibility-based focus detection for this first trial; do not change macOS
permissions or security settings. If a permission prompt or incompatibility
occurs, report it rather than bypassing protections.

Use a managed background process to keep the temporary trial running. Record its
process identity for stopping it. Supply options directly, without creating
`~/.config/borders/bordersrc`, changing AeroSpace, or installing a login agent.

## Validation and rollback

Before launching, recheck that no Borders instance is running. Homebrew must
report a successfully installed stable formula, with an executable available.
After launching, verify that the owned process stays alive and check startup
output for errors. Process health is not proof of correct visual rendering.

Ask the user to switch focus among windows using clicks and AeroSpace shortcuts,
then try another workspace and their usual monitor setup. The user should confirm
that the blue outline follows the focused window, does not obscure content, and
that inactive windows have no visible outline. Screen-edge clipping or missed
focus updates are reasons to adjust the trial, not silently change window gaps.

Stop the owned trial process to remove borders. Optionally uninstall the newly
installed `borders` formula if the user rejects the tool. Do not remove the
pre-existing Homebrew tap or unrelated packages.

## Deferred cross-Mac rollout

After the user accepts the trial, add `borders/.config/borders/bordersrc`, register
the Stow package in `Makefile`, and document installation on each Mac. Choose one
autostart owner (AeroSpace or Homebrew) at that time; do not enable both.

No push, remote-Mac commands, autostart changes, shared runtime configuration,
AeroSpace gap edits, or broad dotfiles cleanup belong to this trial. The design
and subsequent implementation-plan documents may be committed locally; no
publication is authorized.

## References

- [Upstream installation and configuration](https://github.com/FelixKratz/JankyBorders#usage)
- [Upstream option reference](https://github.com/FelixKratz/JankyBorders/wiki/Man-Page)
