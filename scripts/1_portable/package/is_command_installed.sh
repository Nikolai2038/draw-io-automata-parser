#!/bin/bash

if [ -n "${IS_FILE_SOURCED_IS_COMMAND_INSTALLED}" ]; then
  return
fi

# Echo 1 if passed command name is installed, and 0 - if not installed.
function is_command_installed() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../messages.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local command_name="${1}" && shift
  if [ -z "${command_name}" ]; then
    print_error "You need to specify command name!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  which "${command_name}" &>/dev/null && echo "1" || echo "0"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  is_command_installed "$@" || exit "$?"
fi

export IS_FILE_SOURCED_IS_COMMAND_INSTALLED=1
