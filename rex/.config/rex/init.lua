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

-- Hyper-M toggles the floating window between minimized and shown.
rex.bind("ctrl+alt+cmd+shift+m", "pane.minimize_floating")

-- Jump to the next pane that needs you: blocked first, then failed, then finished.
-- Scans every session's terminals via their program status (OSC 7501) records.
local TERMINAL = "com.superlogical.terminal"
local RANK = { blocked = 1, error = 2, failed = 2, done = 3 }
local SNOOZE_BOOTSTRAP = 'PATH="$HOME/.local/share/rex-snooze/bin:$HOME/.local/bin:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:$PATH"; export PATH; exec "$HOME/.local/bin/rex-snooze" "$@"'
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
          local b_best, snooze_state
          for _, rec in ipairs((st and st.records) or {}) do
            if rec.id == "rex.snooze" then snooze_state = rec.state end
            local rank = RANK[rec.state]
            if rank and (b_best == nil or rank < b_best.rank) then
              b_best = { rank = rank, session_id = s.session_id, window_id = b.window_id, block_id = b.block_id, state = rec.state }
            end
          end
          if snooze_state ~= "idle" and b_best and (best == nil or b_best.rank < best.rank) then
            b_best.snooze_ack = (snooze_state == "blocked")
            best = b_best
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
    if best.snooze_ack then
      local ok, result, ack_err
      if ctx.server then
        -- rex.call follows the selected remote context; rex.exec would run here.
        ok, result, ack_err = pcall(rex.call, "client.action", { action = "snooze_ack", args = { block_id = best.block_id } })
        if ok and result and result.result and result.result.started == false then
          ack_err, result = result.result.error or "acknowledgement did not start", nil
        end
      elseif type(rex.exec) == "table" and rex.exec.start then
        ok, result, ack_err = pcall(rex.exec.start, { "/bin/sh", "-c", SNOOZE_BOOTSTRAP, "rex-snooze", "ack", "--ringing-only", best.block_id }, { detach = true })
      end
      if not ok or not result then rex.log("warn", "snooze acknowledgement failed: " .. tostring(ack_err or result)) end
    end
    return { found = not returning, returned = returning, state = best.state, block_id = best.block_id }
  end,
}
rex.bind("ctrl+a>ctrl+a", "jump_attention")

-- Open a CLI picker in a centered floating pane over the current tab; closes when the picker exits.
local function open_float_picker(ctx, label, cmd, shell)
  local split, err = rex.session.new_split{
    anchor_id = ctx.block_id,
    direction = "horizontal",
    side      = "after",
    focus     = true,
    layout    = rex.layout.block{
      flavor  = "com.superlogical.terminal.shell",
      label   = label,
      options = { command = cmd, shell = shell },
    },
  }
  if err ~= nil then error(err, 0) end
  local block_id = split.block_ids[1]
  local _, ferr = rex.session.float_block{ block_id = block_id, bounds = { 0.08, 0.08, 0.84, 0.84 } }
  if ferr ~= nil then rex.log("warn", label .. ": couldn't float picker: " .. ferr) end
  rex.session.focus_block{ block_id = block_id }
  return { block_id = block_id }
end

local ARCHIVE_BOOTSTRAP = 'PATH="$HOME/.local/bin:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:$PATH"; export PATH; exec "$HOME/.local/bin/rex-archive" "$@"'

