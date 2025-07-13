#!/bin/bash


# --- Global Paths and Markers ---
# Use readlink -f to get the canonical path of the script, resolving symlinks and /dev/fd/ issues
TRUST_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$TRUST_SCRIPT_PATH")"
SETUP_MARKER_FILE="/var/lib/trusttunnel/.setup_complete"
# TRUST_COMMAND_PATH="/usr/local/bin/trust" # Removed as per user request

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/logs.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/scheduler.sh"



# --- Function to ensure 'trust' command symlink exists ---
# This function is now removed as per user request.
# ensure_trust_command_available() {
#   echo -e "${CYAN}Checking 'trust' command symlink status...${RESET}"
#
#   local symlink_ok=false
#   local current_symlink_target=$(readlink "$TRUST_COMMAND_PATH" 2>/dev/null)
#
#   if [[ "$current_symlink_target" == /dev/fd/* ]]; then
#     print_error "❌ Warning: The existing 'trust' symlink points to a temporary location ($current_symlink_target)."
#     print_error "   This can happen if the script was run in a non-standard way (e.g., piped to bash)."
#     print_error "   Attempting to fix it by recreating the symlink to the permanent script path."
#   fi
#
#   sudo mkdir -p "$(dirname "$TRUST_COMMAND_PATH")"
#   if sudo ln -sf "$TRUST_SCRIPT_PATH" "$TRUST_COMMAND_PATH"; then
#     print_success "Attempted to create/update 'trust' command symlink."
#     if [ -L "$TRUST_COMMAND_PATH" ] && [ "$(readlink "$TRUST_COMMAND_PATH" 2>/dev/null)" = "$TRUST_SCRIPT_PATH" ]; then
#       symlink_ok=true
#     Fİ
#   else
#     print_error "Failed to create/update 'trust' command symlink initially. Check permissions."
#   fi
#
#   if [ "$symlink_ok" = true ]; then
#     print_success "'trust' command symlink is correctly set up."
#     return 0
#   else
#     print_error "❌ Critical Error: The 'trust' command symlink is not properly set up or accessible."
#     print_error "   This means the 'trust' command will not work."
#     print_error "   Please try the following manual steps to fix it:"
#     echo -e "${WHITE}   1. Ensure you are running this script directly from its file path (e.g., 'sudo bash /path/to/your_script.sh')."
#     echo -e "${WHITE}   2. Run: sudo ln -sf \"$TRUST_SCRIPT_PATH\" \"$TRUST_COMMAND_PATH\"${RESET}"
#     echo -e "${WHITE}   3. Check your PATH: echo \$PATH${RESET}"
#     echo -e "${WHITE}      Ensure '/usr/local/bin' is in your PATH. If not, add it to your shell's config (e.g., ~/.bashrc, ~/.zshrc):${RESET}"
#     echo -e "${WHITE}      export PATH=\"/usr/local/bin:\$PATH\"${RESET}"
#     echo -e "${WHITE}   4. After making changes, restart your terminal or run: source ~/.bashrc (or your shell's config file)${RESET}"
#     sleep 5
#     return 1
#   fi
# }



