# Rex Attention Return Implementation Plan

> **For agentic workers:** Execute inline; the operator authorized implementation, not delegation. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When no other pane needs attention, return to the pane where the user started the current round.

**Architecture:** Keep a configuration-local origin table keyed by Rex client ID. Capture the current placed block only on the first successful attention jump, keep it through later jumps, and restore its session/window/block when no eligible alternative exists. Clear the saved origin after returning so the next round can start elsewhere. A temporary live counter probe confirmed configuration-local Lua variables persist across invocations; the probe was removed.

**Tech Stack:** Rex Lua, LuaJIT, Rex config check/reload.

## Global Constraints

- Preserve the existing blocked → error/failed → done order.
- Do not acknowledge or clear attention statuses; programs remain responsible for them.
- Do not enable Remote Control, restart Rex, or touch unrelated repository changes.
- Saved origins reset on config reload/server restart and are independent for each client.

---

### Task 1: Remember the start and return when attention is exhausted

**Files:**
- Modify: `rex/.config/rex/init.lua`
- Test: `rex/.config/rex/tests/jump_attention_test.lua`

**Interfaces:**
- Consumes: `ctx.client_id`, `ctx.block_id`, placed block listings and their session/window IDs.
- Produces: unchanged attention selection, or `{ found = false, returned = true, block_id = origin.block_id }` with explicit client-side tab selection on return.

- [x] **Step 1: Verify the multi-jump regression fails**

The executable fixture in `rex/.config/rex/tests/jump_attention_test.lua` starts at a working pane, visits a blocked pane and then a finished pane, clears their statuses to idle, and invokes the command again:

```lua
assert(result.returned == true and result.found == false,
  "must return to the starting pane when attention is exhausted")
assert(focused.block_id == "block:current")
assert(queued[1].args.window_id == "window:current")
```

Run: `luajit ~/.config/rex/tests/jump_attention_test.lua`
Expected: failure at the return assertion.

- [x] **Step 2: Add per-client origin storage**

Add `local attention_origins = {}` beside the ranking table. While scanning blocks, capture the current placed block's session/window/block. Before the existing focus call, choose the target:

```lua
local key = ctx.client_id or "default"
local returning = best == nil
if returning then
  best = attention_origins[key]
  attention_origins[key] = nil
  if best == nil then return { found = false } end
elseif attention_origins[key] == nil then
  attention_origins[key] = current
end
```

Use the existing explicit tab selection for either target and return `found = not returning`, `returned = returning`.

- [x] **Step 3: Verify GREEN and fresh-round behavior**

Run the LuaJIT test, then add tests for clearing the saved origin after return, starting a new round elsewhere, and independent clients. Run: `luajit ~/.config/rex/tests/jump_attention_test.lua && rex config check`.
Expected: all checks pass and no Rex config diagnostics. Also reproduced a closed-origin failure before adding focus error handling: a vanished starting pane is forgotten without queuing an app selection. Seven checks pass.

- [x] **Step 4: Reload and request UI verification**

Run: `rex config reload --json`.
Expected: empty diagnostics. Ask the user to drain attention panes and press Ctrl+A then A once more; that should return to the starting pane. UI verification is separate because CLI Remote Control is disabled.
