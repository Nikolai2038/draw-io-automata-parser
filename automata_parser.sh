#!/bin/bash

ATTRIBUTE_ID="id"
ATTRIBUTE_TARGET="target"
ATTRIBUTE_SOURCE="source"
ATTRIBUTE_VALUE="value"
ARRAY_INDEX_SEPARATOR="___"
TABLE_BEFORE_CELL_VALUE="   "
TABLE_AFTER_CELL_VALUE="   "
TABLE_EMPTY_CELL="?"
LAMBDA="L"
DELTA="D"
CALCULATE_K_ITERATION_LIMIT=5

DO_NOT_PRINT_K_ID=0
PRINT_K_ID=1

declare -a ALPHABET=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")
ALPHABET_SIZE="${#ALPHABET[@]}"
declare -A K=()

function get_nodes_count() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo 0
    return 0
  fi

  echo "<xml>${xml}</xml>" | xpath -q -e "count(//mxCell)" || return "$?"

  return 0
}

function get_node_attribute_value() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo ""
    return 0
  fi

  local attribute_name="${1}" && shift
  if [ -z "${attribute_name}" ]; then
    echo "You need to specify attribute name!" >&2
    return 1
  fi

  echo "<xml>${xml}</xml>" | xpath -q -e "(//mxCell)/@${attribute_name}" | sed -E "s/^ ${attribute_name}=\"([^\"]+)\"\$/\\1/" || return "$?"

  return 0
}

function get_node_with_attribute_value() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo ""
    return 0
  fi

  local attribute_name="${1}" && shift
  if [ -z "${attribute_name}" ]; then
    echo "You need to specify attribute name!" >&2
    return 1
  fi

  local attribute_value="${1}" && shift
  if [ -z "${attribute_value}" ]; then
    echo "You need to specify attribute value!" >&2
    return 1
  fi

  echo "<xml>${xml}</xml>" | xpath -q -e "(//mxCell[@${attribute_name}=\"${attribute_value}\"]" || return "$?"

  return 0
}

function calculate_K() {
  local ellipses_values_as_string="${1}" && shift
  if [ -z "${ellipses_values_as_string}" ]; then
    echo "You need to specify ellipses values as string!" >&2
    return 1
  fi

  local lines_as_string="${1}" && shift
  if [ -z "${lines_as_string}" ]; then
    echo "You need to specify lines as string!" >&2
    return 1
  fi

  local K_id="${1}" && shift
  if [ -z "${K_id}" ]; then
    echo "You need to specify K id!" >&2
    return 1
  fi

  declare -a ellipses_values
  mapfile -t ellipses_values <<< "${ellipses_values_as_string}" || return "$?"

  declare -a lines
  mapfile -t lines <<< "${lines_as_string}" || return "$?"

  local lines_count="${#lines[@]}"

  # DEBUG:
  # echo "lines_count: $lines_count"

  local free_symbol_id=0
  declare -A line_to_symbol=()

  local line_id
  for ((line_id = 0; line_id < lines_count; line_id++)); do
    local line="${lines["${line_id}"]}"

    local symbol="${line_to_symbol["${line}"]}"
    if [ -z "${symbol}" ]; then
      line_to_symbol["${line}"]="${ALPHABET["${free_symbol_id}"]}${K_id}"
      symbol="${line_to_symbol["${line}"]}"
      ((free_symbol_id++))
      if ((free_symbol_id >= ALPHABET_SIZE)); then
        echo "Need to increase ALPHABET!" >&2
        return 1
      fi
    fi

    if [ -n "${K["${symbol}"]}" ]; then
      K["${symbol}"]+=" "
    fi

    K["${symbol}"]+="${ellipses_values["${line_id}"]}"

    # DEBUG:
    # echo "${symbol}: $((line_id + 1))"
  done

  # DEBUG:
  # declare -p K

  return 0
}

