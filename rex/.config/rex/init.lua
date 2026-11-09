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
