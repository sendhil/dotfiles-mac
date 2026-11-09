# Shell Startup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Avoid eager x-cmd initialization and Kubernetes prompt detection in new Zsh shells while retaining first-use x-cmd behavior and an explicit Kubernetes opt-in.

**Architecture:** Source a small tracked Zsh lazy loader from both the tracked startup file and the live machine-local startup file. Keep the Powerlevel10k Kubernetes segment in the configuration but remove it from the resolved segment list unless `DOTFILES_KUBECONTEXT=1` is set. Execute inline in the current session; do not delegate, update packages, or restart terminals. Commit and push only when separately authorized by the user.

**Tech Stack:** Zsh, Powerlevel10k, Python standard-library unittest; `uv run` for temporary profiling scripts.

## Global Constraints

- Preserve unrelated work in `Makefile` and tmux plugins.
- Preserve all installer-added paths and integrations in the live `~/.zshrc`.
- Do not disable Git-status: its previously suspected large delay was a diagnostic-cache artifact.
- Do not delete production completion or Git-status caches.
- Do not source live shell configuration into tests with private environment values.
- The installed x-cmd loader defines both the native `x` function and `___x_cmd`; its initialization is the external test boundary.
- Keep the existing unittest suite and no new dependencies.

---

### Task 1: Lazy-load x-cmd through its normal entrypoint

**Files:**
- Create: `bash-linux/.bash/x_cmd.zsh`
- Modify: `bash-linux/.zshrc`
- Modify: `/Users/sendhil/.zshrc` (machine-local file; only replace its eager x-cmd line)
- Test: `tests/test_shell_startup.py`

**Interfaces:**
- Consumes: installed `$HOME/.x-cmd.root/X`, which defines `x` and `___x_cmd` in the calling shell.
- Produces: a deferred `x` entrypoint, preserving arguments, command exit status, and native replacement after initialization. A missing x-cmd installation is a no-op.

- [ ] Add an inert lazy-loader module stub so the new interface can be tested without missing-file or missing-symbol errors:

```zsh
function x() { return 127; }
```

- [ ] Add a subprocess Zsh test with a temporary HOME and a fixture external x-cmd loader. Observe no loader side effects before `x`, then exactly one initialization and correctly forwarded arguments on first use. Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_shell_startup.py -v`; confirm the new assertion fails because the stub does not initialize x-cmd.
- [ ] Replace the stub with the minimal lazy loader:

```zsh
if [[ -r "$HOME/.x-cmd.root/X" ]] && (( ! $+functions[___x_cmd] )); then
  function x() {
    source "$HOME/.x-cmd.root/X" || return
    # Delegate to the installed x function, including its two-stage agent loader.
    'x' "$@"
  }
fi
```

- [ ] Run the focused test green. Add one regression at a time for repeated use/resourcing, exit status, load failure, and a missing installation. Exercise realistic mutations when a regression already passes on first execution.
- [ ] Wire the module into tracked `.zshrc` with `source ~/.bash/x_cmd.zsh` after the shared profile/fzf. Replace only the live eager x-cmd source with the same module source. Back up the live file under a private temporary directory before editing it.
- [ ] Add a startup integration test using temporary Prezto/shared-profile fixtures and the actual tracked `.zshrc`, verifying first-use behavior and no eager initialization.

### Task 2: Make Kubernetes prompt detection opt-in

**Files:**
- Modify: `prezto/.p10k.zsh`
- Test: `tests/test_shell_startup.py`
- Modify: `README.md`

**Interfaces:**
- Consumes: `DOTFILES_KUBECONTEXT`, outside the `POWERLEVEL9K_*` namespace that the config resets.
- Produces: resolved prompt segment arrays with no `kubecontext` by default, and `kubecontext` restored when the variable equals `1`. Preserve `dir`, `vcs`, and `aws`.

- [ ] Update the existing default resolved-prompt regression to expect `kubecontext` absent while retaining other work context. Run focused unittest discovery and observe the intended assertion failure.
- [ ] Immediately after defining `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`, add:

```zsh
  # Opt in before startup, or export this and source ~/.p10k.zsh to reload.
  if [[ ${DOTFILES_KUBECONTEXT:-0} != 1 ]]; then
    POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS:#kubecontext})
  fi
