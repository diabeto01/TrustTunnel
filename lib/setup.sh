perform_initial_setup() {
  # Check if initial setup has already been performed
  if [ -f "$SETUP_MARKER_FILE" ]; then
    echo -e "${YELLOW}Initial setup already performed. Skipping prerequisites installation.${RESET}" # Updated message
    # ensure_trust_command_available # Removed as per user request
    return 0 # Exit successfully
  fi

  echo -e "${CYAN}Performing initial setup (installing dependencies)...${RESET}" # Performing initial setup (installing dependencies)...

  # Install required tools
  echo -e "${CYAN}Updating package lists and installing dependencies...${RESET}" # Updating package lists and installing dependencies...
  sudo apt update
  sudo apt install -y build-essential curl pkg-config libssl-dev git figlet certbot rustc cargo cron

  # Default path for the Cargo environment file.
  CARGO_ENV_FILE="$HOME/.cargo/env"

  echo "Checking for Rust installation..." # Checking for Rust installation...

  # Check if 'rustc' command is available in the system's PATH.
  if command -v rustc >/dev/null 2>&1; then
    # If 'rustc' is found, Rust is already installed.
    echo "✅ Rust is already installed: $(rustc --version)" # Rust is already installed: rustc --version
    RUST_IS_READY=true
  else
    # If 'rustc' is not found, start the installation.
    echo "🦀 Rust is not installed. Installing..." # Rust is not installed. Installing...
    RUST_IS_READY=false

    # Download and run the rustup installer.
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
      echo "✅ Rust installed successfully." # Rust installed successfully.

      # Source the Cargo environment file for the current script session.
      if [ -f "$CARGO_ENV_FILE" ]; then
        source "$CARGO_ENV_FILE"
        echo "♻️ Cargo environment file sourced for this script session." # Cargo environment file sourced for this script session.
      else
        # Fallback if the environment file is not found.
        echo "⚠️ Cargo environment file ($CARGO_ENV_FILE) not found. You might need to set PATH manually." # Cargo environment file (CARGO_ENV_FILE) not found. You might need to set PATH manually.
        export PATH="$HOME/.cargo/bin:$PATH"
      fi

      # Display the installed version for confirmation.
      if command -v rustc >/dev/null 2>&1; then
        echo "✅ Installed Rust version: $(rustc --version)" # Installed Rust version: rustc --version
        RUST_IS_READY=true
      else
        echo "❌ Rust is installed but 'rustc' is not available in the current PATH." # Rust is installed but 'rustc' is not available in the current PATH.
      fi

      echo ""
      echo "------------------------------------------------------------------"
      echo "⚠️ Important: To make Rust available in your terminal," # Important: To make Rust available in your terminal,
      echo "    you need to restart your terminal or run this command:" # you need to restart your terminal or run this command:
      echo "    source \"$CARGO_ENV_FILE\""
      echo "    Run this command once in each new terminal session." # Run this command once in each new terminal session.
      echo "------------------------------------------------------------------"

    else
      # Error message if installation fails.
      echo "❌ An error occurred during Rust installation. Please check your internet connection or try again." # An error occurred during Rust installation. Please check your internet connection or try again.
      return 1 # Indicate failure
    fi
  fi

  # ensure_trust_command_available # Removed as per user request
  if [ "$RUST_IS_READY" = true ]; then
    sudo mkdir -p "$(dirname "$SETUP_MARKER_FILE")" # Ensure directory exists for marker file
    sudo touch "$SETUP_MARKER_FILE" # Create marker file only if all initial setup steps (excluding symlink) succeed
    print_success "Initial setup complete." # Initial setup complete.
    return 0
  else
    print_error "Rust is not ready. Skipping setup marker." # Rust is not ready. Skipping setup marker.
    return 1 # Indicate failure
  fi
  echo ""
  return 0
}
