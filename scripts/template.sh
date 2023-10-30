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
