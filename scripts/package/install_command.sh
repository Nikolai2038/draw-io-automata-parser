#!/bin/bash

# Install command with specified name
function install_command() {
  # ========================================
  # 1. Imports
  # ========================================

  local directory_with_script
  directory_with_script="$(dirname "${BASH_SOURCE[0]}")" || return "$?"

  # shellcheck source=./is_command_installed.sh
  source "${directory_with_script}/is_command_installed.sh" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local commandName="${1}"
  if [ -z "${commandName}" ]; then
    echo "You need to specify command name!" >&2
    return 1
  fi

  local packageName="${2}"

  # ========================================
  # 3. Main code
  # ========================================

  local isCommandInstalled
  isCommandInstalled="$(is_command_installed "${commandName}")" || return "$?"

  if ((isCommandInstalled)); then
    return 0
  fi

  sudo apt update || return "$?"

  if [ -n "${packageName}" ]; then
    sudo apt install -y "${packageName}" || return "$?"
  else
    sudo apt install -y "${commandName}" || return "$?"
  fi

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  install_command "$@" || exit "$?"
fi
