-- Owner-server acknowledgement action for rex-snooze.
rex.action{
  name = "snooze_ack",
  title = "Acknowledge Snoozed Pane",
  args = { block_id = "string" },
  run = function(ctx, args)
    if ctx.server then return { started = false, error = "owner action cannot target another server" } end
    if not args.block_id:match("^block:[%w%-]+$") then return { started = false, error = "invalid block ID" } end
    local handle, err = rex.exec.start({ "/bin/sh", "-c", 'PATH="$HOME/.local/share/rex-snooze/bin:$HOME/.local/bin:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:$PATH"; export PATH; exec "$HOME/.local/bin/rex-snooze" "$@"', "rex-snooze", "ack", "--ringing-only", args.block_id }, { detach = true, timeout = 4 })
    if not handle then return { started = false, error = tostring(err) } end
    local result, wait_err = handle:wait(5)
    if not result then return { started = false, error = tostring(wait_err) } end
    if not result.ok then return { started = false, error = result.stderr ~= "" and result.stderr or "acknowledgement failed" } end
    return { started = true }
  end,
}
