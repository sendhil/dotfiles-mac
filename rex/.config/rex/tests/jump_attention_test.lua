-- Run: luajit ~/.config/rex/tests/jump_attention_test.lua
-- Drives the real action; substitutes only the Rex server/app API boundary.
-- Proves an explicit app-side tab selection, not actual GUI rendering.
local actions, queued, focused = {}, {}, nil
local terminal = "com.superlogical.terminal"
local sessions = { { session_id = "session:test", label = "Test" } }
local blocks = {
  ["session:test"] = {
    { block_id = "block:current", window_id = "window:current", creator_name = terminal, placement = "placed" },
    { block_id = "block:question", window_id = "window:question", creator_name = terminal, placement = "placed" },
  },
}
local statuses = {
  ["block:current"] = { records = { { state = "working", app = "pi" } } },
  ["block:question"] = { records = { { state = "working", app = "pi" }, { id = "pi.ask", state = "blocked", kind = "question", app = "pi" } } },
}
rex = {
  bind = function() end,
  mode = function() end,
  action = function(def) actions[def.name] = def.run end,
  log = function() end,
  call = function(method)
    assert(method == "session.list", "unexpected server method: " .. method)
    return { sessions = sessions }
  end,
  session = {
    list_blocks = function(args)
      assert(blocks[args.session_id], "unexpected session")
      return { blocks = blocks[args.session_id] }
    end,
    focus_block = function(args)
      for _, block in ipairs(blocks[args.session_id] or {}) do
        if block.block_id == args.block_id then
          focused = args
          return { revision = 1 }
        end
      end
      return nil, "block not found"
    end,
  },
  block = {
    call = function(creator, method, args)
      assert(creator == terminal and method == "program_status", "unexpected block method")
      assert(statuses[args.block_id], "unexpected block")
      return statuses[args.block_id]
    end,
  },
  client = {
    queue = function(action, args)
      queued[#queued + 1] = { action = action, args = args }
    end,
  },
}
dofile(arg[1] or (os.getenv("HOME") .. "/.config/rex/init.lua"))

local result = actions.jump_attention({ client_id = "client:same", session_id = "session:test", block_id = "block:current" }, {})
assert(result.found and result.block_id == "block:question" and result.state == "blocked", "must find the blocked child record")
assert(focused and focused.block_id == "block:question", "must focus the target pane")
assert(#queued == 1, "same-session jump must ask the Rex app to select the target tab")
assert(queued[1].action == "session.select", "must use app-side session selection")
assert(queued[1].args.session_id == "session:test", "must select the target session")
assert(queued[1].args.window_id == "window:question", "must explicitly select the target tab")
print("PASS: same-session attention jump explicitly selects the target tab")

-- The explicit target tab must also survive a cross-session jump.
queued, focused = {}, nil
sessions[2] = { session_id = "session:other", label = "Other" }
blocks["session:other"] = { blocks["session:test"][2] }
blocks["session:test"][2] = nil
result = actions.jump_attention({ client_id = "client:cross", session_id = "session:test", block_id = "block:current" }, {})
assert(result.found and result.block_id == "block:question", "must find a blocked pane in another session")
assert(focused and focused.session_id == "session:other", "must focus the other session's pane")
assert(#queued == 1 and queued[1].action == "session.select", "must ask the app to switch sessions")
assert(queued[1].args.session_id == "session:other", "must select the other session")
assert(queued[1].args.window_id == "window:question", "cross-session selection must include the target tab")
print("PASS: cross-session attention jump explicitly selects the target tab")

-- No eligible records must not change focus or select a tab.
queued, focused = {}, nil
statuses["block:question"] = { records = { { state = "idle", app = "pi" } } }
result = actions.jump_attention({ client_id = "client:empty", session_id = "session:test", block_id = "block:current" }, {})
assert(result.found == false, "idle and working panes must not need attention")
assert(focused == nil and #queued == 0, "must leave the app alone when nothing needs attention")
print("PASS: no attention target leaves focus unchanged")

-- A round can visit multiple attention panes without overwriting its origin.
local function jump(client, session, block)
  queued, focused = {}, nil
  return actions.jump_attention({ client_id = client, session_id = session, block_id = block }, {})
end
blocks["session:other"][2] = {
  block_id = "block:finished", window_id = "window:finished", creator_name = terminal, placement = "placed",
}
statuses["block:question"] = { records = { { state = "blocked", app = "pi" } } }
statuses["block:finished"] = { records = { { state = "done", app = "pi" } } }
result = jump("client:tour", "session:test", "block:current")
assert(result.block_id == "block:question", "must visit blocked before finished")
statuses["block:question"] = { records = { { state = "idle", app = "pi" } } }
result = jump("client:tour", "session:other", "block:question")
assert(result.block_id == "block:finished", "must visit the next remaining attention pane")
statuses["block:finished"] = { records = { { state = "idle", app = "pi" } } }
result = jump("client:tour", "session:other", "block:finished")
assert(result.returned == true and result.found == false, "must return to the starting pane when attention is exhausted")
assert(focused and focused.block_id == "block:current" and focused.session_id == "session:test", "must restore the original pane, not the previous attention pane")
assert(#queued == 1 and queued[1].args.session_id == "session:test" and queued[1].args.window_id == "window:current", "must visibly return to the original tab")
print("PASS: multiple attention jumps return to the starting pane")

result = jump("client:tour", "session:test", "block:current")
assert(result.found == false and focused == nil and #queued == 0, "returning must clear the old starting pane")
print("PASS: a completed round does not repeatedly restore its origin")

-- A new round starts elsewhere; another app has its own independent origin.
statuses["block:current"] = { records = { { state = "done", app = "pi" } } }
result = jump("client:tour", "session:other", "block:question")
assert(result.block_id == "block:current", "new round must visit the new attention target")
result = jump("client:independent", "session:other", "block:finished")
assert(result.block_id == "block:current", "another app must also find the attention target")
statuses["block:current"] = { records = { { state = "idle", app = "pi" } } }
result = jump("client:tour", "session:test", "block:current")
assert(result.returned and focused.block_id == "block:question", "new round must remember its new starting pane")
assert(queued[1].args.session_id == "session:other" and queued[1].args.window_id == "window:question", "must return to the new starting tab")
result = jump("client:independent", "session:test", "block:current")
assert(result.returned and focused.block_id == "block:finished", "each app must restore its own starting pane")
print("PASS: fresh rounds and different clients keep independent starting panes")

statuses["block:current"] = { records = { { state = "done", app = "pi" } } }
result = jump("client:closed-origin", "session:other", "block:question")
assert(result.block_id == "block:current", "must establish a round before the origin is closed")
statuses["block:current"] = { records = { { state = "idle", app = "pi" } } }
local original = table.remove(blocks["session:other"], 1)
result = jump("client:closed-origin", "session:test", "block:current")
assert(result.found == false and result.returned == false and #queued == 0, "a closed starting pane must not cause an app selection")
result = jump("client:closed-origin", "session:test", "block:current")
assert(result.found == false and #queued == 0, "a closed origin must be forgotten")
table.insert(blocks["session:other"], 1, original)
print("PASS: a closed starting pane is forgotten without switching tabs")

-- Snoozed panes (id = rex.snooze, state = idle) are skipped even if another record says done/blocked.
statuses["block:question"] = {
  records = {
    { state = "done", app = "pi" },
    { id = "rex.snooze", state = "idle", app = "snooze" },
  },
}
statuses["block:finished"] = { records = { { state = "idle", app = "pi" } } }
statuses["block:current"] = { records = { { state = "idle", app = "pi" } } }
result = jump("client:snooze", "session:test", "block:current")
assert(result.found == false and focused == nil, "actively snoozed pane must be skipped by jump_attention")
print("PASS: actively snoozed pane is skipped by jump_attention")

-- Expired snooze (id = rex.snooze, state = blocked) is visited and auto-acknowledged.
local started_cmds = {}
rex.exec = {
  start = function(argv, opts)
    started_cmds[#started_cmds + 1] = { argv = argv, opts = opts }
    return {}
  end,
}
statuses["block:question"] = {
  records = {
    { state = "idle", app = "pi" },
    { id = "rex.snooze", state = "blocked", kind = "question", app = "snooze" },
  },
}
result = jump("client:snooze-wake", "session:test", "block:current")
assert(result.found and result.block_id == "block:question" and result.state == "blocked", "expired snooze must be visited as blocked")
assert(#started_cmds == 1 and started_cmds[1].argv[1] == "/bin/sh" and started_cmds[1].argv[3]:find("/opt/homebrew/bin", 1, true) and started_cmds[1].argv[5] == "ack" and started_cmds[1].argv[6] == "--ringing-only" and started_cmds[1].argv[7] == "block:question", "local ack must set a usable PATH and target the ringing pane")
assert(started_cmds[1].opts and started_cmds[1].opts.detach == true, "ack must run detached")
print("PASS: expired snooze is visited and auto-acknowledged")

-- A remote target must be acknowledged on its owning server, never on the Lua host.
local remote_ack
rex.call = function(method, args)
  if method == "session.list" then return { sessions = sessions } end
  if method == "client.action" then remote_ack = args; return { result = { started = true } } end
  error("unexpected method " .. method)
end
started_cmds = {}
queued, focused = {}, nil
result = actions.jump_attention({ client_id = "client:remote", session_id = "session:test", block_id = "block:current", server = "work-desktop" }, {})
assert(result.found and #queued == 1, "remote jump must still navigate")
assert(remote_ack and remote_ack.action == "snooze_ack" and remote_ack.args.block_id == "block:question", "remote ringing snooze must be acknowledged on its owner")
assert(#started_cmds == 0, "remote snooze must not spawn a local acknowledgement")
print("PASS: remote acknowledgement routes to the owner server")

-- A throwing rex.exec.start must not prevent session.select from queuing.
rex.exec = {
  start = function() error("spawn failed") end,
}
result = jump("client:snooze-err", "session:test", "block:current")
assert(result.found and #queued == 1 and queued[1].action == "session.select", "session.select must still queue even if ack fails")
print("PASS: failing ack does not break attention jump")

-- snooze_pane action opens floating rex-snooze picker targeting the current session and block.
local split_called, float_called = nil, nil
rex.session.new_split = function(args)
  split_called = args
  return { block_ids = { "block:picker" } }
end
rex.session.float_block = function(args)
  float_called = args
  return {}
end
rex.layout = {
  block = function(def) return def end,
}
blocks["session:test"][#blocks["session:test"] + 1] = {
  block_id = "block:picker", window_id = "window:current", creator_name = terminal, placement = "placed",
}
assert(actions.snooze_pane, "snooze_pane action must be defined")
local sres = actions.snooze_pane({ session_id = "session:test", block_id = "block:current", server = "work-desktop" }, {})
assert(sres and sres.block_id == "block:picker", "snooze_pane must return the picker block_id")
assert(split_called and split_called.anchor_id == "block:current", "snooze_pane must split from ctx.block_id")
local cmd = split_called.layout.options.command
assert(split_called.layout.options.shell == "none" and cmd[1] == "/bin/sh" and cmd[2] == "-c", "remote picker must resolve its executable on the target host")
assert(cmd[5] == "ui" and cmd[6] == "-s" and cmd[7] == "session:test" and cmd[8] == "-b" and cmd[9] == "block:current", "snooze_pane must pass session and block as separate arguments")
assert(float_called and float_called.block_id == "block:picker", "snooze_pane must float the picker pane")
print("PASS: snooze_pane opens floating rex-snooze picker with target session and block")

