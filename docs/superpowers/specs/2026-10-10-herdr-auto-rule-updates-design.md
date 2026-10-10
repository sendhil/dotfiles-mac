# Herdr automatic detection-rule updates

## Goal

Enable automatic agent-detection rule updates on this machine and publish the same policy through the existing cross-machine dotfiles setup.

## Approved approach

Set `[update].manifest_check = true` explicitly in `herdr/.config/herdr/config.toml`. Explicit configuration documents the intended policy; deleting the current `false` value and relying on Herdr's default would also work but is less clear.

The local `~/.config/herdr/config.toml` is already a Stow symlink to this tracked file. The Makefile already includes the `herdr` package, so no new synchronization mechanism or setup-script changes are needed. Preserve every unrelated setting and the existing symlink. This enables rule checks only, not a new binary-update policy.

## Activation and cross-machine rollout

Reload configuration on the four running local Herdr servers: `default`, `jarvis`, `lanes`, and `phone`. Use each server's existing socket and do not stop servers, recreate panes, or restart agents. Check each reload response for errors or startup-only warnings; report any setting that cannot be activated live rather than silently restarting.

Commit and push the change to `sendhil/dotfiles-mac` on `master`. The user explicitly approved including the existing unpushed merge commit `a453007` in the normal push. Other machines receive the setting after pulling this repository. Existing Stow links require no restow; machines without the link use `make stow-herdr`. Running Herdr servers on those machines must reload their configuration (or receive the setting on their next startup). Git itself is not being made to pull automatically.

## Verification

Before editing, run a focused assertion that the shared TOML enables `update.manifest_check`; it must fail against the current `false` value. After editing, rerun that assertion, parse the complete TOML, and verify all other parsed settings are unchanged.

Install the actual `herdr` Stow package into a disposable home directory using the existing Makefile target. Verify its config resolves to the tracked shared file and reads `manifest_check = true`.

Run active diagnostics if a TOML server is available, check the scoped Git diff, and verify successful live configuration reloads on all four local servers. Confirm the final commit is present on `origin/master`; leave the working tree clean. No changes to other machines are claimed without actually accessing them.
