#!/bin/bash

if [ -n "${IS_FILE_SOURCED_GET_NODES_COUNT}" ]; then
  return
fi

function get_nodes_count() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../../1_portable/messages.sh" || return "$?"
  cd - >/dev/null || return "$?"

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

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  get_nodes_count "$@" || exit "$?"
fi

export IS_FILE_SOURCED_GET_NODES_COUNT=1
