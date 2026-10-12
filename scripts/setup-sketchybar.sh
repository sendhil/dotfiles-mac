#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PYTHONDONTWRITEBYTECODE=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! command -v python3 >/dev/null; then
  if [[ "${1:-}" == --check || "${1:-}" == --restore ]]; then
    echo 'Python 3.9+ is required; install it with brew install python.' >&2
    exit 1
  fi
  command -v brew >/dev/null || { echo 'Install Homebrew first: https://brew.sh' >&2; exit 1; }
  HOMEBREW_NO_AUTO_UPDATE=1 brew install python
fi
exec python3 "$SCRIPT_DIR/sketchybar_setup.py" "$@"
