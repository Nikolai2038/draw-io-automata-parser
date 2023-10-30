#!/bin/bash

# ========================================
# Source this file only if wasn't sourced already
# ========================================
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
# ========================================

function template() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  # source "./scripts/..." || return "$?"
  # source "./scripts/..." || return "$?"
  # source "./scripts/..." || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  # None

  # ========================================
  # 3. Main code
  # ========================================

  # ...

  return 0
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  template "$@" || exit "$?"
fi
# ========================================
