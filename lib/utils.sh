# shellcheck disable=SC2154

draw_line() {
  local color="$1"
  local char="$2"
  local length=${3:-40}
  printf "%s" "${color}"
  for ((i=0; i<length; i++)); do
    printf "%s" "$char"
  done
  printf "%s\n" "$RESET"
}

print_success() {
  local message="$1"
  echo -e "${GREEN}✅ $message${RESET}"
}

print_error() {
  local message="$1"
  echo -e "${RED}❌ $message${RESET}"
}

draw_green_line() {
  echo -e "${GREEN}+--------------------------------------------------------+${RESET}"
}
