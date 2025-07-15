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
edit_server_ports_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ✏️ Edit TrustTunnel Server Ports${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""

  local service_file="/etc/systemd/system/trusttunnel.service"
  if [ ! -f "$service_file" ]; then
    echo -e "${RED}❌ trusttunnel.service not found. Please add server first.${RESET}"
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return
  fi

  local current_listen_port=$(grep -oP '--addr 0\.0\.0\.0:\K[0-9]+' "$service_file")
  local current_tcp_port=$(grep -oP '--tcp-upstream \K[0-9]+' "$service_file")
  local current_udp_port=$(grep -oP '--udp-upstream \K[0-9]+' "$service_file")

  echo -e "Current tunneling port: ${WHITE}$current_listen_port${RESET}"
  echo -e "Current TCP upstream port: ${WHITE}$current_tcp_port${RESET}"
  echo -e "Current UDP upstream port: ${WHITE}$current_udp_port${RESET}"
  echo ""

  local listen_port
  while true; do
    echo -e "👉 ${WHITE}New tunneling address port (1-65535, default $current_listen_port):${RESET} "
    read -p "" input
    listen_port=${input:-$current_listen_port}
    if validate_port "$listen_port"; then
      break
    else
      print_error "Invalid port number."
    fi
  done

  local tcp_upstream_port
  while true; do
    echo -e "👉 ${WHITE}New TCP upstream port (1-65535, default $current_tcp_port):${RESET} "
    read -p "" input
    tcp_upstream_port=${input:-$current_tcp_port}
    if validate_port "$tcp_upstream_port"; then
      break
    else
      print_error "Invalid port number."
    fi
  done

  local udp_upstream_port
  while true; do
    echo -e "👉 ${WHITE}New UDP upstream port (1-65535, default $current_udp_port):${RESET} "
    read -p "" input
    udp_upstream_port=${input:-$current_udp_port}
    if validate_port "$udp_upstream_port"; then
      break
    else
      print_error "Invalid port number."
    fi
  done

  sudo sed -i "s/--addr 0\.0\.0\.0:$current_listen_port/--addr 0.0.0.0:$listen_port/" "$service_file"
  sudo sed -i "s/--tcp-upstream $current_tcp_port/--tcp-upstream $tcp_upstream_port/" "$service_file"
  sudo sed -i "s/--udp-upstream $current_udp_port/--udp-upstream $udp_upstream_port/" "$service_file"

  sudo systemctl daemon-reload
  sudo systemctl restart trusttunnel.service
  print_success "Server ports updated."
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}

edit_client_ports_action() {
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ✏️ Edit TrustTunnel Client Ports${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""

  mapfile -t services < <(systemctl list-unit-files --full --no-pager | grep '^trusttunnel-' | awk '{print $1}' | sed 's/.service$//')

  if [ ${#services[@]} -eq 0 ]; then
    echo -e "${RED}❌ No clients found.${RESET}"
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return
  fi

  services+=("Back to previous menu")
  echo -e "${CYAN}📋 Please select a client:${RESET}"
  select selected_service in "${services[@]}"; do
    if [[ "$selected_service" == "Back to previous menu" ]]; then
      return
    elif [ -n "$selected_service" ]; then
      service_file="/etc/systemd/system/${selected_service}.service"
      break
    else
      echo -e "${RED}⚠️ Invalid selection. Please enter a valid number.${RESET}"
    fi
  done

  local exec_line=$(grep ExecStart "$service_file")
  local bin_path=$(echo "$exec_line" | cut -d' ' -f1 | cut -d'=' -f2)
  local server_addr=$(echo "$exec_line" | grep -oP '--server-addr "\K[^\"]+')
  local password=$(echo "$exec_line" | grep -oP '--password "\K[^\"]+')

  echo ""
  echo -e "${CYAN}📡 Tunnel Mode:${RESET}"
  echo -e "  (tcp/udp/both)"
  echo -e "👉 ${WHITE}Tunnel mode ? (tcp/udp/both):${RESET} "
  read -p "" tunnel_mode
  echo ""

  local port_count
  while true; do
    echo -e "👉 ${WHITE}How many ports to tunnel?${RESET} "
    read -p "" port_count_input
    if [[ "$port_count_input" =~ ^[0-9]+$ ]] && (( port_count_input >= 0 )); then
      port_count=$port_count_input
      break
    else
      print_error "Invalid input. Please enter a non-negative number for port count."
    fi
  done
  echo ""

  mappings=""
  for ((i=1; i<=port_count; i++)); do
    local port
    while true; do
      echo -e "👉 ${WHITE}Enter Port #$i (1-65535):${RESET} "
      read -p "" port_input
      if validate_port "$port_input"; then
        port="$port_input"
        break
      else
        print_error "Invalid port number. Please enter a number between 1 and 65535."
      fi
    done
    mapping="IN^0.0.0.0:$port^0.0.0.0:$port"
    [ -z "$mappings" ] && mappings="$mapping" || mappings="$mappings,$mapping"
    echo ""
  done

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
      echo -e "${YELLOW}⚠️ Invalid tunnel mode specified. Using 'both' as default.${RESET}"
      mapping_args="--tcp-mappings \"$mappings\" --udp-mappings \"$mappings\""
      ;;
  esac

  local new_exec="${bin_path} --server-addr \"$server_addr\" --password \"$password\" ${mapping_args} --quic-timeout-ms 1000 --tcp-timeout-ms 1000 --udp-timeout-ms 1000 --wait-before-retry-ms 3000"
  sudo sed -i "s|^ExecStart=.*|ExecStart=${new_exec}|" "$service_file"

  sudo systemctl daemon-reload
  sudo systemctl restart "${selected_service}.service"
  print_success "Client ports updated for '$selected_service'"
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}
