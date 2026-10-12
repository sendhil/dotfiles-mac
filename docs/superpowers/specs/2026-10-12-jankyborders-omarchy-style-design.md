# JankyBorders: Omarchy-inspired amber trial

Date: 2026-10-12
Status: Amber style and written specification approved; Apply now authorized.

## Goal and evidence

The initial rounded, 3-point blue trial was hard for the user to see. The user
requested an Omarchy-default-inspired appearance and selected the amber option.
This is an appearance adjustment, not a confirmed JankyBorders rendering bug.

Current upstream Omarchy Quattro uses square 2px borders and theme-dependent
active colors. Its generated theme template uses the theme accent unless
explicitly overridden and falls back to `rgba(595959aa)` for inactive borders.
Tokyo Night's accent is `#7aa2f7`, exactly the blue in the initial trial.
Matte Black's accent is `#e68e0d`; use that for the replacement.

## Approved mapping

- JankyBorders `style=square` approximates Omarchy's square border geometry.
- `width=4.0` is an intentional macOS visibility adjustment, not a claim to
  reproduce Omarchy's 2px border dimensions exactly.
- `active_color=0xffe68e0d`: opaque Matte Black amber.
- `inactive_color=0xaa595959`: Omarchy's gray fallback, converting Hyprland's
  `RRGGBBAA` representation to JankyBorders' `AARRGGBB` representation.
- Keep `hidpi=on` and `ax_focus=off` unchanged.

Apply the documented runtime update to the existing owned Borders instance:

```sh
borders style=square width=4.0 hidpi=on ax_focus=off \
  active_color=0xffe68e0d inactive_color=0xaa595959
```

Do not create a config file, enable a service, edit AeroSpace, change permissions,
install another package, push, or run commands on other Macs. Preserve unrelated
concurrent AeroSpace/Sketchybar edits in the working tree.

## Validation and rollback

Before updating, confirm that the original managed trial (`b0de2a0e9`, PID 34556
at the initial checkpoint) still owns the sole Borders process. If it has exited
or ownership changed, stop and reconcile rather than start or alter another
instance implicitly.

Check the update command's exit status/output, then verify that the same primary
process remains alive. A runtime IPC update does not change the primary process's
startup command line: `ps` will still show the original blue arguments. Neither
that command line nor exit status proves visual rendering. Ask the user to
confirm the amber outline is clearly visible, follows focus, and behaves well
with their workspace, monitor and window-edge setup.

If needed, restore the initial appearance with a runtime update:

```sh
borders style=round width=3.0 hidpi=on ax_focus=off \
  active_color=0xff7aa2f7 inactive_color=0x00000000
```

Alternatively, stop the verified owned trial. Sync and autostart remain deferred
until the user accepts the appearance and approves the later rollout.

## Sources inspected

- [Omarchy geometry](https://github.com/omacom/omarchy/blob/quattro/default/hypr/looknfeel.lua)
- [Theme border mapping](https://github.com/omacom/omarchy/blob/quattro/default/themed/hyprland.lua.tpl)
- [Tokyo Night palette](https://github.com/omacom/omarchy/blob/quattro/themes/tokyo-night/colors.toml)
- [Matte Black palette](https://github.com/omacom/omarchy/blob/quattro/themes/matte-black/colors.toml)
- [JankyBorders runtime updates and options](https://github.com/FelixKratz/JankyBorders#updating-the-border-properties-during-runtime)
