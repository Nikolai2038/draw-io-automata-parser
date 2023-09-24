#!/bin/bash

if [ -n "${IS_FILE_SOURCED_PRINT_CALCULATIONS_RESULT}" ]; then
  return
fi

export TABLE_BEFORE_CELL_VALUE="   "
export TABLE_AFTER_CELL_VALUE="   "
export TABLE_EMPTY_CELL="?"

function print_calculations_result() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "../1_portable/messages.sh" || return "$?"
  source "./class_family_print.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local was_error="${1:-0}" && shift

  # ========================================
  # 3. Main code
  # ========================================

  # ----------------------------------------
  # Creating table's headers
  # ----------------------------------------
  local table_header_lambda=""
  local table_header_delta=""
  local table_header_variables=""

  local variable_name_id_in_list
  for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
    table_header_lambda+="${TABLE_BEFORE_CELL_VALUE}${LAMBDA}${TABLE_AFTER_CELL_VALUE}|"
    table_header_delta+="${TABLE_BEFORE_CELL_VALUE}${DELTA}${TABLE_AFTER_CELL_VALUE}|"

    local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
    table_header_variables+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}|"
  done
  table_header_lambda+=""

  local header=""

  header+="|${TABLE_BEFORE_CELL_VALUE} ${TABLE_AFTER_CELL_VALUE}|${table_header_lambda}${table_header_delta}\n"
  header+="|${TABLE_BEFORE_CELL_VALUE} ${TABLE_AFTER_CELL_VALUE}|${table_header_variables}${table_header_variables}"
  # ----------------------------------------

  echo "================================================================================"
  echo "Result:"
  echo "================================================================================"
  echo "u0 = ${START_ARROW_TARGET_VALUE}"

  echo ""
  echo -en "${header}"

  local result

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"

    result+="|${TABLE_BEFORE_CELL_VALUE}${ellipse_value}${TABLE_AFTER_CELL_VALUE}"

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local current_lambda="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      result+="|${TABLE_BEFORE_CELL_VALUE}${current_lambda:-"${TABLE_EMPTY_CELL}"}${TABLE_AFTER_CELL_VALUE}"
    done

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local current_delta="${CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      result+="|${TABLE_BEFORE_CELL_VALUE}${current_delta:-"${TABLE_EMPTY_CELL}"}${TABLE_AFTER_CELL_VALUE}"
    done

    result+="|\n"
  done

  echo -e "${result}" | sort --unique

  # ----------------------------------------
  # Print K
  # ----------------------------------------
  echo ""
  for ((class_family_id = 0; class_family_id < class_families_count; class_family_id++)); do
    echo -n "${CLASS_FAMILY_SYMBOL}${class_family_id} = "
    class_family_print "${class_family_id}" "${DO_PRINT_CLASS_FAMILY_ID}" || return "$?"
  done
  # ----------------------------------------

  if ((!was_error)); then
    echo "${CLASS_FAMILY_SYMBOL}${last_calculated_class_family_id} == ${CLASS_FAMILY_SYMBOL}$((last_calculated_class_family_id - 1)) == ${CLASS_FAMILY_SYMBOL}"

    declare -a last_calculated_K_symbols=()

    local symbol_id
    for ((symbol_id = 0; symbol_id < CLASS_SYMBOLS_COUNT; symbol_id++)); do
      local symbol="${CLASS_SYMBOLS["${symbol_id}"]}"
      local class_name="${symbol}${last_calculated_class_family_id}"
      local class_family_linked_name="${CLASS_FAMILIES["${class_name}"]}"

      if [ -z "${class_family_linked_name}" ]; then
        continue
      fi

      last_calculated_K_symbols+=("${symbol}")
    done

    if [[ -z "${class_family_linked_cell_value}" ]]; then
      print_error "Calculation for ${CLASS_FAMILY_SYMBOL} cell value failed!"
      return 1
    fi

    # ----------------------------------------
    # Print Smin
    # ----------------------------------------
    echo ""
    echo -n "Smin = {"

    local is_first=1

    local last_calculated_K_symbols_count="${#last_calculated_K_symbols[@]}"
    for ((symbol_id = 0; symbol_id < last_calculated_K_symbols_count; symbol_id++)); do
      local symbol="${last_calculated_K_symbols["${symbol_id}"]}"

      if ((is_first)); then
        is_first=0
      else
        echo -n ","
      fi

      echo -n " ${symbol}"
    done

    echo " }"
    # ----------------------------------------

    echo "u0min = ..."
  fi

  echo "================================================================================"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  print_calculations_result "$@" || exit "$?"
fi

export IS_FILE_SOURCED_PRINT_CALCULATIONS_RESULT=1
