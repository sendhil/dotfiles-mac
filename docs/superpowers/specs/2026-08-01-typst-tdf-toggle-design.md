# Typst TDF Toggle Design

## Goal

Add `:TypstTdfToggle` to Neovim so a Typst document can be compiled continuously and previewed with `tdf` in a right-hand Herdr pane.

## Scope

- Operate on the current `.typ` buffer.
- Require Neovim to be running inside Herdr for the terminal preview.
- Compile once before opening the viewer so `tdf` receives an existing PDF.
- Run `typst watch` for save-driven PDF updates; rely on `tdf` hot reload.
- Toggle the same preview off by stopping the watcher and closing its Herdr pane.
- Clean up the watcher and preview pane when Neovim exits.
- Leave `typst-preview.nvim` intact for browser-based, unsaved-buffer previewing.

## Architecture

Create a focused Lua module at `lua/typst_tdf.lua`. It owns one preview session containing the source path, PDF path, Typst watcher process, and Herdr pane ID. The Typst plugin spec registers `:TypstTdfToggle` and a Typst-specific keybinding that calls the module.

The module uses argument-vector process APIs rather than constructing shell command strings. This keeps paths with spaces safe and makes process failures observable.

## Data Flow

1. Validate that the current buffer is a saved `.typ` file and that `HERDR_ENV=1` and `HERDR_PANE_ID` are present.
2. If a session is active, stop it and return.
3. Write the current buffer, derive a sibling `.pdf` path, and run `typst compile` once.
4. Start `typst watch <source> <pdf>` as a Neovim-owned background process.
5. Split the current Herdr pane to the right without moving focus.
6. Run `tdf <pdf>` in the new pane. The shell-level `tdf` wrapper removes the inherited WezTerm identifiers, allowing Herdr's Kitty graphics support to render the pages.
7. On the next toggle or Neovim exit, terminate the watcher and close the preview pane.

## Error Handling

- Report unsaved/non-Typst buffers without starting processes.
- Report missing Herdr context instead of opening a broken Neovim terminal preview.
- If initial compilation fails, show Typst's error and create neither watcher nor pane.
- If pane creation or viewer launch fails, stop any watcher already started and clear session state.
- Treat an already-closed pane or exited watcher as successful cleanup.

## Testing

Use a headless Neovim test with injected process functions to verify command construction and lifecycle behavior without mutating a live Herdr workspace. Cover initial start, second-toggle cleanup, invalid buffer/context, compilation failure, and exit cleanup. Also run Lua formatting/syntax checks and compile the existing three-page sample with the real Typst CLI.