function print_K() {
  local K_id="${1}" && shift
  if [ -z "${K_id}" ]; then
    echo "You need to specify K id!" >&2
    return 1
  fi

  local print_K_id="${1}" && shift
  if [ -z "${K_id}" ]; then
    echo "You need to specify print or do not print K_id!" >&2
    return 1
  fi

  echo -n "{"

  local is_first=1

  local symbol_id
  for ((symbol_id = 0; symbol_id < ALPHABET_SIZE; symbol_id++)); do
    local symbol="${ALPHABET["${symbol_id}"]}"
    local class_name="${symbol}${K_id}"

    local K_value="${K["${class_name}"]}"

    if [ -z "${K_value}" ]; then
      continue
    fi

    if ((is_first)); then
      is_first=0
    else
      echo -n ","
    fi

    echo -n " ${symbol}"

    local K_value_pretty
    K_value_pretty="$(echo "${K_value}" | sed -E 's/ /,/g')" || return "$?"

    if ((print_K_id)); then
      echo -n "${K_id}={${K_value_pretty}}"
    else
      echo -n "={${K_value_pretty}}"
    fi
  done

  echo " }"

  return 0
}

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

  echo "Parsing file \"${filePath}\"..." >&2

  local file_content
  file_content="$(cat "${filePath}")" || return "$?"

  # ----------------------------------------
  # Elements
  # ----------------------------------------
  local elements
  elements="$(echo "${file_content}" | xpath -q -e "
    //mxCell
  ")" || return "$?"
  local elements_count
  elements_count="$(get_nodes_count "${elements}")" || return "$?"

  if ((elements_count < 1)); then
    echo "No elements found!" >&2
    return 1
  fi
  echo "Found ${elements_count} elements!" >&2
  # ----------------------------------------

  # ----------------------------------------
  # Elipses
  # ----------------------------------------
  local ellipses
  ellipses="$(echo "<xml>${elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"ellipse;\")
    ]
  ")" || return "$?"
  local ellipses_count
  ellipses_count="$(get_nodes_count "${ellipses}")" || return "$?"

  if ((ellipses_count < 1)); then
    echo "No ellipses found!" >&2
    return 1
  fi
  echo "Found ${ellipses_count} ellipses!" >&2
  # ----------------------------------------

  # ----------------------------------------
  # Arrows
  # ----------------------------------------
  local arrows
  arrows="$(echo "<xml>${elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"edgeStyle\")
    ]
  ")" || return "$?"
  local arrows_count
  arrows_count="$(get_nodes_count "${arrows}")" || return "$?"

  if ((arrows_count < 1)); then
    echo "No arrows found!" >&2
    return 1
  fi
  echo "Found ${arrows_count} arrows!" >&2
  # ----------------------------------------

  # ----------------------------------------
  # Start arrow
  # ----------------------------------------
  local start_arrow
  start_arrow="$(echo "<xml>${arrows}</xml>" | xpath -q -e "
    //mxCell[
      not(@source)
      and
      @target
    ]
  ")" || return "$?"
  local start_arrow_count
  start_arrow_count="$(get_nodes_count "${start_arrow}")" || return "$?"

  if ((start_arrow_count < 1)); then
    echo "No start arrow found! You need to create arrow with no source but connect it to some ellipse." >&2
    return 1
  elif ((start_arrow_count > 1)); then
    echo "Only one start arrow is allowed! Found: ${start_arrow_count}. IDs:" >&2
    get_node_attribute_value "${start_arrow}" "${ATTRIBUTE_ID}"
    return 1
  fi
  echo "Start arrow found!" >&2

  # Find first ellipsis id
  local start_arrow_target_id
  start_arrow_target_id="$(get_node_attribute_value "${start_arrow}" "${ATTRIBUTE_TARGET}")" || return "$?"

  # Find first ellipsis node
  local start_arrow_target
  start_arrow_target="$(get_node_with_attribute_value "${ellipses}" "${ATTRIBUTE_ID}" "${start_arrow_target_id}")" || return "$?"

  # Find first ellipsis value
  local start_arrow_target_value
  start_arrow_target_value="$(get_node_attribute_value "${start_arrow_target}" "${ATTRIBUTE_VALUE}")" || return "$?"
  # ----------------------------------------

  # ----------------------------------------
  # Disconnected arrows
  # ----------------------------------------
  local disconnected_arrows
  disconnected_arrows="$(echo "<xml>${arrows}</xml>" | xpath -q -e "
    //mxCell[
      (
        @source
        and
        not(@target)
      )
      or
      (
        not(@source)
        and
        not(@target)
      )
    ]
  ")" || return "$?"

  if [ -n "${disconnected_arrows}" ]; then
    local disconnected_arrows_count
    disconnected_arrows_count="$(get_nodes_count "${disconnected_arrows}")" || return "$?"
    if ((disconnected_arrows_count > 0)); then
      echo "Found ${disconnected_arrows_count} disconnected arrows! IDs:" >&2
      get_node_attribute_value "${disconnected_arrows}" "${ATTRIBUTE_ID}"
      return 1
    fi
  fi
  echo "No disconnected arrows found!" >&2
  # ----------------------------------------

  # ----------------------------------------
  # Connected arrows
  # ----------------------------------------
  local connected_arrows
  connected_arrows="$(echo "<xml>${arrows}</xml>" | xpath -q -e "
    //mxCell[
      @source
      and
      @target
    ]
  ")" || return "$?"
  local connected_arrows_count
  connected_arrows_count="$(get_nodes_count "${connected_arrows}")" || return "$?"

  if ((connected_arrows_count < 1)); then
    echo "No connected arrows found!" >&2
    return 1
  fi
  echo "Found ${connected_arrows_count} connected arrows!" >&2
  # ----------------------------------------

  local ellipses_ids_string
  ellipses_ids_string="$(get_node_attribute_value "${ellipses}" "${ATTRIBUTE_ID}")" || return "$?"
  declare -a ellipses_ids
  mapfile -t ellipses_ids <<< "${ellipses_ids_string}" || return "$?"

  local ellipses_values_string
  ellipses_values_string="$(get_node_attribute_value "${ellipses}" "${ATTRIBUTE_VALUE}")" || return "$?"
  declare -a ellipses_values
  mapfile -t ellipses_values <<< "${ellipses_values_string}" || return "$?"

  # TODO: Add this check later
  # declare -a ellipses_is_in_scheme=()
  # local ellipse_id_in_list
  # for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
  #   ellipses_is_in_scheme+=("0")
  # done

  declare -a variables_names=()

  # Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
  declare -A cells=()

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
    local ellipse_id="${ellipses_ids["${ellipse_id_in_list}"]}"
    local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"
    echo "Calcullate data for ellipse (id \"${ellipse_id}\", value \"${ellipse_value}\")!" >&2

    local arrows_from_ellipse
    arrows_from_ellipse="$(get_node_with_attribute_value "${connected_arrows}" "${ATTRIBUTE_SOURCE}" "${ellipse_id}")" || return "$?"
    local arrows_from_ellipse_count
    arrows_from_ellipse_count="$(get_nodes_count "${arrows_from_ellipse}")" || return "$?"
    if ((arrows_from_ellipse_count < 1)); then
      continue
    fi

    # DEBUG:
    # echo "arrows_from_ellipse_count: $arrows_from_ellipse_count"
    # echo "arrows_from_ellipse: $arrows_from_ellipse"

    local arrow_values_string
    arrow_values_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_VALUE}")"
    declare -a arrow_values
    mapfile -t arrow_values <<< "${arrow_values_string}" || return "$?"

    # DEBUG:
    # echo "arrow_values_string: $arrow_values_string"

    local arrow_ids_string
    arrow_ids_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_ID}")"
    declare -a arrow_ids
    mapfile -t arrow_ids <<< "${arrow_ids_string}" || return "$?"

    local arrow_targets_string
    arrow_targets_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_TARGET}")"
    declare -a arrow_targets
    mapfile -t arrow_targets <<< "${arrow_targets_string}" || return "$?"

    local arrow_id_in_list
    for ((arrow_id_in_list = 0; arrow_id_in_list < arrows_from_ellipse_count; arrow_id_in_list++)); do
      local arrow_id="${arrow_ids["${arrow_id_in_list}"]}"
      local arrow_value="${arrow_values["${arrow_id_in_list}"]}"

      echo "  Calcullate data for arrow (id \"${arrow_id}\", value \"${arrow_value}\")!" >&2

      local arrow_target_id="${arrow_targets["${arrow_id_in_list}"]}"
      local arrow_target_node
      arrow_target_node="$(get_node_with_attribute_value "${ellipses}" "${ATTRIBUTE_ID}" "${arrow_target_id}")" || return "$?"
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
        echo "Failed to get variable name and value from arrow (id \"${arrow_id}\", value \"${arrow_value}\") from ellipse (id \"${ellipse_id}\", value \"${ellipse_value}\")! You must add text to arrow in format \"<variable name>/<variable value>\"" >&2
        return 1
      fi

      # Collecting all variables names into "variables_names" array
      variables_names+=("${arrow_variable_name}")

      local current_lambda="${cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      if [ -n "${current_lambda}" ]; then
        echo "From ellipse (id \"${ellipse_id}\", value \"${ellipse_value}\") there are more than one arrows with variable name \"${arrow_variable_name}\"!" >&2
        return 1
      fi

      cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_variable_value}"
      cells["${DELTA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_target_value}"
    done
  done

  # Sort variables names
  local variables_names_string_sorted
  variables_names_string_sorted="$(echo "${variables_names[@]}" | tr ' ' '\n' | sort --unique)" || return "$?"
  mapfile -t variables_names <<< "${variables_names_string_sorted}" || return "$?"

  local variables_names_count="${#variables_names[@]}"

  # DEBUG:
  # echo "variables_names_count: $variables_names_count"

  # ----------------------------------------
  # Prepare for K calculations
  # ----------------------------------------
  declare -A lines_to_find_K=()
  local ellipses_values_as_string

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
    local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"

    lines_to_find_K["0"]+="${ellipse_value}"
    ellipses_values_as_string+="${ellipse_value}"

    # Make sure to not add extra line because we count them in calculate_K function
    if ((ellipse_id_in_list != ellipses_count - 1)); then
      lines_to_find_K["0"]+="
"
      ellipses_values_as_string+="
"
    fi

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
      local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
      local current_lambda="${cells["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      lines_to_find_K["1"]+=" ${current_lambda:-"${TABLE_EMPTY_CELL}"}"
    done

    # Make sure to not add extra line because we count them in calculate_K function
    if ((ellipse_id_in_list != ellipses_count - 1)); then
      lines_to_find_K["1"]+="
"
    fi

    result+="\n"
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
  local K_id=0
  local calculated_Ks=0

  while [[ "${current_K}" != "${prev_K}" ]] && ((K_id < CALCULATE_K_ITERATION_LIMIT)); do
    # For Ks greater than 1 we need to calculate lines_to_find_K based on previous K
    if ((K_id > 1)); then
      local K_id_prev="$((K_id - 1))"

      for ((ellipse_id_in_list = 0; ellipse_id_in_list < ellipses_count; ellipse_id_in_list++)); do
        local ellipse_value="${ellipses_values["${ellipse_id_in_list}"]}"

        for ((variable_name_id_in_list = 0; variable_name_id_in_list < variables_names_count; variable_name_id_in_list++)); do
          local variable_name_in_list="${variables_names["${variable_name_id_in_list}"]}"
          local current_delta="${cells["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"

          # Find cell value for previous K
          local K_cell_value=""

          local symbol_id
          for ((symbol_id = 0; symbol_id < ALPHABET_SIZE; symbol_id++)); do
            local class_name="${ALPHABET["${symbol_id}"]}${K_id_prev}"
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
            echo "Calculation for K cell value failed!" >&2
            return 1
          fi

          # DEBUG:
          # echo "current_delta: ${current_delta}; ellipse_value: ${ellipse_value}; variable_name_in_list: ${variable_name_in_list}; K_cell_value: ${K_cell_value}"

          cells["K${K_id_prev}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${K_cell_value}"

          lines_to_find_K["${K_id}"]+=" ${K_cell_value:-"${TABLE_EMPTY_CELL}"}"
        done

        # Make sure to not add extra line because we count them in calculate_K function
        if ((ellipse_id_in_list != ellipses_count - 1)); then
          lines_to_find_K["${K_id}"]+="
"
        fi

        result+="\n"
      done
    fi

    echo "Calculate K${K_id}..."

    calculate_K "${ellipses_values_as_string}" "${lines_to_find_K["${K_id}"]}" "${K_id}" || return "$?"
    ((calculated_Ks++))

    prev_K="${current_K}"
    current_K="$(print_K "${K_id}" "${DO_NOT_PRINT_K_ID}")" || return "$?"

    # DEBUG:
    echo "prev_K: ${prev_K}"
    echo "current_K: ${current_K}"

    ((K_id++))
  done

  local was_error=0
  if ((K_id >= CALCULATE_K_ITERATION_LIMIT)); then
    echo "Calculate K iteration limit (${K_id}/${CALCULATE_K_ITERATION_LIMIT} iterations) was reached! If there are huge automate and you think this is a mistake, increase \"CALCULATE_K_ITERATION_LIMIT\" variable." >&2
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

  echo ""
  echo "================================================================================"
  echo "Result:"
  echo "================================================================================"
  echo "u0 = ${start_arrow_target_value}"

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
  for ((K_id = 0; K_id < calculated_Ks; K_id++)); do
    echo -n "K${K_id} = "
    print_K "${K_id}" "${PRINT_K_ID}" || return "$?"
  done
  # ----------------------------------------

  echo ""
  if ((!was_error)); then
    local last_calculated_K_id="$((calculated_Ks - 1))"

    echo "K${last_calculated_K_id} == K$((last_calculated_K_id - 1)) == K"

    declare -a last_calculated_K_symbols=()

    local symbol_id
    for ((symbol_id = 0; symbol_id < ALPHABET_SIZE; symbol_id++)); do
      local symbol="${ALPHABET["${symbol_id}"]}"
      local class_name="${symbol}${last_calculated_K_id}"
      local K_value="${K["${class_name}"]}"

      if [ -z "${K_value}" ]; then
        continue
      fi

      last_calculated_K_symbols+=("${symbol}")
    done

    if [[ -z "${K_cell_value}" ]]; then
      echo "Calculation for K cell value failed!" >&2
      return 1
    fi

    # ----------------------------------------
    # Print Smin
    # ----------------------------------------
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
    echo -n "u0min = ..."

    # TODO: Calculate result table
    # ...

    # TODO: Insert K columns in first table
    # ...
  fi

  echo "================================================================================"
  echo ""

  echo "Parsing file \"${filePath}\": done!" >&2
  return "${was_error}"
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
