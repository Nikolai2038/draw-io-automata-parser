#!/bin/bash

# (REUSE) Source this file only if wasn't sourced already
{
  current_file_path="$(realpath "${BASH_SOURCE[0]}")" || exit "$?"
  current_file_hash="$(echo "${current_file_path}" | sha256sum | cut -d ' ' -f 1)" || exit "$?"
  current_file_is_sourced_variable_name="FILE_IS_SOURCED_${current_file_hash^^}"
  current_file_is_sourced="$(eval "echo \"\${${current_file_is_sourced_variable_name}}\"")" || exit "$?"
  if [ -n "${current_file_is_sourced}" ]; then
    return
  fi
  eval "export ${current_file_is_sourced_variable_name}=1" || exit "$?"
  if [ "${IS_DEBUG_BASH}" == "1" ]; then
    if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
      echo "Executing \"${current_file_path}\"..." >&2
    else
      echo "Sourcing \"${current_file_path}\"..." >&2
    fi
  fi
}

# (REUSE) Prepare before imports
{
  source_previous_directory="${PWD}"
  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || return "$?"
}

# Imports
source "./is_command_installed.sh"
source "./../messages.sh"

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || return "$?"
}

# Install command with specified name
function install_command() {
  local command_name="${1}"
  if [ -z "${command_name}" ]; then
    print_error "You need to specify command name!"
    return 1
  fi

  local package_name="${2}"

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

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    install_command "$@" || exit "$?"
  fi
}
