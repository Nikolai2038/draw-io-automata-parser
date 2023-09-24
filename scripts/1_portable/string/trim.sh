#!/bin/bash

if [ -n "${IS_FILE_SOURCED_TRIM}" ]; then
  return
fi

function trim() {
  # ========================================
  # 1. Imports
  # ========================================

  # None

  # ========================================
  # 2. Arguments
  # ========================================

  local text="${1}" && shift

  # ========================================
  # 3. Main code
  # ========================================

  # First we use sed to remove empty lines at the beginning and end of the text, then we use set to remove extra spaces at the beginning of the first line and at the end of the last
  echo "${text}" | sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}' -e '/./,$!d' | sed -e '1s/^[[:space:]]*//' -e '$s/[[:space:]]*$//' || return "$?"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  trim "$@" || exit "$?"
fi

export IS_FILE_SOURCED_TRIM=1
