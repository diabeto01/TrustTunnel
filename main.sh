#!/bin/bash
set -euo pipefail

# --- Global Paths and Markers ---
TRUST_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$TRUST_SCRIPT_PATH")"
SETUP_MARKER_FILE="/var/lib/trusttunnel/.setup_complete"

# Load shared libraries
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/logs.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/scheduler.sh"
source "$SCRIPT_DIR/lib/setup.sh"
source "$SCRIPT_DIR/lib/install.sh"
source "$SCRIPT_DIR/lib/reverse.sh"
source "$SCRIPT_DIR/lib/direct.sh"
source "$SCRIPT_DIR/lib/certificates.sh"
source "$SCRIPT_DIR/lib/menu.sh"

# Perform initial setup once
perform_initial_setup || { echo "Initial setup failed. Exiting."; exit 1; }

# Check Rust readiness after setup
if command -v rustc >/dev/null 2>&1; then
  RUST_IS_READY=true
else
  RUST_IS_READY=false
fi

if [ "$RUST_IS_READY" = true ]; then
  main_menu
else
  echo ""
  echo "🛑 Rust is not ready. Skipping the main menu."
fi
