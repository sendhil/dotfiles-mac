# JankyBorders: upstream screenshot-style trial

Date: 2026-10-12
Status: Repository look and written specification approved; restart authorized.

## Goal

The user disliked the earlier blue and Omarchy-inspired amber appearances and
requested the look in the main JankyBorders repository. Use its rounded neutral
reference, not another invented palette. The supplied blue screenshot was taken
at 12:58:05, before the amber update around 13:00; it cannot prove that update
failed. Current appearance is nevertheless not accepted by the user.

## Selected appearance

Use the colors and 5-point width from the README's AeroSpace example, with the
upstream default round style. Retain the existing local Retina/focus settings:

```sh
borders style=round width=5.0 hidpi=on ax_focus=off \
  active_color=0xffe1e3e4 inactive_color=0xff494d64
```

The focused outline is off-white and the inactive outlines are subdued gray.
This maps the repository example; it does not claim to reproduce the reference
screenshot's wallpaper, terminal theme, window spacing, or exact pixel geometry.
`hidpi=on` is retained for this Retina Mac rather than copied from the separate
README config-file example, which uses a different 6-point setup.

## Clean temporary restart

Confirm the original managed trial `b0de2a0e9` still owns sole Borders PID 34556.
Stop only that owned task, verify it exited and no Borders process remains, then
start one managed process with the complete selected arguments above. Record its
new task ID and PID. If ownership differs, stop and reconcile rather than kill
an unrelated process or silently update another instance.

This uses explicit startup settings instead of relying on a runtime update:
the inspected 1.9.0 client returns 0 without checking Mach message delivery and
provides no renderer acknowledgment. A clean startup makes the requested
arguments observable, though process health is still not proof of visual quality.

Keep installed Borders 1.9.0. Do not create a config file, start a login service,
change permissions, edit AeroSpace/gaps, upgrade or patch the tool, push, or touch
other Macs. Preserve unrelated concurrent AeroSpace/Sketchybar changes.

## Validation and stop

Verify exactly one new owned process with the intended arguments, inspect startup
output for errors, and confirm no Borders config/login agent was added. Check
runtime-file fingerprints before and after and keep the restart's expected old
task-exit notification separate from unexpected failures.

Ask the user to assess the new neutral appearance while switching focus and
workspaces. A fresh corner crop after this restart should show whether there is
still a doubled/clipped outline. Do not claim an underlying renderer bug is fixed.

If the reference look is also unacceptable, stop and reassess geometry/focus and
whether the tool fits this desktop instead of continuing blind palette changes.
Stop the verified new owned trial if requested; do not uninstall without approval.
Sync and autostart remain deferred until visual acceptance and rollout approval.

## Sources

- [README example](https://github.com/FelixKratz/JankyBorders#bootstrap-with-aerospace)
- [Repository screenshot](https://github.com/FelixKratz/JankyBorders/blob/main/images/screenshot.png)
- [Version 1.9.0 startup/update path](https://github.com/FelixKratz/JankyBorders/blob/v1.9.0/src/main.c)
- [Version 1.9.0 message delivery](https://github.com/FelixKratz/JankyBorders/blob/v1.9.0/src/mach.c)