# --- Uninstall TrustTunnel Action ---
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
add_new_server_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ➕ Add New TrustTunnel Server${RESET}" # Add New TrustTunnel Server
  draw_line "$CYAN" "=" 40
  echo ""

  if [ ! -f "rstun/rstund" ]; then
    echo -e "${RED}❗ Server build (rstun/rstund) not found.${RESET}" # Server build (rstun/rstund) not found.
    echo -e "${YELLOW}Please run 'Install TrustTunnel' option from the main menu first.${RESET}" # Please run 'Install TrustTunnel' option from the main menu first.
    echo ""
    echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
    read -p ""
    return # Use return instead of continue in a function
  fi

  local tls_enabled="true" # Default to true (recommended)
  echo -e "${CYAN}🔒 TLS/SSL Mode Configuration:${RESET}"
  echo -e "  (It's highly recommended to enable TLS for secure communication.)"
  echo -e "👉 ${WHITE}Do you want to enable TLS/SSL for this server? (Y/n, default: Y):${RESET} "
  read -p "" tls_choice_input
  tls_choice_input=${tls_choice_input:-Y} # Default to Y if empty

  if [[ "$tls_choice_input" =~ ^[Nn]$ ]]; then
    tls_enabled="false"
    print_error "TLS/SSL is disabled. Communication will not be encrypted."
    echo ""
    echo -e "${YELLOW}Press Enter to continue without TLS...${RESET}"
    read -p ""
  else
    print_success "TLS/SSL is enabled. Proceeding with certificate configuration."
    echo ""
  fi

  local cert_path=""
  local cert_args=""

  if [[ "$tls_enabled" == "true" ]]; then
    # لیست کردن certificate های موجود
    local certs_dir="/etc/letsencrypt/live"
    if [ ! -d "$certs_dir" ]; then
      echo -e "${RED}❌ No certificates directory found at $certs_dir.${RESET}"
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi

    # Find directories under /etc/letsencrypt/live/ that are not 'README'
    # and get their base names (which are the domain names)
    mapfile -t cert_domains < <(sudo find "$certs_dir" -maxdepth 1 -mindepth 1 -type d ! -name "README" -exec basename {} \;)

    if [ ${#cert_domains[@]} -eq 0 ]; then
      echo -e "${RED}❌ No SSL certificates found.${RESET}"
      echo -e "${YELLOW}Please create one from the 'Certificate management' menu first.${RESET}"
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi

    echo -e "${CYAN}Available SSL Certificates:${RESET}"
    for i in "${!cert_domains[@]}"; do
      echo -e "  ${YELLOW}$((i+1)))${RESET} ${WHITE}${cert_domains[$i]}${RESET}"
    done

    local cert_choice
    while true; do
      echo -e "👉 ${WHITE}Select a certificate by number:${RESET} "
      read -p "" cert_choice
      if [[ "$cert_choice" =~ ^[0-9]+$ ]] && [ "$cert_choice" -ge 1 ] && [ "$cert_choice" -le ${#cert_domains[@]} ]; then
        break
      else
        print_error "Invalid selection. Please enter a valid number."
      fi
    done
    local selected_domain_name="${cert_domains[$((cert_choice-1))]}"
    cert_path="$certs_dir/$selected_domain_name"
    echo -e "${GREEN}Selected certificate: $selected_domain_name (Path: $cert_path)${RESET}"
    echo ""

    if [ ! -d "$cert_path" ]; then
      echo -e "${RED}❌ SSL certificate not available. Server setup aborted.${RESET}"
      echo ""
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi
    cert_args="--cert \"$cert_path/fullchain.pem\" --key \"$cert_path/privkey.pem\""
  else
    echo -e "${YELLOW}Skipping SSL certificate selection as TLS is disabled.${RESET}"
    echo ""
  fi

  echo -e "${CYAN}⚙️ Server Configuration:${RESET}" # Server Configuration:
  echo -e "  (Default tunneling address port is 6060)"
  
  # Validate Listen Port
  local listen_port
  while true; do
    echo -e "👉 ${WHITE}Enter tunneling address port (1-65535, default 6060):${RESET} " # Enter tunneling address port (1-65535, default 6060):
    read -p "" listen_port_input
    listen_port=${listen_port_input:-6060} # Apply default if empty
    if validate_port "$listen_port"; then
      break
    else
      print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
    fi
  done

  echo -e "  (Default TCP upstream port is 8800)"
  # Validate TCP Upstream Port
  local tcp_upstream_port
  while true; do
    echo -e "👉 ${WHITE}Enter TCP upstream port (1-65535, default 8800):${RESET} " # Enter TCP upstream port (1-65535, default 8800):
    read -p "" tcp_upstream_port_input
    tcp_upstream_port=${tcp_upstream_port_input:-8800} # Apply default if empty
    if validate_port "$tcp_upstream_port"; then
      break
    else
      print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
    fi
  done

  echo -e "  (Default UDP upstream port is 8800)"
  # Validate UDP Upstream Port
  local udp_upstream_port
  while true; do
    echo -e "👉 ${WHITE}Enter UDP upstream port (1-65535, default 8800):${RESET} " # Enter UDP upstream port (1-65535, default 8800):
    read -p "" udp_upstream_port_input
    udp_upstream_port=${udp_upstream_port_input:-8800} # Apply default if empty
    if validate_port "$udp_upstream_port"; then
      break
    else
      print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
    fi
  done

  echo -e "👉 ${WHITE}Enter password:${RESET} " # Enter password:
  read -p "" password
  echo ""

  if [[ -z "$password" ]]; then
    echo -e "${RED}❌ Password cannot be empty!${RESET}" # Password cannot be empty!
    echo ""
    echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
    read -p ""
    return # Use return instead of exit 1
  fi

  local service_file="/etc/systemd/system/trusttunnel.service"

  if systemctl is-active --quiet trusttunnel.service || systemctl is-enabled --quiet trusttunnel.service; then
    echo -e "${YELLOW}🛑 Stopping existing Trusttunnel service...${RESET}" # Stopping existing Trusttunnel service...
    sudo systemctl stop trusttunnel.service > /dev/null 2>&1
    echo -e "${YELLOW}🗑️ Disabling and removing existing Trusttunnel service...${RESET}" # Disabling and removing existing Trusttunnel service...
    sudo systemctl disable trusttunnel.service > /dev/null 2>&1
    sudo rm -f /etc/systemd/system/trusttunnel.service > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1
    print_success "Existing TrustTunnel service removed." # TrustTunnel service removed.
  fi

  cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=TrustTunnel Service
After=network.target

[Service]
Type=simple
ExecStart=$(pwd)/rstun/rstund --addr 0.0.0.0:$listen_port --tcp-upstream $tcp_upstream_port --udp-upstream $udp_upstream_port --password "$password" $cert_args --quic-timeout-ms 1000 --tcp-timeout-ms 1000 --udp-timeout-ms 1000
Restart=always
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

  echo -e "${CYAN}🔧 Reloading systemd daemon...${RESET}" # Reloading systemd daemon...
  sudo systemctl daemon-reload

  echo -e "${CYAN}🚀 Enabling and starting Trusttunnel service...${RESET}" # Enabling and starting Trusttunnel service...
  sudo systemctl enable trusttunnel.service > /dev/null 2>&1
  sudo systemctl start trusttunnel.service > /dev/null 2>&1

  print_success "TrustTunnel service started successfully!" # TrustTunnel service started successfully!


  echo ""
  echo -e "${YELLOW}Do you want to view the logs for trusttunnel.service now? (y/N): ${RESET}" # Do you want to view the logs for trusttunnel.service now? (y/N):
  read -p "" view_logs_choice
  echo ""

  if [[ "$view_logs_choice" =~ ^[Yy]$ ]]; then
    show_service_logs trusttunnel.service
  fi

  echo ""
  
  echo -e "${YELLOW}Press Enter to return to main menu...${RESET}" # Press Enter to return to main menu...
  read -p ""
}

add_new_client_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ➕ Add New TrustTunnel Client${RESET}" # Add New TrustTunnel Client
  draw_line "$CYAN" "=" 40
  echo ""

  # Prompt for the client name (e.g., asiatech, respina, server2)
  echo -e "👉 ${WHITE}Enter client name (e.g., asiatech, respina, server2):${RESET} " # Enter client name (e.g., asiatech, respina, server2):
  read -p "" client_name
  echo ""

  # Construct the service name based on the client name
  service_name="trusttunnel-$client_name"
  # Define the path for the systemd service file
  service_file="/etc/systemd/system/${service_name}.service"

  # Check if a service with the given name already exists
  if [ -f "$service_file" ]; then
    echo -e "${RED}❌ Service with this name already exists.${RESET}" # Service with this name already exists.
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
    return # Return to menu
  fi

  echo -e "${CYAN}🌐 Server Connection Details:${RESET}" # Server Connection Details:
  echo -e "  (e.x., server.yourdomain.com:6060)"
  
  # Validate Server Address
  local server_addr
  while true; do
    echo -e "👉 ${WHITE}Server address and port (e.g., server.yourdomain.com:6060 or 192.168.1.1:6060):${RESET} " # Server address and port (e.g., server.yourdomain.com:6060 or 192.168.1.1:6060):
    read -p "" server_addr_input
    # Split into host and port for validation
    local host_part=$(echo "$server_addr_input" | cut -d':' -f1)
    local port_part=$(echo "$server_addr_input" | cut -d':' -f2)

    if validate_host "$host_part" && validate_port "$port_part"; then
      server_addr="$server_addr_input"
      break
    else
      print_error "Invalid server address or port format. Please use 'host:port' (e.g., example.com:6060)." # Invalid server address or port format. Please use 'host:port' (e.g., example.com:6060).
    fi
  done
  echo ""

  echo -e "${CYAN}📡 Tunnel Mode:${RESET}" # Tunnel Mode:
  echo -e "  (tcp/udp/both)"
  echo -e "👉 ${WHITE}Tunnel mode ? (tcp/udp/both):${RESET} " # Tunnel mode ? (tcp/udp/both):
  read -p "" tunnel_mode
  echo ""

  echo -e "🔑 ${WHITE}Password:${RESET} " # Password:
  read -p "" password
  echo ""

  echo -e "${CYAN}🔢 Port Mapping Configuration:${RESET}" # Port Mapping Configuration:
  
  local port_count
  while true; do
    echo -e "👉 ${WHITE}How many ports to tunnel?${RESET} " # How many ports to tunnel?
    read -p "" port_count_input
    if [[ "$port_count_input" =~ ^[0-9]+$ ]] && (( port_count_input >= 0 )); then
      port_count=$port_count_input
      break
    else
      print_error "Invalid input. Please enter a non-negative number for port count." # Invalid input. Please enter a non-negative number for port count.
    fi
  done
  echo ""
  
  mappings=""
  for ((i=1; i<=port_count; i++)); do
    local port
    while true; do
      echo -e "👉 ${WHITE}Enter Port #$i (1-65535):${RESET} " # Enter Port #i (1-65535):
      read -p "" port_input
      if validate_port "$port_input"; then
        port="$port_input"
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
      fi
    done
    mapping="IN^0.0.0.0:$port^0.0.0.0:$port"
    [ -z "$mappings" ] && mappings="$mapping" || mappings="$mappings,$mapping"
    echo ""
  done

  # Determine the mapping arguments based on the tunnel_mode
  mapping_args=""
  case "$tunnel_mode" in
    "tcp")
      mapping_args="--tcp-mappings \"$mappings\""
      ;;
    "udp")
      mapping_args="--udp-mappings \"$mappings\""
      ;;
    "both")
      mapping_args="--tcp-mappings \"$mappings\" --udp-mappings \"$mappings\""
      ;;
    *)
      echo -e "${YELLOW}⚠️ Invalid tunnel mode specified. Using 'both' as default.${RESET}" # Invalid tunnel mode specified. Using 'both' as default.
      mapping_args="--tcp-mappings \"$mappings\" --udp-mappings \"$mappings\""
      ;;
  esac

  # Create the systemd service file using a here-document
  cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=TrustTunnel Client - $client_name
