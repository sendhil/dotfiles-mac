# Rex Attention Jump Implementation Plan

> **For agentic workers:** Execute inline; the operator authorized the patch, not delegation. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Jump to Pane Needing Attention visibly select a blocked pane in another tab of the same session.

**Architecture:** Keep the existing OSC 7501 scan and priority ranking. Carry the selected block's window_id through selection and always queue the app's session.select action with both session_id and window_id after focusing the pane on the server.

**Tech Stack:** Rex Lua configuration, LuaJIT regression test, Rex config validation.

## Global Constraints

- Preserve all unrelated bindings and blocked → error/failed → done ranking.
- Do not enable Remote Control or restart Rex.
- ~/.config/rex is a symlink to this repository's rex/.config/rex.
- Preserve unrelated dirty Ghostty, Karabiner, and documentation files; do not commit.

---

### Task 1: Explicit app-side tab selection

**Files:**
- Modify: `rex/.config/rex/init.lua`
- Create/Test: `rex/.config/rex/tests/jump_attention_test.lua`

**Interfaces:**
- Consumes: block listings with block_id, window_id, placement, creator_name; OSC 7501 records; action ctx.session_id and ctx.block_id.
- Produces: server focus_block plus queued client session.select with explicit target session and window.

- [x] **Step 1: Reproduce at the real action seam**

Load the real configuration using LuaJIT with substitutes only for external Rex APIs. Supply a working current pane and a blocked pi.ask child record in another window of the same session. Assert that the selected result is blocked and that the queued app action is:

```lua
assert(#queued == 1, "same-session jump must ask the Rex app to select the target tab")
assert(queued[1].action == "session.select")
assert(queued[1].args.session_id == "session:test")
assert(queued[1].args.window_id == "window:question")
```

The complete executable fixture lives in `rex/.config/rex/tests/jump_attention_test.lua`.

- [x] **Step 2: Verify RED**

Run: `luajit ~/.config/rex/tests/jump_attention_test.lua`
Expected: assertion failure `same-session jump must ask the Rex app to select the target tab`.

- [x] **Step 3: Patch only selection routing**

Store `window_id = b.window_id` in the selected best record. Replace conditional cross-session app selection with:

```lua
rex.session.focus_block{ session_id = best.session_id, block_id = best.block_id }
rex.client.queue("session.select", {
  session_id = best.session_id,
  window_id = best.window_id,
})
```

- [x] **Step 4: Verify GREEN and configuration validity**

Run: `luajit ~/.config/rex/tests/jump_attention_test.lua && rex config check`
Expected: regression passes; no config warnings or errors.

- [x] **Step 5: Reload and request UI verification**

Run: `rex config reload`
Expected: successful reload, preserving unrelated bindings. Ask the operator to try Ctrl+A then A or the command palette. On-screen behavior remains unverified until they confirm; CLI app control is disabled.