local function archive_browser(ctx, mode)
  local argv = { "/bin/sh", "-c", ARCHIVE_BOOTSTRAP, "rex-archive", mode or "ui" }
  if mode == "ui-tab" then
    if not ctx.session_id or not ctx.block_id then error("Select a pane to archive its tab.", 0) end
    argv[#argv + 1] = ctx.session_id
    argv[#argv + 1] = ctx.block_id
  end
  return open_float_picker(ctx, "rex-archive", argv, "none")
end

-- Run on the local owner only. A remote selection uses the terminal browser there.
local function archive_helper(...)
  local argv = { "/bin/sh", "-c", ARCHIVE_BOOTSTRAP, "rex-archive", ... }
  local r, err = rex.exec(argv, { timeout = 25 })
  if not r then error(err, 0) end
  if not r.ok then error(r.stderr ~= "" and r.stderr or r.stdout, 0) end
  local result, why = rex.json.decode(r.stdout)
  if not result then error(why or "Unreadable rex-archive response", 0) end
  return result
end

local function archive_pick(ctx, prompt, fallback)
  local id, why, detail = rex.ui.pick(prompt)
  if why == "unsupported" then archive_browser(ctx, fallback or "ui-restore")
  elseif not id and why ~= "cancelled" and why ~= "timeout" then error(detail or why, 0) end
  return id
end

local function needs_browser(ctx)
  return ctx.server or not (rex.ui and rex.ui.pick)
end

rex.action{
  name = "archive_this_tab", title = "Archive This Tab…", category = "Sessions",
  run = function(ctx)
    if needs_browser(ctx) then return archive_browser(ctx, "ui-tab") end
    local sid, bid = ctx.session_id, ctx.block_id
    if not sid or not bid then error("Select a pane to archive its tab.", 0) end
    local tab = archive_helper("tab-summary", sid, bid)
    local title = tab.scope == "session" and "Archive & close last tab and session" or "Archive & close tab"
    local choice = archive_pick(ctx, { title = title .. ": " .. tab.title .. "?", items = {
      { id = "cancel", title = "Keep open" },
      { id = "archive", title = title, subtitle = tab.detail .. " · Running processes will stop." },
    } }, "ui-tab")
    if choice == "archive" then return archive_helper("archive-confirmed", sid, tab.window, tab.scope) end
  end,
}

rex.action{
  name = "restore_archived_work", title = "Restore Archived Work…", category = "Sessions",
  run = function(ctx)
    if needs_browser(ctx) then return archive_browser(ctx, "ui-restore") end
    local catalog = archive_helper("catalog")
    local items, dest = {}, {}
    for _, a in ipairs(catalog.archives) do
      items[#items + 1] = { id = a.id, title = a.title, subtitle = a.subtitle, detail = a.detail }
      dest[a.id] = a.destination
    end
    if #items == 0 then
      archive_pick(ctx, { title = "No archived work", items = { { id = "close", title = "Close", subtitle = "Use Archive This Tab to save a workspace." } } })
      return
    end
    local key = archive_pick(ctx, { title = "Restore archived work", placeholder = "Filter archives", items = items })
    if not key then return end
    local target = dest[key]
    if target == "choose" then
      local targets = { { id = "new", title = "New session" } }
      for _, s in ipairs(catalog.sessions) do targets[#targets + 1] = s end
      target = archive_pick(ctx, { title = "Original session is gone. Restore tab into…", items = targets })
      if not target then return end
    end
    local result = archive_helper("restore-to", key, target)
    rex.client.queue("session.select", { session_id = result.session })
    return result
  end,
}

rex.action{
  name = "open_favorite", title = "Open Favorite…", category = "Sessions",
  keywords = "star favorite bookmark workspace session tab archive",
  run = function(ctx)
    local fallback = "ui-favorites"
    if needs_browser(ctx) then return archive_browser(ctx, fallback) end
    local rows = archive_helper("favorites")
    local items, by_id = {}, {}
    for _, row in ipairs(rows) do
      items[#items + 1] = { id = row.id, title = row.title, detail = row.state, icon = "star" }
      by_id[row.id] = row
    end
    if #items == 0 then
      archive_pick(ctx, { title = "No favorites yet", items = { { id = "close", title = "Close", subtitle = "In Manage Sessions & Archives, press Ctrl-F to star a row." } } }, fallback)
      return
    end
    local id = archive_pick(ctx, { title = "Open favorite", items = items }, fallback)
    if not id then return end
    if by_id[id].state == "Missing" then
      local choice = archive_pick(ctx, { title = by_id[id].title .. " is missing", items = {
        { id = "keep", title = "Keep favorite" }, { id = "remove", title = "Remove favorite" },
      } }, fallback)
      if choice == "remove" then return archive_helper("forget-missing", id) end
      return
    end
    local result = archive_helper("open-favorite", id)
    if result.choose then
      local targets = { { id = "new", title = "New session" } }
      for _, s in ipairs(archive_helper("catalog").sessions) do targets[#targets + 1] = s end
      local dest = archive_pick(ctx, { title = "Original session is gone. Restore tab into…", items = targets }, fallback)
      if not dest then return end
      result = archive_helper("open-favorite", id, dest)
    end
    rex.client.queue("session.select", { session_id = result.session, window_id = result.window })
    return result
  end,
}

-- Keep the live previews and batch commands in the terminal browser.
rex.action{
  name  = "archive_sessions",
  title = "Manage Sessions & Archives…",
  description = "Archive sessions or tabs to disk and restore them later (rex-archive).",
  category = "Sessions",
  keywords = "archive restore defer stash hide park sessions tabs rex-archive",
  run   = function(ctx) return archive_browser(ctx) end,
}

-- Snooze a pane for a duration and mark it blocked (OSC 7501) when due (rex/.local/bin/rex-snooze).
rex.action{
  name  = "snooze_pane",
  title = "Snooze Pane…",
  description = "Snooze a pane for a duration and mark it blocked when due (rex-snooze).",
  category = "Pane",
  keywords = "snooze defer remind timer later attention block pane rex-snooze",
  run   = function(ctx, args)
    -- Expand HOME on the server that owns the new terminal, not the Lua host.
    local cmd = { "/bin/sh", "-c", SNOOZE_BOOTSTRAP, "rex-snooze", "ui" }
    if ctx.session_id then cmd[#cmd + 1] = "-s"; cmd[#cmd + 1] = ctx.session_id end
    if ctx.block_id then cmd[#cmd + 1] = "-b"; cmd[#cmd + 1] = ctx.block_id end
    return open_float_picker(ctx, "rex-snooze", cmd, "none")
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