After=network.target

[Service]
Type=simple
ExecStart=$(pwd)/rstun/rstunc --server-addr "$server_addr" --password "$password" $mapping_args --quic-timeout-ms 1000 --tcp-timeout-ms 1000 --udp-timeout-ms 1000 --wait-before-retry-ms 3000
Restart=always
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

  echo -e "${CYAN}🔧 Reloading systemd daemon...${RESET}" # Reloading systemd daemon...
  sudo systemctl daemon-reload

  echo -e "${CYAN}🚀 Enabling and starting Trusttunnel client service...${RESET}" # Enabling and starting Trusttunnel client service...
  sudo systemctl enable "$service_name" > /dev/null 2>&1
  sudo systemctl start "$service_name" > /dev/null 2>&1

  print_success "Client '$client_name' started as $service_name" # Client 'client_name' started as service_name
  echo ""
  echo -e "${YELLOW}Do you want to view the logs for $client_name now? (y/N): ${RESET}" # Do you want to view the logs for client_name now? (y/N):
  read -p "" view_logs_choice
  echo ""

  if [[ "$view_logs_choice" =~ ^[Yy]$ ]]; then
    show_service_logs "$service_name"
  fi
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
  read -p ""
}

# --- Initial Setup Function ---
# This function performs one-time setup tasks like installing dependencies
# and creating the 'trust' command symlink.
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

