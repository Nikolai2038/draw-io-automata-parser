#!/bin/bash

# Start main script of Automata Parser
function automata_parser() {
  # ========================================
  # 1. Imports
  # ========================================

  local directory_with_script
  directory_with_script="$(dirname "${BASH_SOURCE[0]}")" || return "$?"

  # shellcheck source=./scripts/package/install_command.sh
  source "${directory_with_script}/scripts/package/install_command.sh" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local version="0.1.0"
  echo "Automata Parser v.${version}" >&2

  local filePath="${1}" && shift
  if [ -z "${filePath}" ]; then
    echo "You need to specify file path!" >&2
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  install_command "xpath" "libxml-xpath-perl" || return "$?"

  xpath -e '//mxCell' "${filePath}"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
