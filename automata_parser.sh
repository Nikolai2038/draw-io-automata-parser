#!/bin/bash

export SCRIPTS_VERSION="0.1.0"

export ARRAY_INDEX_SEPARATOR="___"

export TABLE_BEFORE_CELL_VALUE="   "
export TABLE_AFTER_CELL_VALUE="   "
export TABLE_EMPTY_CELL="?"

export LAMBDA="L"
export DELTA="D"

export CALCULATE_K_ITERATION_LIMIT=50

export DO_NOT_PRINT_CLASS_FAMILY_ID=0
export DO_PRINT_CLASS_FAMILY_ID=1

# Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
declare -A CELLS=()

# Start main script of Automata Parser
function automata_parser() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "./scripts/1_portable/package/install_command.sh" || return "$?"
  source "./scripts/1_portable/messages.sh" || return "$?"
  source "./scripts/2_inner/xpath/load_xml.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_nodes_count.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_with_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/xpath/fill_lamda_and_delta_and_variables_names.sh" || return "$?"
  source "./scripts/2_inner/class_family_calculate.sh" || return "$?"
  source "./scripts/2_inner/class_family_print.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  print_info "Automata Parser ${C_HIGHLIGHT}v.${SCRIPTS_VERSION}${C_RETURN}"

  local file_path="${1}" && shift
  if [ -z "${file_path}" ]; then
    print_error "You need to specify file path!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  load_xml "${file_path}" || return "$?"

  print_info "Parsing..."

  fill_lamda_and_delta_and_variables_names || return "$?"

  # ----------------------------------------
  # Prepare for K calculations
  # ----------------------------------------
  declare -A lines_to_find_family_class=()

  local ellipse_id_in_list
  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"

    lines_to_find_family_class["0"]+="${ellipse_value}"

    # Make sure to not add extra line because we count them in class_family_calculate function
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      lines_to_find_family_class["0"]+="
"
    fi

    local variable_name_id_in_list
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local current_lambda="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      lines_to_find_family_class["1"]+=" ${current_lambda:-"${TABLE_EMPTY_CELL}"}"
    done

    # Make sure to not add extra line because we count them in class_family_calculate function
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      lines_to_find_family_class["1"]+="
"
    fi
  done

  # DEBUG:
  # declare -p lines_to_find_K
  # ----------------------------------------

  # ----------------------------------------
  # Calculate K
  # ----------------------------------------
  # Initialization values must be different here
  local class_family_previous="0"
  local class_family_current="1"
  local class_family_id=0
  local class_families_count=0
  local last_calculated_class_family_id=0

  while [[ "${class_family_current}" != "${class_family_previous}" ]] && ((class_family_id < CALCULATE_K_ITERATION_LIMIT)); do
    print_info "Calculate ${C_HIGHLIGHT}${CLASS_FAMILY_SYMBOL}${class_family_id}${C_RETURN}..."

    # For Ks greater than 1 we need to calculate lines_to_find_K based on previous family class
    if ((class_family_id > 1)); then
      local class_family_id_previous="$((class_family_id - 1))"

      for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
        local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"

        for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
          local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
          local current_delta="${CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"

          # Find cell value for previous family class
          local class_family_linked_cell_value=""

          local symbol_id
          for ((symbol_id = 0; symbol_id < CLASS_SYMBOLS_COUNT; symbol_id++)); do
            local class_name="${CLASS_SYMBOLS["${symbol_id}"]}${class_family_id_previous}"
            local class_family_linked_name="${CLASS_FAMILIES["${class_name}"]}"

            if [ -z "${class_family_linked_name}" ]; then
              continue
            fi

            # Add extra spaces to match first and last numbers in class_family_linked_name
            if [[ " ${class_family_linked_name} " == *" ${current_delta} "* ]]; then
              class_family_linked_cell_value="${class_name}"
              break
            fi
          done

          if [[ -z "${class_family_linked_cell_value}" ]]; then
            print_error "Calculation for ${CLASS_FAMILY_SYMBOL} cell value failed! class_name = \"${class_name}\""
            return 1
          fi

          # DEBUG:
          # echo "current_delta: ${current_delta}; ellipse_value: ${ellipse_value}; variable_name_in_list: ${variable_name_in_list}; K_cell_value: ${K_cell_value}"

          CELLS["${CLASS_FAMILY_SYMBOL}${class_family_id_previous}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${class_family_linked_cell_value}"

          lines_to_find_family_class["${class_family_id}"]+=" ${class_family_linked_cell_value:-"${TABLE_EMPTY_CELL}"}"
        done

        # Make sure to not add extra line because we count them in class_family_calculate function
        if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
          lines_to_find_family_class["${class_family_id}"]+="
"
        fi
      done
    fi

    class_family_calculate "${ELLIPSES_VALUES_AS_STRING}" "${lines_to_find_family_class["${class_family_id}"]}" "${class_family_id}" || return "$?"
    last_calculated_class_family_id="$((class_families_count))"
    ((class_families_count++))

    class_family_previous="${class_family_current}"
    class_family_current="$(class_family_print "${class_family_id}" "${DO_NOT_PRINT_CLASS_FAMILY_ID}")" || return "$?"

    print_info "- ${C_HIGHLIGHT}${CLASS_FAMILY_SYMBOL}${class_family_id} = $(class_family_print "${class_family_id}" "${DO_PRINT_CLASS_FAMILY_ID}")${C_RETURN}" || return "$?"

    ((class_family_id++))
  done

  local was_error=0
  if ((class_family_id >= CALCULATE_K_ITERATION_LIMIT)); then
    print_error "Calculate ${CLASS_FAMILY_SYMBOL} iteration limit (${class_family_id}/${CALCULATE_K_ITERATION_LIMIT} iterations) was reached! If there are huge automate, and you think this is a mistake, increase \"CALCULATE_K_ITERATION_LIMIT\" variable."
    was_error=1
  fi
  # ----------------------------------------

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

    # TODO: Calculate u0min
    echo "u0min = ..."

    # TODO: Calculate result table
    # ...

    # TODO: Insert K columns in first table
    # ...

    # TODO: Add check on infinite K calculating when they switch each other
    # ...
  fi

  echo "================================================================================"

  if ((was_error)); then
    print_error "Parsing: failed!"
  else
    print_success "Parsing: done!"
  fi

  return "${was_error}"
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
