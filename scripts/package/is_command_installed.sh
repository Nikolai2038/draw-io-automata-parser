#!/bin/bash

# Echo 1 if passed command name is installed, and 0 - if not installed.
function is_command_installed() {
  # ========================================
  # 1. Imports
  # ========================================

  # None

  # ========================================
  # 2. Arguments
  # ========================================

  local commandName="${1}" && shift
  if [ -z "${commandName}" ]; then
    echo "You need to specify command name!" >&2
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  which "${commandName}" &> /dev/null && echo "1" || echo "0"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  is_command_installed "$@" || exit "$?"
fi
