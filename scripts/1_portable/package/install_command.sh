#!/bin/bash

if [ -n "${IS_FILE_SOURCED_INSTALL_COMMAND}" ]; then
  return
fi

# Install command with specified name
function install_command() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "./is_command_installed.sh" || return "$?"
  source "./../messages.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local command_name="${1}"
  if [ -z "${command_name}" ]; then
    print_error "You need to specify command name!"
    return 1
  fi

  local package_name="${2}"

  # ========================================
  # 3. Main code
  # ========================================

  local is_command_installed
  is_command_installed="$(is_command_installed "${command_name}")" || return "$?"

  if ((is_command_installed)); then
    return 0
  fi

  if [ -n "${package_name}" ]; then
    print_info "Installing command ${C_HIGHLIGHT}${command_name}${C_RETURN} from package ${C_HIGHLIGHT}${package_name}${C_RETURN}..."
  else
    print_info "Installing command ${C_HIGHLIGHT}${command_name}${C_RETURN}..."
  fi

  sudo apt update || return "$?"

  if [ -n "${package_name}" ]; then
    sudo apt install -y "${package_name}" || return "$?"
    print_success "Command ${C_HIGHLIGHT}${command_name}${C_RETURN} from package ${C_HIGHLIGHT}${package_name}${C_RETURN} successfully installed!"
  else
    sudo apt install -y "${command_name}" || return "$?"
    print_success "Command ${C_HIGHLIGHT}${command_name}${C_RETURN} successfully installed!"
  fi

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  install_command "$@" || exit "$?"
fi

export IS_FILE_SOURCED_INSTALL_COMMAND=1