# --- Add New Direct Server Action ---
add_new_direct_server_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}        ➕ Add New Direct Server${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""
  
  if [ ! -f "rstun/rstund" ]; then
    echo -e "${RED}❗ Server build (rstun/rstund) not found.${RESET}"
    echo -e "${YELLOW}Please run 'Install TrustTunnel' option from the main menu first.${RESET}"
    echo ""
    echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
    read -p ""
    return
  fi

  local tls_enabled="true" # Default to true (recommended)
  echo -e "${CYAN}🔒 TLS/SSL Mode Configuration:${RESET}"
  echo -e "  (It's highly recommended to enable TLS for secure communication.)"
  echo -e "👉 ${WHITE}Do you want to enable TLS/SSL for this server? (Y/n, default: Y):${RESET} "
  read -p "" tls_choice_input
  tls_choice_input=${tls_choice_input:-Y} # Default to Y if empty

  if [[ "$tls_choice_input" =~ ^[Nn]$ ]]; then
    tls_enabled="false"
    print_error "TLS/SSL is disabled. Communication will not be encrypted."
    echo ""
    echo -e "${YELLOW}Press Enter to continue without TLS...${RESET}"
    read -p ""
  else
    print_success "TLS/SSL is enabled. Proceeding with certificate configuration."
    echo ""
  fi

  local cert_path=""
  local cert_args=""

  if [[ "$tls_enabled" == "true" ]]; then
    # لیست کردن certificate های موجود
    local certs_dir="/etc/letsencrypt/live"
    if [ ! -d "$certs_dir" ]; then
      echo -e "${RED}❌ No certificates directory found at $certs_dir.${RESET}"
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi

    mapfile -t cert_domains < <(sudo find "$certs_dir" -maxdepth 1 -mindepth 1 -type d ! -name "README" -exec basename {} \;)

    if [ ${#cert_domains[@]} -eq 0 ]; then
      echo -e "${RED}❌ No SSL certificates found.${RESET}"
      echo -e "${YELLOW}Please create one from the 'Certificate management' menu first.${RESET}"
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi

    echo -e "${CYAN}Available SSL Certificates:${RESET}"
    for i in "${!cert_domains[@]}"; do
      echo -e "  ${YELLOW}$((i+1)))${RESET} ${WHITE}${cert_domains[$i]}${RESET}"
    done

    local cert_choice
    while true; do
      echo -e "👉 ${WHITE}Select a certificate by number:${RESET} "
      read -p "" cert_choice
      if [[ "$cert_choice" =~ ^[0-9]+$ ]] && [ "$cert_choice" -ge 1 ] && [ "$cert_choice" -le ${#cert_domains[@]} ]; then
        break
      else
        print_error "Invalid selection. Please enter a valid number."
      fi
    done
    local selected_domain_name="${cert_domains[$((cert_choice-1))]}"
    cert_path="$certs_dir/$selected_domain_name"
    echo -e "${GREEN}Selected certificate: $selected_domain_name (Path: $cert_path)${RESET}"
    echo ""

    if [ ! -d "$cert_path" ]; then
      echo -e "${RED}❌ SSL certificate not available. Server setup aborted.${RESET}"
      echo ""
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi
    cert_args="--cert \"$cert_path/fullchain.pem\" --key \"$cert_path/privkey.pem\""
  else
    echo -e "${YELLOW}Skipping SSL certificate selection as TLS is disabled.${RESET}"
    echo ""
  fi

  # Proceed only if certificate acquisition was successful or it already existed
  # The check for cert_path existence is now inside the tls_enabled block
  # so this outer if is no longer needed.
  # if [ -d "$cert_path" ] || [[ "$tls_enabled" == "false" ]]; then # This condition is now implicitly handled by the above logic

    echo -e "${CYAN}⚙️ Server Configuration:${RESET}"
    echo -e "  (Default listen port is 8800)"
    
    # Validate Listen Port
    local listen_port
    while true; do
      echo -e "👉 ${WHITE}Enter listen port (1-65535, default 8800):${RESET} "
      read -p "" listen_port_input
      listen_port=${listen_port_input:-8800}
      if validate_port "$listen_port"; then
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535."
      fi
    done
    echo -e "  (Default TCP upstream port is 8800)"
    # Validate TCP Upstream Port
    local tcp_upstream_port
    while true; do
      echo -e "👉 ${WHITE}Enter TCP upstream port (1-65535, default 2030):${RESET} " # Enter TCP upstream port (1-65535, default 8800):
      read -p "" tcp_upstream_port_input
      tcp_upstream_port=${tcp_upstream_port_input:-2030} # Apply default if empty
      if validate_port "$tcp_upstream_port"; then
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
      fi
    done

    echo -e "  (Default UDP upstream port is 8800)"
    # Validate UDP Upstream Port
    local udp_upstream_port
    while true; do
      echo -e "👉 ${WHITE}Enter UDP upstream port (1-65535, default 2040):${RESET} " # Enter UDP upstream port (1-65535, default 8800):
      read -p "" udp_upstream_port_input
      udp_upstream_port=${udp_upstream_port_input:-2040} # Apply default if empty
      if validate_port "$udp_upstream_port"; then
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
      fi
      done



    echo -e "👉 ${WHITE}Enter password:${RESET} "
    read -p "" password
    echo ""

    if [[ -z "$password" ]]; then
      echo -e "${RED}❌ Password cannot be empty!${RESET}"
      echo ""
      echo -e "${YELLOW}Press Enter to return to main menu...${RESET}"
      read -p ""
      return
    fi

    local service_file="/etc/systemd/system/trusttunnel-direct.service"

    if systemctl is-active --quiet trusttunnel-direct.service || systemctl is-enabled --quiet trusttunnel-direct.service; then
      echo -e "${YELLOW}🛑 Stopping existing Direct Trusttunnel service...${RESET}"
      sudo systemctl stop trusttunnel-direct.service > /dev/null 2>&1
      sudo systemctl disable trusttunnel-direct.service > /dev/null 2>&1
      sudo rm -f /etc/systemd/system/trusttunnel-direct.service > /dev/null 2>&1
      sudo systemctl daemon-reload > /dev/null 2>&1
      print_success "Existing Direct TrustTunnel service removed."
    fi

    cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=Direct TrustTunnel Service
After=network.target

[Service]
Type=simple
ExecStart=$(pwd)/rstun/rstund --addr 0.0.0.0:$listen_port --password "$password" --tcp-upstream $tcp_upstream_port --udp-upstream $udp_upstream_port $cert_args --quic-timeout-ms 1000 --tcp-timeout-ms 1000 --udp-timeout-ms 1000
Restart=always
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${CYAN}🔧 Reloading systemd daemon...${RESET}"
    sudo systemctl daemon-reload

    echo -e "${CYAN}🚀 Enabling and starting Direct Trusttunnel service...${RESET}"
    sudo systemctl enable trusttunnel-direct.service > /dev/null 2>&1
    sudo systemctl start trusttunnel-direct.service > /dev/null 2>&1

    print_success "Direct TrustTunnel service started successfully!"
  # else # This else block is no longer needed due to the early return in the TLS section
  #   echo -e "${RED}❌ SSL certificate not available. Server setup aborted.${RESET}"
  # fi




  echo ""
  echo -e "${YELLOW}Do you want to view the logs for trusttunnel-direct.service now? (y/N): ${RESET}" # Do you want to view the logs for trusttunnel.service now? (y/N):
  read -p "" view_logs_choice
  echo ""

  if [[ "$view_logs_choice" =~ ^[Yy]$ ]]; then
    show_service_logs trusttunnel-direct.service
  fi

  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}

# --- Add New Direct Client Action ---
add_new_direct_client_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}        ➕ Add New Direct Client${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""

  # Prompt for the client name
  echo -e "👉 ${WHITE}Enter client name (e.g., client1, client2):${RESET} "
  read -p "" client_name
  echo ""

  # Construct the service name based on the client name
  service_name="trusttunnel-direct-client-$client_name"
  # Define the path for the systemd service file
  service_file="/etc/systemd/system/${service_name}.service"

  # Check if a service with the given name already exists
  if [ -f "$service_file" ]; then
    echo -e "${RED}❌ Service with this name already exists.${RESET}"
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return
  fi

  echo -e "${CYAN}🌐 Server Connection Details:${RESET}"
  echo -e "  (e.x., server.yourdomain.com:8800)"
  
  # Validate Server Address
  local server_addr
  while true; do
    echo -e "👉 ${WHITE}Server address and port (e.g., server.yourdomain.com:8800 or 192.168.1.1:8800):${RESET} " # Server address and port (e.g., server.yourdomain.com:8800 or 192.168.1.1:8800):
    read -p "" server_addr_input
    # Split into host and port for validation
    local host_part=$(echo "$server_addr_input" | cut -d':' -f1)
    local port_part=$(echo "$server_addr_input" | cut -d':' -f2)

    if validate_host "$host_part" && validate_port "$port_part"; then
      server_addr="$server_addr_input"
      break
    else
      print_error "Invalid server address or port format. Please use 'host:port' (e.g., example.com:8800)." # Invalid server address or port format. Please use 'host:port' (e.g., example.com:8800).
    fi
  done
  echo ""

  echo -e "${CYAN}📡 Tunnel Mode:${RESET}" # Tunnel Mode:
  echo -e "  (tcp/udp/both)"
  echo -e "👉 ${WHITE}Tunnel mode ? (tcp/udp/both):${RESET} " # Tunnel mode ? (tcp/udp/both):
  read -p "" tunnel_mode
  echo ""

  echo -e "🔑 ${WHITE}Password:${RESET} " # Password:
  read -p "" password
  echo ""

  echo -e "${CYAN}🔢 Port Mapping Configuration:${RESET}" # Port Mapping Configuration:
  
  local port_count
  while true; do
    echo -e "👉 ${WHITE}How many ports to tunnel?${RESET} " # How many ports to tunnel?
    read -p "" port_count_input
    if [[ "$port_count_input" =~ ^[0-9]+$ ]] && (( port_count_input >= 0 )); then
      port_count=$port_count_input
      break
    else
      print_error "Invalid input. Please enter a non-negative number for port count." # Invalid input. Please enter a non-negative number for port count.
    fi
  done
  echo ""
  
  mappings=""
  for ((i=1; i<=port_count; i++)); do
    local port
    while true; do
      echo -e "👉 ${WHITE}Enter Port #$i (1-65535):${RESET} " # Enter Port #i (1-65535):
      read -p "" port_input
      if validate_port "$port_input"; then
        port="$port_input"
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535." # Invalid port number. Please enter a number between 1 and 65535.
      fi
    done
    mapping="OUT^0.0.0.0:$port^$port"
    [ -z "$mappings" ] && mappings="$mapping" || mappings="$mappings,$mapping"
    echo ""
  done

  # Determine the mapping arguments based on the tunnel_mode
  mapping_args=""
  case "$tunnel_mode" in
    "tcp")
      mapping_args="--tcp-mappings \"$mappings\""
      ;;
    "udp")
      mapping_args="--udp-mappings \"$mappings\""
      ;;
    "both")
      mapping_args="--tcp-mappings \"$mappings\" --udp-mappings \"$mappings\""
      ;;
    *)
      echo -e "${YELLOW}⚠️ Invalid tunnel mode specified. Using 'both' as default.${RESET}" # Invalid tunnel mode specified. Using 'both' as default.
      mapping_args="--tcp-mappings \"$mappings\" --udp-mappings \"$mappings\""
      ;;
  esac

  # Create the systemd service file
  cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=Direct TrustTunnel Client - $client_name
