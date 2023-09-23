#!/bin/bash

# TODO: Function's description
function template() {
  # ========================================
  # 1. Working directory
  # ========================================

  # We will work in this script's directory
  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"

  # ========================================
  # 2. Imports
  # ========================================

  # None

  # ========================================
  # 3. Arguments
  # ========================================

  # None

  # ========================================
  # 4. Main code
  # ========================================

  # TODO: Function's main code

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  template "$@" || exit "$?"
fi
