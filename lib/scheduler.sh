reset_timer() {
  local service_to_restart="$1"
  clear
  echo ""
  draw_line "$CYAN" "=" 40
  echo -e "${CYAN}     ⏰ Schedule Service Restart${RESET}"
  draw_line "$CYAN" "=" 40
  echo ""
  if [[ -z "$service_to_restart" ]]; then
    echo -e "👉 ${WHITE}Which service do you want to restart (e.g., 'nginx', 'apache2', 'trusttunnel')? ${RESET}"
    read -p "" service_to_restart
    echo ""
  fi
  if [[ -z "$service_to_restart" ]]; then
    print_error "Service name cannot be empty. Aborting scheduling."
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi
  if [ ! -f "/etc/systemd/system/${service_to_restart}.service" ]; then
    print_error "Service '$service_to_restart' does not exist on this system. Cannot schedule restart."
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi
  echo -e "${CYAN}Scheduling restart for service: ${WHITE}$service_to_restart${RESET}"
  echo ""
  echo "Please select a time interval for the service to restart RECURRINGLY:"
  echo -e "  ${YELLOW}1)${RESET} ${WHITE}Every 30 minutes${RESET}"
  echo -e "  ${YELLOW}2)${RESET} ${WHITE}Every 1 hour${RESET}"
  echo -e "  ${YELLOW}3)${RESET} ${WHITE}Every 2 hours${RESET}"
  echo -e "  ${YELLOW}4)${RESET} ${WHITE}Every 4 hours${RESET}"
  echo -e "  ${YELLOW}5)${RESET} ${WHITE}Every 6 hours${RESET}"
  echo -e "  ${YELLOW}6)${RESET} ${WHITE}Every 12 hours${RESET}"
  echo -e "  ${YELLOW}7)${RESET} ${WHITE}Every 24 hours${RESET}"
  echo ""
  read -p "👉 Enter your choice (1-7): " choice
  echo ""
  local cron_minute=""
  local cron_hour=""
  local cron_day_of_month="*"
  local cron_month="*"
  local cron_day_of_week="*"
  local description=""
  case "$choice" in
    1)
      cron_minute="*/30"
      cron_hour="*"
      description="every 30 minutes"
      ;;
    2)
      cron_minute="0"
      cron_hour="*/1"
      description="every 1 hour"
      ;;
    3)
      cron_minute="0"
      cron_hour="*/2"
      description="every 2 hours"
      ;;
    4)
      cron_minute="0"
      cron_hour="*/4"
      description="every 4 hours"
      ;;
    5)
      cron_minute="0"
      cron_hour="*/6"
      description="every 6 hours"
      ;;
    6)
      cron_minute="0"
      cron_hour="*/12"
      description="every 12 hours"
      ;;
    7)
      cron_minute="0"
      cron_hour="0"
      description="every 24 hours (daily at midnight)"
      ;;
    *)
      echo -e "${RED}❌ Invalid choice. No cron job will be scheduled.${RESET}"
      echo ""
      echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
      read -p ""
      return 1
      ;;
  esac
  echo -e "${CYAN}Scheduling '$service_to_restart' to restart $description...${RESET}"
  echo ""
  local cron_command="/usr/bin/systemctl restart $service_to_restart >> /var/log/trusttunnel_cron.log 2>&1"
  local cron_job_entry="$cron_minute $cron_hour $cron_day_of_month $cron_month $cron_day_of_week $cron_command # TrustTunnel automated restart for $service_to_restart"
  local temp_cron_file=$(mktemp)
  if ! sudo crontab -l &> /dev/null; then
    echo "" | sudo crontab -
  fi
  sudo crontab -l > "$temp_cron_file"
  sed -i "/# TrustTunnel automated restart for $service_to_restart$/d" "$temp_cron_file"
  echo "$cron_job_entry" >> "$temp_cron_file"
  if sudo crontab "$temp_cron_file"; then
    print_success "Successfully scheduled a restart for '$service_to_restart' $description."
    echo -e "${CYAN}   The cron job entry looks like this:${RESET}"
    echo -e "${WHITE}   $cron_job_entry${RESET}"
    echo -e "${CYAN}   You can check scheduled cron jobs with: ${WHITE}sudo crontab -l${RESET}"
    echo -e "${CYAN}   Logs will be written to: ${WHITE}/var/log/trusttunnel_cron.log${RESET}"
  else
    print_error "Failed to schedule the cron job. Check permissions or cron service status."
  fi
  rm -f "$temp_cron_file"
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}

delete_cron_job_action() {
  clear
  echo ""
  draw_line "$RED" "=" 40
  echo -e "${RED}     🗑️ Delete Scheduled Restart (Cron)${RESET}"
  draw_line "$RED" "=" 40
  echo ""
  echo -e "${CYAN}🔍 Searching for TrustTunnel related services with scheduled restarts...${RESET}"
  mapfile -t services_with_cron < <(sudo crontab -l 2>/dev/null | grep "# TrustTunnel automated restart for" | awk '{print $NF}' | sort -u)
  local service_names=()
  for service_comment in "${services_with_cron[@]}"; do
    local extracted_name=$(echo "$service_comment" | sed 's/# TrustTunnel automated restart for //')
    service_names+=("$extracted_name")
  done
  if [ ${#service_names[@]} -eq 0 ]; then
    print_error "No TrustTunnel services with scheduled cron jobs found."
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi
  echo -e "${CYAN}📋 Please select a service to delete its scheduled restart:${RESET}"
  service_names+=("Back to previous menu")
  select selected_service_name in "${service_names[@]}"; do
    if [[ "$selected_service_name" == "Back to previous menu" ]]; then
      echo -e "${YELLOW}Returning to previous menu...${RESET}"
      echo ""
      return 0
    elif [ -n "$selected_service_name" ]; then
      break
    else
      print_error "Invalid selection. Please enter a valid number."
    fi
  done
  echo ""
  if [[ -z "$selected_service_name" ]]; then
    print_error "No service selected. Aborting."
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi
  echo -e "${CYAN}Attempting to delete cron job for '$selected_service_name'...${RESET}"
  local temp_cron_file=$(mktemp)
  if ! sudo crontab -l &> /dev/null; then
    print_error "Crontab is empty or not accessible. Nothing to delete."
    rm -f "$temp_cron_file"
    echo ""
    echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
    read -p ""
    return 1
  fi
  sudo crontab -l > "$temp_cron_file"
  sed -i "/# TrustTunnel automated restart for $selected_service_name$/d" "$temp_cron_file"
  if sudo crontab "$temp_cron_file"; then
    print_success "Successfully removed scheduled restart for '$selected_service_name'."
    echo -e "${WHITE}You can verify with: ${YELLOW}sudo crontab -l${RESET}"
  else
    print_error "Failed to delete cron job. It might not exist or there's a permission issue."
  fi
  rm -f "$temp_cron_file"
  echo ""
  echo -e "${YELLOW}Press Enter to return to previous menu...${RESET}"
  read -p ""
}
