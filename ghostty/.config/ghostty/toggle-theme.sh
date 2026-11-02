#!/usr/bin/env bash
# Compatibility entry point: persist the toggle locally, not in the stowed config.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/theme.sh" toggle
