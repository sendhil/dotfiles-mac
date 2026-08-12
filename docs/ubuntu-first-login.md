# Ubuntu first-login checklist

Complete this checklist on the physical work laptop. Static tests cannot
validate the display stack, input devices, desktop portals, corporate
applications, or GPU behavior. Keep GNOME available in GDM until every
critical workflow works reliably.

## Before choosing Sway

- [ ] Finish `bin/bootstrap`, `bin/audit work`, `bin/apply work`, and the
  follow-up audit in the separate `linux-laptop-setup` checkout.
- [ ] Run `bin/doctor work` from `linux-laptop-setup` and review every warning.
- [ ] Run `make preflight-ubuntu` and `make stow-ubuntu` from this dotfiles
  checkout, resolving every conflict explicitly without deleting existing
  home-directory content.
- [ ] If a proprietary NVIDIA driver is detected, do not change it; plan a
  short Sway smoke test and be ready to select GNOME again in GDM.

Log out, open GDM's session chooser, and select Sway. Then verify:

- [ ] Sway reaches a stable desktop, and logout returns to GDM normally.
- [ ] GNOME can still be selected in GDM and reaches a stable desktop.
- [ ] `Alt+Enter` opens Kitty and `Alt+d` opens the Fuzzel launcher.
- [ ] Focus with `Alt+h/j/k/l` and move with `Alt+Shift+h/j/k/l` work in every
  direction.
- [ ] Selection and move bindings cover workspaces 1–20, including the
  secondary-workspace mode.
- [ ] `Alt+Tab` workspace back-and-forth returns to the expected workspace.
- [ ] `Alt+Backtick` creates, hides, and restores exactly one scratchpad
  terminal.
- [ ] `Alt+r` resize mode changes width and height and exits with Return or
  Escape.
- [ ] The output mode focuses each attached output and moves a container
  between outputs.
- [ ] Application routing sends Chrome, VS Code, Kitty, Obsidian, and Slack to
  the documented workspaces; inspect mismatches rather than guessing IDs.
- [ ] Built-in and attached displays use the expected resolution, scale,
  position, refresh rate, and lid behavior.
- [ ] Brightness controls and laptop brightness keys change the built-in panel
  smoothly across a usable range.
- [ ] Waybar displays workspaces, clock, battery, audio, network, and Bluetooth
  status without errors.
- [ ] Mako displays and dismisses a test notification.
- [ ] The clipboard works between native Wayland, terminal, and XWayland
  applications.
- [ ] Full-screen and region screenshots capture the intended pixels and save
  successfully.
- [ ] Manual locking works, idle locking triggers, and resume accepts the
  expected credentials without exposing the session.
- [ ] Audio output, headphones, microphone input, mute keys, media keys, and
  volume keys work.
- [ ] Network status is visible, and Wi-Fi disconnects and reconnects.
- [ ] Bluetooth discovers and reconnects a trusted peripheral.
- [ ] Policy prompts appear for an action that legitimately needs elevation.
- [ ] Slack and Zoom launch, render correctly, and can access the microphone
  and camera according to workplace policy.
- [ ] Slack and Zoom screen sharing opens the desktop portal chooser and shares
  the selected display or window instead of a blank frame.
- [ ] An incoming SSH session from the work Mac starts Bash and Zsh cleanly
  without a graphical environment; tmux copy mode reaches the Mac clipboard
  through OSC 52 when terminal policy allows it.
- [ ] `bin/doctor work` inside Sway reports working portals, audio-session
  services, and policy-agent integration; investigate every `FAIL`.
- [ ] Logout works without a forced reboot, and both Sway and GNOME remain in
  the next GDM session menu.

If a critical check fails, record whether the application is native Wayland
or XWayland, log out normally, and select GNOME. Do not replace workplace
drivers, desktop packages, or IT-owned services as a troubleshooting shortcut.
