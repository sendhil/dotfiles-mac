# Defer x-cmd's completion and prompt hooks until the first x command.
# The loader replaces x with its native implementation after initialization.
if [[ -r "$HOME/.x-cmd.root/X" ]] && (( ! $+functions[___x_cmd] )); then
  function x() {
    source "$HOME/.x-cmd.root/X" || return
    # Use the installed entrypoint, including x-cmd's two-stage agent loader.
    'x' "$@"
  }
fi
