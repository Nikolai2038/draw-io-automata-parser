#!/bin/bash

if [ -n "${IS_FILE_SOURCED_GET_NODE_ATTRIBUTE_VALUE}" ]; then
  return
fi

function get_node_attribute_value() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../../2_external_functions/messages.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo ""
    return 0
  fi

  local attribute_name="${1}" && shift
  if [ -z "${attribute_name}" ]; then
    print_error "You need to specify attribute name!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  echo "<xml>${xml}</xml>" | xpath -q -e "(//mxCell)/@${attribute_name}" | sed -E "s/^ ${attribute_name}=\"([^\"]+)\"\$/\\1/" || return "$?"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  get_node_attribute_value "$@" || exit "$?"
fi

export IS_FILE_SOURCED_GET_NODE_ATTRIBUTE_VALUE=1
