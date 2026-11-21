-- Run: luajit rex/.config/rex/tests/snooze_owner_test.lua rex/.config/rex/snooze-owner.lua
local actions, started = {}, nil
rex = {
  action = function(def) assert(type(def.title) == "string" and def.title ~= "", "Rex requires an action title"); actions[def.name] = def.run end,
  exec = { start = function(argv, opts) started = { argv = argv, opts = opts }; return { wait = function() return { ok = true } end } end },
}
dofile(arg[1] or "rex/.config/rex/snooze-owner.lua")
local result = actions.snooze_ack({}, { block_id = "block:test" })
assert(result.started, "owner action must start acknowledgement")
assert(started and started.opts.detach and started.argv[#started.argv - 1] == "--ringing-only" and started.argv[#started.argv] == "block:test", "must acknowledge the target on the owner")
print("PASS: owner action acknowledges its target")
started = nil
result = actions.snooze_ack({ server = "another-server" }, { block_id = "block:test" })
assert(not result.started and started == nil, "owner action must not spawn for another server")
rex.exec.start = function() return nil, "spawn failed" end
result = actions.snooze_ack({}, { block_id = "block:test" })
assert(not result.started and result.error == "spawn failed", "spawn errors must be reported")
rex.exec.start = function() return { wait = function() return { ok = false, stderr = "clear failed" } end } end
result = actions.snooze_ack({}, { block_id = "block:test" })
assert(not result.started and result.error:find("clear failed"), "command failures must be reported")
print("PASS: owner action rejects wrong server and reports command failures")
