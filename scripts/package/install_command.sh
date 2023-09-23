#!/bin/bash

# Install command with specified name
function install_command() {
  # ========================================
  # 1. Working directory
  # ========================================

  # We will work in this script's directory
  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"

  # ========================================
  # 2. Imports
  # ========================================

  source "./is_command_installed.sh" || return "$?"

  # ========================================
  # 3. Arguments
  # ========================================

  local commandName="$1"
  if [ -z "${commandName}" ]; then
    echo "You need to enter command name!" >&2
    return 1
  fi

  local packageName="$2"

  # ========================================
  # 4. Main code
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
