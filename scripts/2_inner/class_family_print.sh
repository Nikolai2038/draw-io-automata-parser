#!/bin/bash

if [ -n "${IS_FILE_SOURCED_CLASS_FAMILY_PRINT}" ]; then
  return
fi

function class_family_print() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../1_portable/messages.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify class family id!"
    return 1
  fi

  local do_print_class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify do or do not print class family id!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  echo -n "{"

  local is_first_class_to_print=1

  local class_symbol_id
  for ((class_symbol_id = 0; class_symbol_id < CLASS_SYMBOLS_COUNT; class_symbol_id++)); do
    local class_symbol="${CLASS_SYMBOLS["${class_symbol_id}"]}"
    local class_key="${class_symbol}${class_family_id}"

    local class_value="${CLASS_FAMILIES["${class_key}"]}"

    if [ -z "${class_value}" ]; then
      continue
    fi

    if ((is_first_class_to_print)); then
      is_first_class_to_print=0
    else
      echo -n ","
    fi

    echo -n " ${class_symbol}"

    local class_value_with_commas
    class_value_with_commas="$(echo "${class_value}" | sed -E 's/ /,/g')" || return "$?"

    if ((do_print_class_family_id)); then
      echo -n "${class_family_id}={${class_value_with_commas}}"
    else
      echo -n "={${class_value_with_commas}}"
    fi
  done

  echo " }"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  class_family_print "$@" || exit "$?"
fi

export IS_FILE_SOURCED_CLASS_FAMILY_PRINT=1
