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

# Install command with specified name
function install_command() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "./is_command_installed.sh" || return "$?"
  source "./../messages.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

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

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  install_command "$@" || exit "$?"
fi
# ========================================
