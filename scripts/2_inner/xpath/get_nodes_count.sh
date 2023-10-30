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

function get_nodes_count() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "../../1_portable/messages.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo 0
    return 0
  fi

  # ========================================
  # 3. Main code
  # ========================================

  echo "<xml>${xml}</xml>" | xpath -q -e "count(//mxCell)" || return "$?"

  return 0
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  get_nodes_count "$@" || exit "$?"
fi
# ========================================
