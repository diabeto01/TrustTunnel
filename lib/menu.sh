main_menu() {
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
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Edit ports${RESET}" # Edit ports
            echo -e "  ${YELLOW}4)${RESET} ${WHITE}Delete service${RESET}" # Delete service
            echo -e "  ${YELLOW}5)${RESET} ${MAGENTA}Schedule server restart${RESET}" # Schedule server restart
            echo -e "  ${YELLOW}6)${RESET} ${RED}Delete scheduled restart${RESET}" # New option: Delete scheduled restart
            echo -e "  ${YELLOW}7)${RESET} ${WHITE}Back to main menu${RESET}" # Back to main menu
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
                edit_server_ports_action
              ;;
              4)
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
              5) # Schedule server restart
                reset_timer "trusttunnel" # Pass the server service name directly
              ;;
              6) # New case for deleting cron job
                delete_cron_job_action
              ;;
              7)
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
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Edit ports${RESET}" # Edit ports
            echo -e "  ${YELLOW}4)${RESET} ${WHITE}Delete a client${RESET}" # Delete a client
            echo -e "  ${YELLOW}5)${RESET} ${BLUE}Schedule client restart${RESET}" # Schedule client restart
            echo -e "  ${YELLOW}6)${RESET} ${RED}Delete scheduled restart${RESET}" # New option: Delete scheduled restart
            echo -e "  ${YELLOW}7)${RESET} ${WHITE}Back to main menu${RESET}" # Back to main menu
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
                edit_client_ports_action
              ;;
              4)
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
              5) # Schedule client restart
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
              6) # New case for deleting cron job in client menu
                delete_cron_job_action
              ;;
              7)
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
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Edit ports${RESET}"
            echo -e "  ${YELLOW}4)${RESET} ${WHITE}Delete direct service${RESET}"
            echo -e "  ${YELLOW}5)${RESET} ${MAGENTA}Schedule direct server restart${RESET}"
            echo -e "  ${YELLOW}6)${RESET} ${RED}Delete scheduled restart${RESET}"
            echo -e "  ${YELLOW}7)${RESET} ${WHITE}Back to main menu${RESET}"
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
                edit_direct_server_ports_action
              ;;
              4)
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
              5)
                reset_timer "trusttunnel-direct"
                ;;
              6)
                delete_cron_job_action
                ;;
              7)
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
            echo -e "  ${YELLOW}3)${RESET} ${WHITE}Edit ports${RESET}"
            echo -e "  ${YELLOW}4)${RESET} ${WHITE}Delete a direct client${RESET}"
            echo -e "  ${YELLOW}5)${RESET} ${BLUE}Schedule direct client restart${RESET}"
            echo -e "  ${YELLOW}6)${RESET} ${RED}Delete scheduled restart${RESET}"
            echo -e "  ${YELLOW}7)${RESET} ${WHITE}Back to main menu${RESET}"
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
                edit_direct_client_ports_action
              ;;
              4)
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
              5)
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
              6)
                delete_cron_job_action
                ;;
              7)
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
}