After=network.target

[Service]
Type=simple
ExecStart=$(pwd)/rstun/rstunc --server-addr "$server_addr" --password "$password" $mapping_args --quic-timeout-ms 1000 --tcp-timeout-ms 1000 --udp-timeout-ms 1000 --wait-before-retry-ms 3000
Restart=always
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

  echo -e "${CYAN}🔧 Reloading systemd daemon...${RESET}" # Reloading systemd daemon...
  sudo systemctl daemon-reload

  echo -e "${CYAN}🚀 Enabling and starting Direct Trusttunnel client service...${RESET}" # Enabling and starting Direct Trusttunnel client service...
  sudo systemctl enable "$service_name" > /dev/null 2>&1
  sudo systemctl start "$service_name" > /dev/null 2>&1

  print_success "Direct client '$client_name' started as $service_name"
  echo ""
  echo -e "${YELLOW}Do you want to view the logs for $client_name now? (y/N): ${RESET}" # Do you want to view the logs for client_name now? (y/N):
  read -p "" view_logs_choice
  echo ""

  if [[ "$view_logs_choice" =~ ^[Yy]$ ]]; then
    show_service_logs "$service_name"
  fi
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
  read -p ""
}

# --- New: Function to get a new SSL certificate using Certbot ---
get_new_certificate_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ➕ Get New SSL Certificate${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""

  echo -e "${CYAN}🌐 Domain and Email for SSL Certificate:${RESET}"
  echo -e "  (e.g., yourdomain.com)"
  
  local domain
  while true; do
    echo -e "👉 ${WHITE}Please enter your domain:${RESET} "
    read -p "" domain
    if validate_host "$domain"; then
      break
    else
      print_error "Invalid domain or IP address format. Please try again."
    fi
  done
  echo ""

  local email
  while true; do
    echo -e "👉 ${WHITE}Please enter your email:${RESET} "
    read -p "" email
    if validate_email "$email"; then
      break
    else
      print_error "Invalid email format. Please try again."
    fi
  done
  echo ""

  local cert_path="/etc/letsencrypt/live/$domain"

  if [ -d "$cert_path" ]; then
    print_success "SSL certificate for $domain already exists. Skipping Certbot."
  else
    echo -e "${CYAN}🔐 Requesting SSL certificate with Certbot...${RESET}"
    echo -e "${YELLOW}Ensure port 80 is open and not in use by another service.${RESET}"
    if sudo certbot certonly --standalone -d "$domain" --non-interactive --agree-tos -m "$email"; then
      print_success "SSL certificate obtained successfully for $domain."
    else
      print_error "❌ Failed to obtain SSL certificate for $domain. Check Certbot logs for details."
      print_error "   Ensure your domain points to this server and port 80 is open."
    fi
  fi
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}

# --- New: Function to delete existing SSL certificates ---
delete_certificates_action() {
  clear
  echo ""
  draw_line "$RED" "=" 40
  echo -e "${RED}     🗑️ Delete SSL Certificates${RESET}"
  draw_line "$RED" "=" 40
  echo ""

  echo -e "${CYAN}🔍 Searching for existing SSL certificates...${RESET}"
  # Find directories under /etc/letsencrypt/live/ that are not 'README'
  mapfile -t cert_domains < <(sudo find /etc/letsencrypt/live -maxdepth 1 -mindepth 1 -type d ! -name "README" -exec basename {} \;)

  if [ ${#cert_domains[@]} -eq 0 ]; then
    print_error "No SSL certificates found to delete."
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi

  echo -e "${CYAN}📋 Please select a certificate to delete:${RESET}"
  # Add a "Back to previous menu" option
  cert_domains+=("Back to previous menu")
  select selected_domain in "${cert_domains[@]}"; do
    if [[ "$selected_domain" == "Back to previous menu" ]]; then
      echo -e "${YELLOW}Returning to previous menu...${RESET}"
      echo ""
      return 0
    elif [ -n "$selected_domain" ]; then
      break
    else
      print_error "Invalid selection. Please enter a valid number."
    fi
  done
  echo ""

  if [[ -z "$selected_domain" ]]; then
    print_error "No certificate selected. Aborting deletion."
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi

  echo -e "${RED}⚠️ Are you sure you want to delete the certificate for '$selected_domain'? (y/N): ${RESET}"
  read -p "" confirm_delete
  echo ""

  if [[ "$confirm_delete" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🗑️ Deleting certificate for '$selected_domain' using Certbot...${RESET}"
    if sudo certbot delete --cert-name "$selected_domain"; then
      print_success "Certificate for '$selected_domain' deleted successfully."
    else
      print_error "❌ Failed to delete certificate for '$selected_domain'. Check Certbot logs."
    fi
  else
    echo -e "${YELLOW}Deletion cancelled for '$selected_domain'.${RESET}"
  fi

  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}

# --- New: Certificate Management Menu Function ---
certificate_management_menu() {
  while true; do
    clear
    echo ""
    draw_line "$GREEN" "=" 40
    echo -e "${CYAN}     🔐 Certificate Management${RESET}"
    draw_line "$GREEN" "=" 40
    echo ""
    echo -e "  ${YELLOW}1)${RESET} ${WHITE}Get new certificate${RESET}"
    echo -e "  ${YELLOW}2)${RESET} ${WHITE}Delete certificates${RESET}"
    echo -e "  ${YELLOW}3)${RESET} ${WHITE}Back to main menu${RESET}"
    echo ""
    draw_line "$GREEN" "-" 40
    echo -e "👉 ${CYAN}Your choice:${RESET} "
    read -p "" cert_choice
    echo ""

    case $cert_choice in
      1)
        get_new_certificate_action
        ;;
      2)
        delete_certificates_action
        ;;
      3)
        echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}"
        break # Break out of this while loop to return to main menu
        ;;
      *)
        echo -e "${RED}❌ Invalid option.${RESET}"
        echo ""
        echo -e "${YELLOW}Press Enter to continue...${RESET}"
        read -p ""
        ;;
    esac
  done
}


# --- Main Script Execution ---
set -e # Exit immediately if a command exits with a non-zero status

# Perform initial setup (will run only once)
perform_initial_setup || { echo "Initial setup failed. Exiting."; exit 1; }

# Check Rust readiness after initial setup
if command -v rustc >/dev/null 2>&1; then
  RUST_IS_READY=true
else
  RUST_IS_READY=false
fi

