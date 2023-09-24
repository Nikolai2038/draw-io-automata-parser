#!/bin/bash

if [ -n "${IS_FILE_SOURCED_TEMPLATE}" ]; then
  return
fi

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

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  template "$@" || exit "$?"
fi

export IS_FILE_SOURCED_TEMPLATE=1
