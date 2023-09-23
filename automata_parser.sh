#!/bin/bash

# Start main script of Automata Parser
function automata_parser() {
  # ========================================
  # 1. Working directory
  # ========================================

  # We will work in this script's directory
  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"

  # ========================================
  # 2. Imports
  # ========================================

  source "./scripts/package/install_command.sh" || return "$?"

  # ========================================
  # 3. Arguments
  # ========================================

  # None

  # ========================================
  # 4. Main code
  # ========================================

  local version="0.1.0"
  echo "Automata Parser v.${version}" >&2

  install_command "curl" || return "$?"

  # TODO: Main code

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