if [ "$RUST_IS_READY" = true ]; then
while true; do
  # Clear terminal and show logo
  clear
  echo -e "${CYAN}"
  figlet -f slant "TrustTunnel"
  echo -e "${CYAN}"
  echo -e "\033[1;33m=========================================================="
  echo -e "Developed by ErfanXRay => https://github.com/Erfan-XRay/TrustTunnel"
  echo -e "Telegram Channel => @Erfan_XRay"
  echo -e "\033[0m${WHITE}Reverse tunnel over QUIC ( Based on rstun project)${WHITE}${RESET}" # Reverse tunnel over QUIC ( Based on rstun project)
  draw_green_line
  echo -e "${GREEN}|${RESET}      ${WHITE}TrustTunnel Main Menu${RESET}      ${GREEN}|${RESET}" # TrustTunnel Main Menu
  # echo -e "${YELLOW}You can also run this script anytime by typing: ${WHITE}trust${RESET}" # Removed as per user request
  draw_green_line
  # Menu
  echo "Select an option:" # Select an option:
  echo -e "${MAGENTA}1) Install Rstun${RESET}" # Install TrustTunnel
  echo -e "${CYAN}2) Rstun reverse tunnel${RESET}" # Rstun reverse tunnel
  echo -e "${CYAN}3) Rstun direct tunnel${RESET}" # Rstun direct tunnel
  echo -e "${YELLOW}4) Certificate management${RESET}" # New: Certificate management
  echo -e "${RED}5) Uninstall TrustTunnel${RESET}" # Shifted from 4
  echo -e "${WHITE}6) Exit${RESET}" # Shifted from 5
  read -p "👉 Your choice: " choice # Your choice:

  case $choice in
    1)
      install_trusttunnel_action
      ;;
    2)
   while true; do 
    clear # Clear screen for a fresh menu display
    echo ""
    draw_line "$GREEN" "=" 40 # Top border
    echo -e "${CYAN}     🌐 Choose Tunnel Mode${RESET}" # Choose Tunnel Mode
    draw_line "$GREEN" "=" 40 # Separator
    echo ""
    echo -e "  ${YELLOW}1)${RESET} ${MAGENTA}Server (Iran)${RESET}" # Server (Iran)
    echo -e "  ${YELLOW}2)${RESET} ${BLUE}Client (Kharej)${RESET}" # Client (Kharej)
    echo -e "  ${YELLOW}3)${RESET} ${WHITE}Return to main menu${RESET}" # Return to main menu
    echo ""
    draw_line "$GREEN" "-" 40 # Bottom border
    echo -e "👉 ${CYAN}Your choice:${RESET} " # Your choice:
    read -p "" tunnel_choice # Removed prompt from read -p
    echo "" # Add a blank line for better spacing after input

      case $tunnel_choice in
        1)
          clear

          # Server Management Sub-menu
          while true; do
            clear # Clear screen for a fresh menu display
            echo ""
            draw_line "$GREEN" "=" 40 # Top border
            echo -e "${CYAN}     🔧 TrustTunnel Server Management${RESET}" # TrustTunnel Server Management
            draw_line "$GREEN" "=" 40 # Separator
            echo ""
            echo -e "  ${YELLOW}1)${RESET} ${WHITE}Add new server${RESET}" # Add new server
            echo -e "  ${YELLOW}2)${RESET} ${WHITE}Show service logs${RESET}" # Show service logs
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Delete service${RESET}" # Delete service
            echo -e "  ${YELLOW}4)${RESET} ${MAGENTA}Schedule server restart${RESET}" # Schedule server restart
            echo -e "  ${YELLOW}5)${RESET} ${RED}Delete scheduled restart${RESET}" # New option: Delete scheduled restart
            echo -e "  ${YELLOW}6)${RESET} ${WHITE}Back to main menu${RESET}" # Back to main menu
            echo ""
            draw_line "$GREEN" "-" 40 # Bottom border
            echo -e "👉 ${CYAN}Your choice:${RESET} " # Your choice:
            read -p "" srv_choice
            echo ""
            case $srv_choice in
              1)
                add_new_server_action
              ;;
              2)
                clear
                service_file="/etc/systemd/system/trusttunnel.service"
                if [ -f "$service_file" ]; then
                  show_service_logs "trusttunnel.service"
                else
                  echo -e "${RED}❌ Service 'trusttunnel.service' not found. Cannot show logs.${RESET}" # Service 'trusttunnel.service' not found. Cannot show logs.
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  read -p ""
                fi
              ;;
              3)
                clear
                service_file="/etc/systemd/system/trusttunnel.service"
                if [ -f "$service_file" ]; then
                  echo -e "${YELLOW}🛑 Stopping and deleting trusttunnel.service...${RESET}" # Stopping and deleting trusttunnel.service...
                  sudo systemctl stop trusttunnel.service > /dev/null 2>&1
                  sudo systemctl disable trusttunnel.service > /dev/null 2>&1
                  sudo rm -f "$service_file" > /dev/null 2>&1
                  sudo systemctl daemon-reload > /dev/null 2>&1
                  print_success "Service deleted." # Service deleted.
                else
                  echo -e "${RED}❌ Service 'trusttunnel.service' not found. Nothing to delete.${RESET}" # Service 'trusttunnel.service' not found. Nothing to delete.
                fi
                echo ""
                echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  read -p ""
              ;;
              4) # Schedule server restart
                reset_timer "trusttunnel" # Pass the server service name directly
              ;;
              5) # New case for deleting cron job
                delete_cron_job_action
              ;;
              6)
                echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
                break 2 # Break out of both inner while and outer case
              ;;
              *)
                echo -e "${RED}❌ Invalid option.${RESET}" # Invalid option.
                echo ""
                echo -e "${YELLOW}Press Enter to continue...${RESET}" # Press Enter to continue...
                read -p ""
              ;;
            esac
          done
          ;;
        2)
          clear

          while true; do
            clear # Clear screen for a fresh menu display
            echo ""
            draw_line "$GREEN" "=" 40 # Top border
            echo -e "${CYAN}     📡 TrustTunnel Client Management${RESET}" # TrustTunnel Client Management
            draw_line "$GREEN" "=" 40 # Separator
            echo ""
            echo -e "  ${YELLOW}1)${RESET} ${WHITE}Add new client${RESET}" # Add new client
            echo -e "  ${YELLOW}2)${RESET} ${WHITE}Show Client Log${RESET}" # Show Client Log
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Delete a client${RESET}" # Delete a client
            echo -e "  ${YELLOW}4)${RESET} ${BLUE}Schedule client restart${RESET}" # Schedule client restart
            echo -e "  ${YELLOW}5)${RESET} ${RED}Delete scheduled restart${RESET}" # New option: Delete scheduled restart
            echo -e "  ${YELLOW}6)${RESET} ${WHITE}Back to main menu${RESET}" # Back to main menu
            echo ""
            draw_line "$GREEN" "-" 40 # Bottom border
            echo -e "👉 ${CYAN}Your choice:${RESET} " # Your choice:
            read -p "" client_choice
            echo ""

            case $client_choice in
              1)
                add_new_client_action
              ;;
              2)
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}     📊 TrustTunnel Client Logs${RESET}" # TrustTunnel Client Logs
                draw_line "$CYAN" "=" 40
                echo ""

                echo -e "${CYAN}🔍 Searching for clients ...${RESET}" # Searching for clients ...

                # List all systemd services that start with trusttunnel-
                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-' | awk '{print $1}' | sed 's/.service$//')

                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No clients found.${RESET}" # No clients found.
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  # No return here, let the loop continue to show client management menu
                else
                  echo -e "${CYAN}📋 Please select a service to see log:${RESET}" # Please select a service to see log:
                  # Add "Back to previous menu" option
                  services+=("Back to previous menu")
                  select selected_service in "${services[@]}"; do
                    if [[ "$selected_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}" # Returning to previous menu...
                      echo ""
                      break 2 # Exit both the select and the outer while loop
                    elif [ -n "$selected_service" ]; then
                      show_service_logs "$selected_service"
                      break # Exit the select loop
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}" # Invalid selection. Please enter a valid number.
                    fi
                  done
                  echo "" # Add a blank line after selection
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  read -p ""
                fi
              ;;
              3)
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}     🗑️ Delete TrustTunnel Client${RESET}" # Delete TrustTunnel Client
                draw_line "$CYAN" "=" 40
                echo ""

                echo -e "${CYAN}🔍 Searching for clients ...${RESET}" # Searching for clients ...

                # List all systemd services that start with trusttunnel-
                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-' | awk '{print $1}' | sed 's/.service$//')

                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No clients found.${RESET}" # No clients found.
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  # No return here, let the loop continue to show client management menu
                else
                  echo -e "${CYAN}📋 Please select a service to delete:${RESET}" # Please select a service to delete:
                  # Add "Back to previous menu" option
                  services+=("Back to previous menu")
                  select selected_service in "${services[@]}"; do
                    if [[ "$selected_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}" # Returning to previous menu...
                      echo ""
                      break 2 # Exit both the select and the outer while loop
                    elif [ -n "$selected_service" ]; then
                      service_file="/etc/systemd/system/${selected_service}.service"
                      echo -e "${YELLOW}🛑 Stopping $selected_service...${RESET}" # Stopping selected_service...
                      sudo systemctl stop "$selected_service" > /dev/null 2>&1
                      sudo systemctl disable "$selected_service" > /dev/null 2>&1
                      sudo rm -f "$service_file" > /dev/null 2>&1
                      sudo systemctl daemon-reload > /dev/null 2>&1
                      print_success "Client '$selected_service' deleted." # Client 'selected_service' deleted.
                      # Also remove any associated cron jobs for this specific client
                      echo -e "${CYAN}🧹 Removing cron jobs for '$selected_service'...${RESET}" # Removing cron jobs for 'selected_service'...
                      (sudo crontab -l 2>/dev/null | grep -v "# TrustTunnel automated restart for $selected_service$") | sudo crontab -
                      print_success "Cron jobs for '$selected_service' removed." # Cron jobs for '$selected_service' removed.
                      break # Exit the select loop
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}" # Invalid selection. Please enter a valid number.
                    fi
                  done
                  echo "" # Add a blank line after selection
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  read -p ""
                fi
              ;;
              4) # Schedule client restart
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}     ⏰ Schedule Client Restart${RESET}" # Schedule Client Restart
                draw_line "$CYAN" "=" 40
                echo ""

                echo -e "${CYAN}🔍 Searching for clients ...${RESET}" # Searching for clients ...

                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-' | awk '{print $1}' | sed 's/.service$//')

                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No clients found to schedule. Please add a client first.${RESET}" # No clients found to schedule. Please add a client first.
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}" # Press Enter to return to previous menu...
                  read -p ""
                else
                  echo -e "${CYAN}📋 Please select which client service to schedule for restart:${RESET}" # Please select which client service to schedule for restart:
                  # Add "Back to previous menu" option
                  services+=("Back to previous menu")
                  select selected_client_service in "${services[@]}"; do
                    if [[ "$selected_client_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}" # Returning to previous menu...
                      echo ""
                      break 2 # Exit both the select and the outer while loop
                    elif [ -n "$selected_client_service" ]; then
                      reset_timer "$selected_client_service" # Pass the selected client service name
                      break # Exit the select loop
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}" # Invalid selection. Please enter a valid number.
                    fi
                  done
                fi
                ;;
              5) # New case for deleting cron job in client menu
                delete_cron_job_action
              ;;
              6)
                echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
                break 2 # Break out of both inner while and outer case
              ;;
              *)
                echo -e "${RED}❌ Invalid option.${RESET}" # Invalid option.
                echo ""
                echo -e "${YELLOW}Press Enter to continue...${RESET}" # Press Enter to continue...
                read -p ""
              ;;
            esac
          done
          ;;
        3)
          echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
          break # Changed from 'return' to 'break'
          ;;
        *)
          echo -e "${RED}❌ Invalid option.${RESET}" # Invalid option.
          echo ""
          echo -e "${YELLOW}Press Enter to continue...${RESET}" # Press Enable to continue...
          read -p ""
          ;;
      esac
      done
      ;;
      
    3)
    while true; do 
      # Direct tunnel menu (copy of reverse tunnel with modified names)
      clear
      echo ""
      draw_line "$GREEN" "=" 40
      echo -e "${CYAN}        🌐 Choose Direct Tunnel Mode${RESET}"
      draw_line "$GREEN" "=" 40
      echo ""
      echo -e "  ${YELLOW}1)${RESET} ${MAGENTA}Direct Server(Kharej)${RESET}"
      echo -e "  ${YELLOW}2)${RESET} ${BLUE}Direct Client(Iran)${RESET}"
      echo -e "  ${YELLOW}3)${RESET} ${WHITE}Return to main menu${RESET}"
      echo ""
      draw_line "$GREEN" "-" 40
      echo -e "👉 ${CYAN}Your choice:${RESET} "
      read -p "" direct_tunnel_choice
      echo ""

      case $direct_tunnel_choice in
        1)
          clear
          # Direct Server Management Sub-menu (copy of reverse server menu)
          while true; do
            clear
            echo ""
            draw_line "$GREEN" "=" 40
            echo -e "${CYAN}        🔧 Direct Server Management${RESET}"
            draw_line "$GREEN" "=" 40
            echo ""
            echo -e "  ${YELLOW}1)${RESET} ${WHITE}Add new direct server${RESET}"
            echo -e "  ${YELLOW}2)${RESET} ${WHITE}Show direct service logs${RESET}"
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Delete direct service${RESET}"
            echo -e "  ${YELLOW}4)${RESET} ${MAGENTA}Schedule direct server restart${RESET}"
            echo -e "  ${YELLOW}5)${RESET} ${RED}Delete scheduled restart${RESET}"
            echo -e "  ${YELLOW}6)${RESET} ${WHITE}Back to main menu${RESET}"
            echo ""
            draw_line "$GREEN" "-" 40
            echo -e "👉 ${CYAN}Your choice:${RESET} "
            read -p "" direct_srv_choice
            echo ""
            case $direct_srv_choice in
              1)
                add_new_direct_server_action
                ;;
              2)
                clear
                service_file="/etc/systemd/system/trusttunnel-direct.service"
                if [ -f "$service_file" ]; then
                  show_service_logs "trusttunnel-direct.service"
                else
                  echo -e "${RED}❌ Service 'trusttunnel-direct.service' not found. Cannot show logs.${RESET}"
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                fi
                ;;
              3)
                clear
                service_file="/etc/systemd/system/trusttunnel-direct.service"
                if [ -f "$service_file" ]; then
                  echo -e "${YELLOW}🛑 Stopping and deleting trusttunnel-direct.service...${RESET}"
                  sudo systemctl stop trusttunnel-direct.service > /dev/null 2>&1
                  sudo systemctl disable trusttunnel-direct.service > /dev/null 2>&1
                  sudo rm -f /etc/systemd/system/trusttunnel-direct.service > /dev/null 2>&1
                  sudo systemctl daemon-reload > /dev/null 2>&1
                  print_success "Direct service deleted."
                else
                  echo -e "${RED}❌ Service 'trusttunnel-direct.service' not found. Nothing to delete.${RESET}"
                fi
                echo ""
                echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                read -p ""
                ;;
              4)
                reset_timer "trusttunnel-direct"
                ;;
              5)
                delete_cron_job_action
                ;;
              6)
                echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
                break 2
                ;;
              *)
                echo -e "${RED}❌ Invalid option.${RESET}"
                echo ""
                echo -e "${YELLOW}Press Enter to continue...${RESET}"
                read -p ""
                ;;
            esac
          done
          ;;
        2)
          clear
          while true; do
            clear
            echo ""
            draw_line "$GREEN" "=" 40
            echo -e "${CYAN}        📡 Direct Client Management${RESET}"
            draw_line "$GREEN" "=" 40
            echo ""
            echo -e "  ${YELLOW}1)${RESET} ${WHITE}Add new direct client${RESET}"
            echo -e "  ${YELLOW}2)${RESET} ${WHITE}Show Direct Client Log${RESET}"
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Delete a direct client${RESET}"
            echo -e "  ${YELLOW}4)${RESET} ${BLUE}Schedule direct client restart${RESET}"
            echo -e "  ${YELLOW}5)${RESET} ${RED}Delete scheduled restart${RESET}"
            echo -e "  ${YELLOW}6)${RESET} ${WHITE}Back to main menu${RESET}"
            echo ""
            draw_line "$GREEN" "-" 40
            echo -e "👉 ${CYAN}Your choice:${RESET} "
            read -p "" direct_client_choice
            echo ""

            case $direct_client_choice in
              1)
                add_new_direct_client_action
                ;;
              2)
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}        📊 Direct Client Logs${RESET}"
                draw_line "$CYAN" "=" 40
                echo ""
                echo -e "${CYAN}🔍 Searching for direct clients ...${RESET}"
                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-direct-client-' | awk '{print $1}' | sed 's/.service$//')
                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No direct clients found.${RESET}"
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                else
                  echo -e "${CYAN}📋 Please select a service to see log:${RESET}"
                  services+=("Back to previous menu")
                  select selected_service in "${services[@]}"; do
                    if [[ "$selected_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}"
                      echo ""
                      break 2
                    elif [ -n "$selected_service" ]; then
                      show_service_logs "$selected_service"
                      break
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}"
                    fi
                  done
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                fi
                ;;
              3)
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}        🗑️ Delete Direct Client${RESET}"
                draw_line "$CYAN" "=" 40
                echo ""
                echo -e "${CYAN}🔍 Searching for direct clients ...${RESET}"
                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-direct-client-' | awk '{print $1}' | sed 's/.service$//')
                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No direct clients found.${RESET}"
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                else
                  echo -e "${CYAN}📋 Please select a service to delete:${RESET}"
                  services+=("Back to previous menu")
                  select selected_service in "${services[@]}"; do
                    if [[ "$selected_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}"
                      echo ""
                      break 2
                    elif [ -n "$selected_service" ]; then
                      service_file="/etc/systemd/system/${selected_service}.service"
                      echo -e "${YELLOW}🛑 Stopping $selected_service...${RESET}"
                      sudo systemctl stop "$selected_service" > /dev/null 2>&1
                      sudo systemctl disable "$selected_service" > /dev/null 2>&1
                      sudo rm -f "$service_file" > /dev/null 2>&1
                      sudo systemctl daemon-reload > /dev/null 2>&1
                      print_success "Direct client '$selected_service' deleted."
                      echo -e "${CYAN}🧹 Removing cron jobs for '$selected_service'...${RESET}"
                      (sudo crontab -l 2>/dev/null | grep -v "# TrustTunnel automated restart for $selected_service$") | sudo crontab -
                      print_success "Cron jobs for '$selected_service' removed."
                      break
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}"
                    fi
                  done
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                fi
                ;;
              4)
                clear
                echo ""
                draw_line "$CYAN" "=" 40
                echo -e "${CYAN}        ⏰ Schedule Direct Client Restart${RESET}"
                draw_line "$CYAN" "=" 40
                echo ""
                echo -e "${CYAN}🔍 Searching for direct clients ...${RESET}"
                mapfile -t services < <(systemctl list-units --type=service --all | grep 'trusttunnel-direct-client-' | awk '{print $1}' | sed 's/.service$//')
                if [ ${#services[@]} -eq 0 ]; then
                  echo -e "${RED}❌ No direct clients found to schedule. Please add a client first.${RESET}"
                  echo ""
                  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
                  read -p ""
                else
                  echo -e "${CYAN}📋 Please select which direct client service to schedule for restart:${RESET}"
                  services+=("Back to previous menu")
                  select selected_client_service in "${services[@]}"; do
                    if [[ "$selected_client_service" == "Back to previous menu" ]]; then
                      echo -e "${YELLOW}Returning to previous menu...${RESET}"
                      echo ""
                      break 2
                    elif [ -n "$selected_client_service" ]; then
                      reset_timer "$selected_client_service"
                      break
                    else
                      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}"
                    fi
                  done
                fi
                ;;
              5)
                delete_cron_job_action
                ;;
              6)
                echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
                break 2
                ;;
              *)
                echo -e "${RED}❌ Invalid option.${RESET}"
                echo ""
                echo -e "${YELLOW}Press Enter to continue...${RESET}"
                read -p ""
                ;;
            esac
          done
          ;;
        3)
          echo -e "${YELLOW}بازگشت به منوی اصلی...${RESET}" # Returning to main menu...
          break # Changed from 'return' to 'break'
          ;;
        *)
          echo -e "${RED}❌ Invalid option.${RESET}"
          echo ""
          echo -e "${YELLOW}Press Enter to continue...${RESET}"
          read -p ""
          ;;
      esac
      done
      ;;
    4) # New Certificate Management option
      certificate_management_menu
      ;;
    5) # Shifted from 4
      uninstall_trusttunnel_action
    ;;
    6) # Shifted from 5
      exit 0
    ;;
    *)
      echo -e "${RED}❌ Invalid choice. Exiting.${RESET}" # Invalid choice. Exiting.
      echo ""
      echo -e "${YELLOW}Press Enter to continue...${RESET}" # Press Enter to continue...
      read -p ""
    ;;
  esac
  echo ""
done
else
echo ""
  echo "🛑 Rust is not ready. Skipping the main menu." # Rust is not ready. Skipping the main menu.
fi
