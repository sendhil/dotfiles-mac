-- Migrated from Herdr, Ghostty and iTerm2.

-- Herdr (prefix ctrl+a)
rex.bind("ctrl+a>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+a>-", "pane.split", { direction = "down" })
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>x", "pane.close")
rex.bind("shift+cmd+up", "session.previous")
rex.bind("shift+cmd+down", "session.next")
rex.bind("shift+cmd+r", "client.tab.rename")

-- Ghostty
rex.bind("ctrl+shift+p", "client.palette.toggle")

-- iTerm2
rex.bind("shift+cmd+left", "client.tab.move", { direction = "backward" })
rex.bind("shift+cmd+right", "client.tab.move", { direction = "forward" })
rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })

-- Jump to the next pane that needs you: blocked first, then failed, then finished.
-- Scans every session's terminals via their program status (OSC 7501) records.
local TERMINAL = "com.superlogical.terminal"
local RANK = { blocked = 1, error = 2, failed = 2, done = 3 }
-- Each app remembers where its current round of attention jumps began.
local attention_origins = {}

rex.action{
  name  = "jump_attention",
  title = "Jump to Pane Needing Attention",
  description = "Focus blocked, failed, then finished panes; return to where you started when none remain.",
  keywords = "agent blocked waiting attention inbox",
  run   = function(ctx, args)
    local listed = rex.call("session.list")
    local best, current
    for _, s in ipairs((listed and listed.sessions) or {}) do
      local blocks = rex.session.list_blocks{ session_id = s.session_id }
      for _, b in ipairs((blocks and blocks.blocks) or {}) do
        if b.block_id == ctx.block_id and b.placement == "placed" then
          current = { session_id = s.session_id, window_id = b.window_id, block_id = b.block_id }
        end
        if b.creator_name == TERMINAL and b.placement == "placed" and b.block_id ~= ctx.block_id then
          local st = rex.block.call(TERMINAL, "program_status", { block_id = b.block_id })
          for _, rec in ipairs((st and st.records) or {}) do
            local rank = RANK[rec.state]
            if rank and (best == nil or rank < best.rank) then
              best = { rank = rank, session_id = s.session_id, window_id = b.window_id, block_id = b.block_id, state = rec.state }
            end
          end
        end
      end
    end
    local key = ctx.client_id or "default"
    local returning = best == nil
    if returning then
      best = attention_origins[key]
      attention_origins[key] = nil
      if best == nil then
        rex.log("info", "nothing needs attention")
        return { found = false }
      end
    elseif attention_origins[key] == nil then
      attention_origins[key] = current
    end
    local _, err = rex.session.focus_block{ session_id = best.session_id, block_id = best.block_id }
    if err ~= nil then
      if returning then
        rex.log("info", "starting pane is no longer available: " .. tostring(err))
        return { found = false, returned = false }
      end
      error(err, 0)
    end
    -- The app keeps its own selected tab; server focus alone does not switch it.
    rex.client.queue("session.select", {
      session_id = best.session_id,
      window_id = best.window_id,
    })
    return { found = not returning, returned = returning, state = best.state, block_id = best.block_id }
  end,
}
rex.bind("ctrl+a>ctrl+a", "jump_attention")

-- Archive / restore sessions and tabs with the rex-archive fzf picker (rex/.local/bin/rex-archive).
-- Opens it in a floating pane over the current tab; the pane closes when the picker exits.
rex.action{
  name  = "archive_sessions",
  title = "Archive Sessions…",
  description = "Archive sessions or tabs to disk and restore them later (rex-archive).",
  category = "Sessions",
  keywords = "archive restore defer stash hide park sessions tabs rex-archive",
  run   = function(ctx, args)
    local split, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side      = "after",
      focus     = true,
      layout    = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        label   = "rex-archive",
        options = { command = { os.getenv("HOME") .. "/.local/bin/rex-archive" } },
      },
    }
    if err ~= nil then error(err, 0) end
    local block_id = split.block_ids[1]
    local _, ferr = rex.session.float_block{ block_id = block_id, bounds = { 0.08, 0.08, 0.84, 0.84 } }
    if ferr ~= nil then rex.log("warn", "rex-archive: couldn't float picker: " .. ferr) end
    rex.session.focus_block{ block_id = block_id }
    return { block_id = block_id }
  end,
}

