#!/bin/bash

# ========================================
# Source this file only if wasn't sourced already
# ========================================
CURRENT_FILE_HASH="$(realpath "${BASH_SOURCE[0]}" | sha256sum | cut -d ' ' -f 1)" || exit "$?"
if [ -n "${SOURCED_FILES["hash_${CURRENT_FILE_HASH}"]}" ]; then
  return
fi
SOURCED_FILES["hash_${CURRENT_FILE_HASH}"]=1
# ========================================

# ========================================
# Colors for messages
# ========================================
# Color for message
export C_INFO='\e[0;36m'
# Color for successful execution
export C_SUCCESS='\e[0;32m'
# Color for highlighted text
export C_HIGHLIGHT='\e[1;95m'
# Color for error
export C_WARNING='\e[0;33m'
# Color for error
export C_ERROR='\e[0;31m'

# Reset color
export C_RESET='\e[0m'

# Special text that will be replaced with the previous one
export C_RETURN='COLOR_RETURN'
# ========================================

# Prints a message with the specified prefix and text
function print_color_message() {
  # ========================================
  # 1. Imports
  # ========================================

  # None

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

# Prints highlighted message
function print_highlight() {
  local text="${1}" && shift
  print_color_message "${C_HIGHLIGHT}" "${text}" >&2 || return "$?"
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

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  print_color_message "$@" || exit "$?"
fi
# ========================================
