#!/bin/bash

if [ -n "${IS_FILE_SOURCED_CLASS_FAMILY_CALCULATE}" ]; then
  return
fi

function class_family_calculate() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "../2_external_functions/messages.sh" || return "$?"
  source "../3_inner_constants/class_symbols.sh" || return "$?"
  cd - >/dev/null || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local ellipses_values_as_string="${1}" && shift
  if [ -z "${ellipses_values_as_string}" ]; then
    print_error "You need to specify ellipses values as string!"
    return 1
  fi

  local lines_as_string="${1}" && shift
  if [ -z "${lines_as_string}" ]; then
    print_error "You need to specify lines as string!"
    return 1
  fi

  local class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify class family id!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  declare -a ellipses_values
  mapfile -t ellipses_values <<<"${ellipses_values_as_string}" || return "$?"

  declare -a lines
  mapfile -t lines <<<"${lines_as_string}" || return "$?"

  local lines_count="${#lines[@]}"

  local free_symbol_id=0
  declare -A line_to_symbol=()

  local line_id
  for ((line_id = 0; line_id < lines_count; line_id++)); do
    local line="${lines["${line_id}"]}"

    local class_symbol="${line_to_symbol["${line}"]}"
    if [ -z "${class_symbol}" ]; then
      line_to_symbol["${line}"]="${CLASS_SYMBOLS["${free_symbol_id}"]}${class_family_id}"
      class_symbol="${line_to_symbol["${line}"]}"
      ((free_symbol_id++))
      if ((free_symbol_id >= CLASS_SYMBOLS_COUNT)); then
        echo "Need to increase CLASS_SYMBOLS array!"
        return 1
      fi
    fi

    if [ -n "${K["${class_symbol}"]}" ]; then
      K["${class_symbol}"]+=" "
    fi

    K["${class_symbol}"]+="${ellipses_values["${line_id}"]}"
  done

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  class_family_calculate "$@" || exit "$?"
fi

export IS_FILE_SOURCED_CLASS_FAMILY_CALCULATE=1