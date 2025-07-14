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
