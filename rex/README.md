# Rex snooze

`Snooze Pane…` runs the picker, timer, and PTY operations on the server that
owns the selected pane. The Mac's Rex configuration routes remote acknowledgement
to the `snooze_ack` action on that server.

Each server needs `rex-snooze` at `~/.local/bin/rex-snooze`, `uv`, Python 3.11
or later, `rex`, and an `fzf` that supports the picker's `transform` bindings.
`fzf` 0.66.1 is known to work; Ubuntu's 0.44.1 does not. A dedicated binary at
`~/.local/share/rex-snooze/bin/fzf` takes precedence without changing the user's
system `fzf`. Daemon errors are appended to `~/.local/share/rex-snooze/daemon.log`.

For a server with **no existing Rex configuration**, install
`rex/.config/rex/snooze-owner.lua` as `~/.config/rex/init.lua` and run `rex config
check` and `rex config reload` on that server. If it already has a configuration,
add that action to the existing configuration instead of replacing it. Reload
the Mac configuration after changes too. Reloading does not restart the server.

A ringing reminder can be cleared explicitly with the attention jump or the
picker. Merely changing a session's remembered focus does not acknowledge it:
that does not prove a client visited the pane. On Linux, typing does not
implicitly acknowledge it, since devpts access times are not reliable input
signals. Existing macOS input-based acknowledgement remains best-effort.

State and the daemon currently assume the host's default Rex server. They do not
isolate multiple independent Rex server endpoints running under the same account.