```

- [ ] Verify the default regression passes. Add and mutation-check the opt-in regression by sourcing the real configuration with `DOTFILES_KUBECONTEXT=1` in a temporary HOME.
- [ ] Document lazy x-cmd behavior and these explicit reload commands in README:

```zsh
export DOTFILES_KUBECONTEXT=1; source ~/.p10k.zsh
unset DOTFILES_KUBECONTEXT; source ~/.p10k.zsh
```

### Task 3: Verify behavior and measure before/after

**Files:**
- Reuse the temporary profiler `/tmp/tab-startup-investigation-20261107.py`; do not commit it.
- Produce before/after timing evidence under a private temporary directory.

- [ ] Run `zsh -n` on modified Zsh files and the live startup file.
- [ ] Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v` and the repository's standalone shell test scripts. Report pre-existing failures and opt-in machine-local skips explicitly.
- [ ] Smoke-test the real installed x-cmd in a disposable Zsh process: absent before first use, native implementation available after `x version current` (also test `CLAUDECODE=1`), and no eager startup work.
- [ ] Run alternating original/optimized PTY startup comparisons with original Prezto source paths and the existing Git-status daemon cache. Reconstruct the original Kubernetes setting only in a temporary copy; never revert the live file to time it.
- [ ] Inspect the final diff, preserve unrelated changes, and report measured startup improvement and the Kubernetes opt-in. Changes apply to new shells; leave existing tabs and the Rex server alone.

## Execution results — 2026-11-07

The requested startup changes are applied to the tracked files and the live
`/Users/sendhil/.zshrc`. Installer-added paths, Git-status, completion caches,
existing tabs, Rex processes, and unrelated working changes were preserved.
The live `.zshrc` and original prompt config are backed up in the private directory
`/tmp/dotfiles-shell-before.dK9f2w/`.

- Focused behavior tests passed. Initial first-use, startup wiring, default prompt,
  and two-stage agent-loader regressions were observed failing before their fixes;
  already-implemented edge-case tests were checked with targeted mutations.
- Native x-cmd 0.7.5 passed `x version current` in ordinary and `CLAUDECODE=1`
  disposable shells. The lazy wrapper delegates to the native `x` function, not
  directly to `___x_cmd`, to preserve the installed two-stage agent loader.
- Per-file `zsh -n` checks passed for the helper, both startup files, and prompt config.
- Latest full Python command ran 38 tests: 30 passed, 8 existing work-local tests
  skipped because `SHELL_STARTUP_LOCAL_CONFIG` was not supplied.
- All 19 standalone portable Herdr checks passed. Thirteen Ghostty checks passed
  across the full-suite run and the separate real-fzf check.
- The full Ghostty suite remains red in the native integration case
  `native Ghostty loads local selection and reset without duplicating icon maps`:
  installed Ghostty resolves two icon mappings where the test expects one.
  The same failure was reproduced from untouched HEAD-only Ghostty files under
  `/tmp/ghostty-baseline.HG6osS/`. No Ghostty source or tests were modified; repair
  is out of scope and requires separate approval. Do not claim an entirely green suite.
- Active LSP checks returned no server answers for the three queried files, so
  they are inconclusive, not a clean diagnostic result. Runtime tests and Zsh
  syntax checks are the confirmed validation evidence.

Sixteen alternating PTY runs, reusing the actual Git-status daemon cache, measured
median full shell readiness of **394.5 ms before → 244.0 ms after (~38% faster)**.
Before range: 370.0–920.3 ms; after range: 234.0–345.6 ms. No Git-status initialization
errors or timeouts occurred. Eager x-cmd work dropped from a median 77.2 ms to a
0.3 ms lazy wrapper, and first-prompt work dropped from 162.5 ms to 93.3 ms.
These are shell readiness measurements, not end-to-end Rex GUI/login timings.

Timing script: `/tmp/compare-shell-startup-20261107.py`.
Raw results: `/tmp/tab-startup-before-after-results-20261107.json`.
Task verification remains open only for the separately tracked pre-existing
Ghostty failure; the requested shell behavior and performance are verified.
