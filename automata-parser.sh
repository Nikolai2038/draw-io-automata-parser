#!/bin/bash

# Start main script of Automata Parser
function main() {
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

  install_command "curl" || return "$?"

  # TODO: Main code

  return 0
}

main "$@" || exit "$?"