-- Pane focus after the ctrl+a prefix: arrows and vim keys
for key, dir in pairs({ left = "left", right = "right", up = "up", down = "down", h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+a>" .. key, "pane.focus", { direction = dir })
end

-- Resize mode (Herdr prefix+r): ctrl+a then r, then h/j/k/l or arrows resize.
-- shift+h/j/k/l resize in bigger steps, = balances splits, esc or enter leaves.
-- Tiled panes move the split border (pane.resize). A focused floating pane is
-- resized directly: left/up shrink its width/height, right/down grow them.
local function focused_floating_layer()
  local view = rex.session.view{}
  for _, w in ipairs((view and view.windows) or {}) do
    if w.window_id == view.active_window_id and w.focused_block_id then
      for _, l in ipairs(w.layers or {}) do
        if l.kind == "floating" then
          for _, b in ipairs(l.blocks or {}) do
            if b.block_id == w.focused_block_id then return l end
          end
        end
      end
    end
  end
end

rex.action{
  name  = "resize_smart",
  title = "Resize Pane or Floating Pane",
  args  = { direction = "string", big = "boolean?" },
  run   = function(ctx, args)
    local layer = focused_floating_layer()
    if layer == nil then
      rex.client.queue("pane.resize", { direction = args.direction, amount = args.big and 15 or nil })
      return
    end
    local step = args.big and 0.10 or 0.03
    local x, y, w, h = layer.bounds[1], layer.bounds[2], layer.bounds[3], layer.bounds[4]
    local d = args.direction
    if d == "right" then w = w + step
    elseif d == "left" then w = w - step
    elseif d == "down" then h = h + step
    elseif d == "up" then h = h - step end
    w = math.max(0.1, math.min(w, 1 - x))
    h = math.max(0.1, math.min(h, 1 - y))
    local _, err = rex.session.resize_layer{ layer_id = layer.layer_id, bounds = { x, y, w, h } }
    if err ~= nil then error(err, 0) end
  end,
}
rex.mode("resize", { exclusive = true })
rex.bind("ctrl+a>r", "client.mode.enter", { name = "resize" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right", left = "left", down = "down", up = "up", right = "right" }) do
  rex.bind("resize/" .. key, "resize_smart", { direction = dir })
end
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("resize/shift+" .. key, "resize_smart", { direction = dir, big = true })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/esc", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")

-- Move mode: ctrl+a then m, then h/j/k/l or arrows move a floating pane
-- (shift = bigger steps). A tiled pane swaps with its neighbour instead.
-- c centers a floating pane. esc or enter leaves the mode.
rex.action{
  name  = "move_smart",
  title = "Move Pane or Floating Pane",
  args  = { direction = "string", big = "boolean?" },
  run   = function(ctx, args)
    local layer = focused_floating_layer()
    if layer == nil then
      rex.client.queue("pane.move", { direction = args.direction })
      return
    end
    local step = args.big and 0.10 or 0.03
    local x, y, w, h = layer.bounds[1], layer.bounds[2], layer.bounds[3], layer.bounds[4]
    local d = args.direction
    if d == "right" then x = x + step
    elseif d == "left" then x = x - step
    elseif d == "down" then y = y + step
    elseif d == "up" then y = y - step end
    x = math.max(0, math.min(x, 1 - w))
    y = math.max(0, math.min(y, 1 - h))
    local _, err = rex.session.resize_layer{ layer_id = layer.layer_id, bounds = { x, y, w, h } }
    if err ~= nil then error(err, 0) end
  end,
}
rex.action{
  name  = "center_floating",
  title = "Center Floating Pane",
  run   = function(ctx, args)
    local layer = focused_floating_layer()
    if layer == nil then return end
    local w, h = layer.bounds[3], layer.bounds[4]
    local _, err = rex.session.resize_layer{ layer_id = layer.layer_id, bounds = { (1 - w) / 2, (1 - h) / 2, w, h } }
    if err ~= nil then error(err, 0) end
  end,
}
rex.mode("move", { exclusive = true })
rex.bind("ctrl+a>m", "client.mode.enter", { name = "move" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right", left = "left", down = "down", up = "up", right = "right" }) do
  rex.bind("move/" .. key, "move_smart", { direction = dir })
end
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("move/shift+" .. key, "move_smart", { direction = dir, big = true })
end
rex.bind("move/c", "center_floating")
rex.bind("move/esc", "client.mode.exit")
rex.bind("move/enter", "client.mode.exit")

-- Float the focused pane into a centered 80% x 80% layer (replaces the default
-- alt+cmd+enter). A pane that is already floating goes back to the layout via
-- the built-in pane.float.
rex.action{
  name  = "float_centered",
  title = "Float Pane (Centered)",
  run   = function(ctx, args)
    if focused_floating_layer() ~= nil then
      rex.client.queue("pane.float")
      return
    end
    local _, err = rex.session.float_block{ block_id = ctx.block_id, bounds = { 0.1, 0.1, 0.8, 0.8 } }
    if err ~= nil then error(err, 0) end
    rex.session.focus_block{ block_id = ctx.block_id }
  end,
}
rex.bind("alt+cmd+enter", "float_centered")
