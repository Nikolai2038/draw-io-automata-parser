#!/bin/bash

SCRIPTS_VERSION="0.1.0"

ARRAY_INDEX_SEPARATOR="___"

TABLE_BEFORE_CELL_VALUE="   "
TABLE_AFTER_CELL_VALUE="   "
TABLE_EMPTY_CELL="?"

LAMBDA="L"
DELTA="D"

CALCULATE_K_ITERATION_LIMIT=50

DO_NOT_PRINT_CLASS_FAMILY_ID=0
DO_PRINT_CLASS_FAMILY_ID=1

# Start main script of Automata Parser
function automata_parser() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "./scripts/1_portable/package/install_command.sh" || return "$?"
  source "./scripts/1_portable/messages.sh" || return "$?"
  source "./scripts/2_inner/xpath/load_xml.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_nodes_count.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_with_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/class_family_calculate.sh" || return "$?"
  source "./scripts/2_inner/class_family_print.sh" || return "$?"
  cd - >/dev/null || return "$?"

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

  local ellipses_ids_as_string
  ellipses_ids_as_string="$(get_node_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}")" || return "$?"
  if [ -z "${ellipses_ids_as_string}" ]; then
    print_error "Ellipses ids as string is empty!"
    return 1
  fi
  declare -a ellipses_ids
  mapfile -t ellipses_ids <<<"${ellipses_ids_as_string}" || return "$?"

  local ellipses_values_as_string
  ellipses_values_as_string="$(get_node_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_VALUE}")" || return "$?"
  if [ -z "${ellipses_values_as_string}" ]; then
    print_error "Ellipses values as string is empty!"
    return 1
  fi
  declare -a ellipses_values
  mapfile -t ellipses_values <<<"${ellipses_values_as_string}" || return "$?"

  # TODO: Add this check later
  # declare -a ellipses_is_in_scheme=()
  # local ellipse_id_in_list
  # for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
  #   ellipses_is_in_scheme+=("0")
  # done

  declare -a variables_names=()

  # Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
  declare -A cells=()

  local ellipse_id_in_list
  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
    local ellipse_id="${ellipses_ids["${ellipse_id_in_list}"]}"
    local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"
    print_info "Calculate data for ellipse with value \"${ellipse_value}\"!"

    local arrows_from_ellipse
    arrows_from_ellipse="$(get_node_with_attribute_value "${CONNECTED_ARROWS_XML}" "${ATTRIBUTE_SOURCE}" "${ellipse_id}")" || return "$?"
    local arrows_from_ellipse_count
    arrows_from_ellipse_count="$(get_nodes_count "${arrows_from_ellipse}")" || return "$?"
    if ((arrows_from_ellipse_count < 1)); then
      continue
    fi

    local arrow_values_as_string
    arrow_values_as_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_VALUE}")"
    if [ -z "${arrow_values_as_string}" ]; then
      print_error "Arrow values as string is empty!"
      return 1
    fi
    declare -a arrow_values
    mapfile -t arrow_values <<<"${arrow_values_as_string}" || return "$?"

    local arrow_ids_string
    arrow_ids_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_ID}")"
    declare -a arrow_ids
    mapfile -t arrow_ids <<<"${arrow_ids_string}" || return "$?"

    local arrow_targets_string
    arrow_targets_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_TARGET}")"
    declare -a arrow_targets
    mapfile -t arrow_targets <<<"${arrow_targets_string}" || return "$?"

    local arrow_id_in_list
    for ((arrow_id_in_list = 0; arrow_id_in_list < arrows_from_ellipse_count; arrow_id_in_list++)); do
      local arrow_value="${arrow_values["${arrow_id_in_list}"]}"

      print_info "- Calculate data for arrow with value \"${arrow_value}\"!"

      local arrow_target_id="${arrow_targets["${arrow_id_in_list}"]}"
      local arrow_target_node
      arrow_target_node="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${arrow_target_id}")" || return "$?"
      local arrow_target_value
      arrow_target_value="$(get_node_attribute_value "${arrow_target_node}" "${ATTRIBUTE_VALUE}")" || return "$?"

      # DEBUG:
      # echo "arrow_id: $arrow_id"
      # echo "arrow_value: $arrow_value"
      # echo "arrow_target_value: $arrow_target_value"

      local arrow_variable_regexpr="([^\\/]+)\\/([^\\/]+)"

      local arrow_variable_name
      arrow_variable_name="$(echo "${arrow_value}" | sed -En "s/${arrow_variable_regexpr}/\1/p")" || return "$?"

      local arrow_variable_value
      arrow_variable_value="$(echo "${arrow_value}" | sed -En "s/${arrow_variable_regexpr}/\2/p")" || return "$?"

      if [ -z "${arrow_variable_name}" ] || [ -z "${arrow_variable_value}" ]; then
        print_error "Failed to get variable name and value from arrow with value \"${arrow_value}\" from ellipse with value \"${ellipse_value}\"! You must add text to arrow in format \"<variable name>/<variable value>\""
        return 1
      fi

      # Collecting all variables names into "variables_names" array
      variables_names+=("${arrow_variable_name}")

      local current_lambda="${cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      if [ -n "${current_lambda}" ]; then
        print_error "From ellipse with value \"${ellipse_value}\" there are more than one arrows with variable name \"${arrow_variable_name}\"!"
        return 1
      fi

      cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_variable_value}"
      cells["${DELTA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_target_value}"
    done
  done

  # Sort variables names
  local variables_names_string_sorted
  variables_names_string_sorted="$(echo "${variables_names[@]}" | tr ' ' '\n' | sort --unique)" || return "$?"
  mapfile -t variables_names <<<"${variables_names_string_sorted}" || return "$?"

  local variables_names_count="${#variables_names[@]}"

  # DEBUG:
  # echo "variables_names_count: $variables_names_count"

  # ----------------------------------------
  # Prepare for K calculations
  # ----------------------------------------
  declare -A lines_to_find_K=()

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
    local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"

    lines_to_find_K["0"]+="${ellipse_value}"

    # Make sure to not add extra line because we count them in class_family_calculate function
    if ((ellipse_id_in_list != ellipses_count - 1)); then
      lines_to_find_K["0"]+="
"
    fi

    local variable_name_id_in_list
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
      local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
      local current_lambda="${cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      lines_to_find_K["1"]+=" ${current_lambda:-"${TABLE_EMPTY_CELL}"}"
    done

    # Make sure to not add extra line because we count them in class_family_calculate function
    if ((ellipse_id_in_list != ellipses_count - 1)); then
      lines_to_find_K["1"]+="
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
  local prev_K="0"
  local current_K="1"
  local class_family_id=0
  local calculated_Ks=0

  while [[ "${current_K}" != "${prev_K}" ]] && ((class_family_id < CALCULATE_K_ITERATION_LIMIT)); do
    print_info "Calculate K${class_family_id}..."

    # For Ks greater than 1 we need to calculate lines_to_find_K based on previous K
    if ((class_family_id > 1)); then
      local familyOfClassesId_prev="$((class_family_id - 1))"

      for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
        local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"

        for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
          local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
          local current_delta="${cells["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"

          # Find cell value for previous K
          local K_cell_value=""

          local symbol_id
          for ((symbol_id = 0; symbol_id < CLASS_SYMBOLS_COUNT; symbol_id++)); do
            local class_name="${CLASS_SYMBOLS["${symbol_id}"]}${familyOfClassesId_prev}"
            local K_value="${K["${class_name}"]}"

            if [ -z "${K_value}" ]; then
              continue
            fi

            # Add extra spaces to match first and last numbers in K_value
            if [[ " ${K_value} " == *" ${current_delta} "* ]]; then
              K_cell_value="${class_name}"
              break
            fi
          done

          if [[ -z "${K_cell_value}" ]]; then
            print_error "Calculation for ${CLASS_FAMILY_SYMBOL} cell value failed! class_name = \"${class_name}\""
            return 1
          fi

          # DEBUG:
          # echo "current_delta: ${current_delta}; ellipse_value: ${ellipse_value}; variable_name_in_list: ${variable_name_in_list}; K_cell_value: ${K_cell_value}"

          cells["K${familyOfClassesId_prev}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${K_cell_value}"

          lines_to_find_K["${class_family_id}"]+=" ${K_cell_value:-"${TABLE_EMPTY_CELL}"}"
        done

        # Make sure to not add extra line because we count them in class_family_calculate function
        if ((ellipse_id_in_list != ellipses_count - 1)); then
          lines_to_find_K["${class_family_id}"]+="
"
        fi
      done
    fi

    class_family_calculate "${ellipses_values_as_string}" "${lines_to_find_K["${class_family_id}"]}" "${class_family_id}" || return "$?"
    ((calculated_Ks++))

    prev_K="${current_K}"
    current_K="$(class_family_print "${class_family_id}" "${DO_NOT_PRINT_CLASS_FAMILY_ID}")" || return "$?"

    print_info "K${class_family_id} = $(class_family_print "${class_family_id}" "${DO_PRINT_CLASS_FAMILY_ID}")" || return "$?"

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
  for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
    table_header_lambda+="${TABLE_BEFORE_CELL_VALUE}${LAMBDA}${TABLE_AFTER_CELL_VALUE}|"
    table_header_delta+="${TABLE_BEFORE_CELL_VALUE}${DELTA}${TABLE_AFTER_CELL_VALUE}|"

    local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
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

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
    local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"

    result+="|${TABLE_BEFORE_CELL_VALUE}${ellipse_value}${TABLE_AFTER_CELL_VALUE}"

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
      local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
      local current_lambda="${cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      result+="|${TABLE_BEFORE_CELL_VALUE}${current_lambda:-"${TABLE_EMPTY_CELL}"}${TABLE_AFTER_CELL_VALUE}"
    done

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
      local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
      local current_delta="${cells["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      result+="|${TABLE_BEFORE_CELL_VALUE}${current_delta:-"${TABLE_EMPTY_CELL}"}${TABLE_AFTER_CELL_VALUE}"
    done

    result+="|\n"
  done

  echo -e "${result}" | sort --unique

  # ----------------------------------------
  # Print K
  # ----------------------------------------
  echo ""
  for ((class_family_id = 0; class_family_id < calculated_Ks; class_family_id++)); do
    echo -n "K${class_family_id} = "
    class_family_print "${class_family_id}" "${DO_PRINT_CLASS_FAMILY_ID}" || return "$?"
  done
  # ----------------------------------------

  if ((!was_error)); then
    local last_calculated_familyOfClassesId="$((calculated_Ks - 1))"

    echo "${CLASS_FAMILY_SYMBOL}${last_calculated_familyOfClassesId} == ${CLASS_FAMILY_SYMBOL}$((last_calculated_familyOfClassesId - 1)) == ${CLASS_FAMILY_SYMBOL}"

    declare -a last_calculated_K_symbols=()

    local symbol_id
    for ((symbol_id = 0; symbol_id < CLASS_SYMBOLS_COUNT; symbol_id++)); do
      local symbol="${CLASS_SYMBOLS["${symbol_id}"]}"
      local class_name="${symbol}${last_calculated_familyOfClassesId}"
      local K_value="${K["${class_name}"]}"

      if [ -z "${K_value}" ]; then
        continue
      fi

      last_calculated_K_symbols+=("${symbol}")
    done

    if [[ -z "${K_cell_value}" ]]; then
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
