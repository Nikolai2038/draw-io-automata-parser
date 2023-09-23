#!/bin/bash

if [ -n "${IS_FILE_SOURCED_MESSAGES}" ]; then
  return
fi

# Prints a message with the specified prefix and text
function print_color_message() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../1_external_constants/colors.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local main_color="${1}" && shift
  local text="${1}" && shift

  # ========================================
  # 3. Main code
  # ========================================

  # Replaces the special string with the text color
  # (don't forget to escape the first color character with an additional backslash)
  if [ -n "${main_color}" ]; then
    text=$(echo -e "${text}" | sed -E "s/${C_RETURN}/\\${main_color}/g") || return "$?"
  else
    text=$(echo -e "${text}" | sed -E "s/${C_RETURN}//g") || return "$?"
  fi

  # shellcheck disable=SC2320
  echo -e "${main_color}${text}${C_RESET}" || return "$?"

  return 0
}

# Prints a message with information
function print_info() {
  local text="${1}" && shift
  print_color_message "${C_INFO}" "${text}" >&2 || return "$?"
  return 0
}

# Prints a message about success
function print_success() {
  local text="${1}" && shift
  print_color_message "${C_SUCCESS}" "${text}" >&2 || return "$?"
  return 0
}

# Prints a warning message
function print_warning() {
  local text="${1}" && shift
  print_color_message "${C_WARNING}" "${text}" >&2 || return "$?"
  return 0
}

# Prints an error message
function print_error() {
  local text="${1}" && shift
  print_color_message "${C_ERROR}" "${text}" >&2 || return "$?"
  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  print_color_message "$@" || exit "$?"
fi

export IS_FILE_SOURCED_MESSAGES=1
