show_service_logs() {
  local service_name="$1"
  clear
  echo -e "${BLUE}--- Displaying logs for $service_name ---${RESET}"
  sudo journalctl -u "$service_name" -n 50 --no-pager
  echo ""
  echo -e "${YELLOW}Press any key to return to the previous menu...${RESET}"
  read -n 1 -s -r
  clear
}
