uninstall_trusttunnel_action() {
  clear
  echo ""
  echo -e "${RED}⚠️ Are you sure you want to uninstall TrustTunnel and remove all associated files and services? (y/N): ${RESET}" # Are you sure you want to uninstall TrustTunnel and remove all associated files and services? (y/N):
  read -p "" confirm
  echo ""

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🧹 Uninstalling TrustTunnel..." # Uninstalling TrustTunnel...

    # --- Explicitly handle trusttunnel.service (server) ---
    local server_service_name="trusttunnel.service"
    if systemctl list-unit-files --full --no-pager | grep -q "^$server_service_name"; then
      echo "🛑 Stopping and disabling TrustTunnel server service ($server_service_name)..." # Stopping and disabling TrustTunnel server service (server_service_name)...
      sudo systemctl stop "$server_service_name" > /dev/null 2>&1
      sudo systemctl disable "$server_service_name" > /dev/null 2>&1
      sudo rm -f "/etc/systemd/system/$server_service_name" > /dev/null 2>&1
      print_success "TrustTunnel server service removed." # TrustTunnel server service removed.
    else
      echo "⚠️ TrustTunnel server service ($server_service_name) not found. Skipping." # TrustTunnel server service (server_service_name) not found. Skipping.
    fi

    # Find and remove all trusttunnel-* services (clients)
    echo "Searching for TrustTunnel client services to remove..." # Searching for TrustTunnel client services to remove...
    # List all unit files that start with 'trusttunnel-'
    mapfile -t trusttunnel_client_services < <(sudo systemctl list-unit-files --full --no-pager | grep '^trusttunnel-.*\.service' | awk '{print $1}')

    if [ ${#trusttunnel_client_services[@]} -gt 0 ]; then
      echo "🛑 Stopping and disabling TrustTunnel client services..." # Stopping and disabling TrustTunnel client services...
      for service_file in "${trusttunnel_client_services[@]}"; do
        local service_name=$(basename "$service_file") # Get just the service name from the file path
        echo "  - Processing $service_name..." # Processing service_name...
        sudo systemctl stop "$service_name" > /dev/null 2>&1
        sudo systemctl disable "$service_name" > /dev/null 2>&1
        sudo rm -f "/etc/systemd/system/$service_name" > /dev/null 2>&1
      done
      print_success "All TrustTunnel client services have been stopped, disabled, and removed." # All TrustTunnel client services have been stopped, disabled, and removed.
    else
      echo "⚠️ No TrustTunnel client services found to remove." # No TrustTunnel client services found to remove.
    fi

    sudo systemctl daemon-reload # Reload daemon after removing services

    # Remove rstun folder if exists
    if [ -d "rstun" ]; then
      echo "🗑️ Removing 'rstun' folder..." # Removing 'rstun' folder...
      rm -rf rstun
      print_success "'rstun' folder removed successfully." # 'rstun' folder removed successfully.
    else
      echo "⚠️ 'rstun' folder not found." # 'rstun' folder not found.
    fi

    # Remove TrustTunnel related cron jobs
    echo -e "${CYAN}🧹 Removing any associated TrustTunnel cron jobs...${RESET}" # Removing any associated TrustTunnel cron jobs...
    (sudo crontab -l 2>/dev/null | grep -v "# TrustTunnel automated restart for") | sudo crontab -
    print_success "Associated cron jobs removed." # Associated cron jobs removed.

    # Remove 'trust' command symlink (if it was ever created, though it shouldn't be now)
    if [ -L "$TRUST_COMMAND_PATH" ]; then # Check if it's a symbolic link
      echo "🗑️ Removing 'trust' command symlink..." # Removing 'trust' command symlink...
      sudo rm -f "$TRUST_COMMAND_PATH"
      print_success "'trust' command symlink removed." # 'trust' command symlink removed.
    fi
    # Remove setup marker file
    if [ -f "$SETUP_MARKER_FILE" ]; then
      echo "🗑️ Removing setup marker file..." # Removing setup marker file...
      sudo rm -f "$SETUP_MARKER_FILE"
      print_success "Setup marker file removed." # Setup marker file removed.
    fi

    print_success "TrustTunnel uninstallation complete." # TrustTunnel uninstallation complete.
  else
    echo -e "${YELLOW}❌ Uninstall cancelled.${RESET}" # Uninstall cancelled.
  fi
  echo ""
  echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
  read -p ""
}

# --- Install TrustTunnel Action ---
install_trusttunnel_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     📥 Installing TrustTunnel${RESET}" # Installing TrustTunnel
  draw_line "$CYAN" "=" 40
  echo ""

  # Delete existing rstun folder if it exists
  if [ -d "rstun" ]; then
    echo -e "${YELLOW}🧹 Removing existing 'rstun' folder...${RESET}" # Removing existing 'rstun' folder...
    rm -rf rstun
    print_success "Existing 'rstun' folder removed." # Existing 'rstun' folder removed.
  fi

  echo -e "${CYAN}🚀 Detecting system architecture...${RESET}" # Detecting system architecture...
  local arch=$(uname -m)
  local download_url=""
  local filename=""
  local supported_arch=true # Flag to track if architecture is directly supported

  case "$arch" in
    "x86_64")
      filename="rstun-linux-x86_64.tar.gz"
      ;;
    "aarch64" | "arm64")
      filename="rstun-linux-aarch64.tar.gz"
      ;;
    "armv7l") # Corrected filename for armv7l
      filename="rstun-linux-armv7.tar.gz"
      ;;
    *)
      supported_arch=false # Mark as unsupported
      echo -e "${RED}❌ Error: Unsupported architecture detected: $arch${RESET}" # Error: Unsupported architecture detected: arch
      echo -e "${YELLOW}Do you want to try installing the x86_64 version as a fallback? (y/N): ${RESET}" # Do you want to try installing the x86_64 version as a fallback? (y/N):
      read -p "" fallback_confirm
      echo ""
      if [[ "$fallback_confirm" =~ ^[Yy]$ ]]; then
        filename="rstun-linux-x86_64.tar.gz"
        echo -e "${CYAN}Proceeding with x86_64 version as requested.${RESET}" # Proceeding with x86_64 version as requested.
      else
        echo -e "${YELLOW}Installation cancelled. Please download rstun manually for your system from https://github.com/neevek/rstun/releases${RESET}" # Installation cancelled. Please download rstun manually for your system from https://github.com/neevek/rstun/releases
        echo ""
        echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
        read -p ""
        return 1 # Indicate failure
      fi
      ;;
  esac

  download_url="https://github.com/neevek/rstun/releases/download/release%2F0.7.1/${filename}"

  echo -e "${CYAN}Downloading $filename for $arch...${RESET}" # Downloading filename for arch...
  if wget -q --show-progress "$download_url" -O "$filename"; then
    print_success "Download complete!" # Download complete!
  else
    echo -e "${RED}❌ Error: Failed to download $filename. Please check your internet connection or the URL.${RESET}" # Error: Failed to download filename. Please check your internet connection or the URL.
    echo ""
    echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
    read -p ""
    return 1 # Indicate failure
  fi

  echo -e "${CYAN}📦 Extracting files...${RESET}" # Extracting files...
  if tar -xzf "$filename"; then
    mv "${filename%.tar.gz}" rstun # Rename extracted folder to 'rstun'
    print_success "Extraction complete!" # Extraction complete!
  else
    echo -e "${RED}❌ Error: Failed to extract $filename. Corrupted download?${RESET}" # Error: Failed to extract filename. Corrupted download?
    echo ""
    echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
    read -p ""
    return 1 # Indicate failure
  fi

  echo -e "${CYAN}➕ Setting execute permissions...${RESET}" # Setting execute permissions...
  find rstun -type f -exec chmod +x {} \;
  print_success "Permissions set." # Permissions set.

  echo -e "${CYAN}🗑️ Cleaning up downloaded archive...${RESET}" # Cleaning up downloaded archive...
  rm "$filename"
  print_success "Cleanup complete." # Cleanup complete.

  echo ""
  print_success "TrustTunnel installation complete!" # TrustTunnel installation complete!
  # ensure_trust_command_available # Removed as per user request
  echo ""
  echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
  read -p ""
}

# --- Add New Server Action (Beautified) ---
