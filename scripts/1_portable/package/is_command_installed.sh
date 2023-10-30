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
source "../messages.sh" || return "$?"

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || return "$?"
}

# Echo 1 if passed command name is installed, and 0 - if not installed.
function is_command_installed() {
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

  which "${command_name}" &> /dev/null && echo "1" || echo "0"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    is_command_installed "$@" || exit "$?"
  fi
}
