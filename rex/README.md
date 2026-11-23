# Rex archive

- **Archive This Tab…** shows the invoking tab and its programs before saving and closing it. The last tab is saved as a whole session. Switching focus while deciding does not retarget the action.
- **Restore Archived Work…** lists saved tabs and sessions without terminal output. A tab returns to its original session if it still exists; otherwise choose a session or create one.
- **Open Favorite…** focuses a live workspace or restores its latest linked archive. To favorite an existing archive, session, or tab, highlight it in **Manage Sessions & Archives…** and press **Ctrl-F**; press it again to unstar. Typing still searches. Stars survive restore and re-archive on that host. If a starred tab was archived with its parent session, opening it restores that session and selects the tab. A workspace closed outside the archiver shows as **Missing**, with the option to remove the star. Favorites live in `favorites.sqlite3` beside the archive directories; they are not synced by Git.
- **Manage Sessions & Archives…** opens the `fzf` browser with previews, bulk archive/restore, and trash. `rex-archive` still opens this browser from a shell.

Native prompts require [Rex custom UI](https://www.superlogical.com/rex/docs/customize/custom-ui) support (control API revision 17). Older installations and remote contexts offer the same scoped archive and restore flows in a terminal picker. In Manage, type normally to search, Tab to mark rows, Ctrl-A to review an archive, Ctrl-R to restore, and Ctrl-X to review trash. Destructive confirmations default to Cancel. Esc backs out. Install `~/.local/bin/rex-archive`, `uv`, Python 3.11+, and `rex` on the owner host; the browser also needs `fzf` with `transform` bindings. After updating the stowed config, run `rex config check && rex config reload`.

Archives are workspace snapshots, not suspended processes. They store pane directories, commands, layout and recent output under `~/.local/share/rex-archive` (override with `REX_ARCHIVE_DIR`). Only a Claude resume command with a matching saved conversation ID runs automatically. Ambiguous agent resumes and ordinary commands are staged for review, including when restoring older archives. On a partial restore, the snapshot stays available; inspect any newly created panes before retrying.

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
