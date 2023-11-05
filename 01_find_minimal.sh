#!/bin/bash

# (REUSE) Special function to get current script file hash
function get_text_hash() {
  echo "${*}" | sha256sum | cut -d ' ' -f 1 || return "$?"
  return 0
}

# (REUSE) Source this file only if wasn't sourced already
{
  current_file_path="$(realpath "${BASH_SOURCE[0]}")" || exit "$?"
  current_file_hash="$(echo "${current_file_path}" | sha256sum | cut -d ' ' -f 1)" || exit "$?"
  current_file_is_sourced_variable_name="FILE_IS_SOURCED_${current_file_hash^^}"
  current_file_is_sourced="$(eval "echo \"\${${current_file_is_sourced_variable_name}}\"")" || exit "$?"
  if [ -n "${current_file_is_sourced}" ]; then
    return
  fi
  eval "export ${current_file_is_sourced_variable_name}=1" || exit "$?"
  if [ "${IS_DEBUG_BASH}" == "1" ]; then
    if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
      echo "Executing \"${current_file_path}\"..." >&2
    else
      echo "Sourcing \"${current_file_path}\"..." >&2
    fi
  fi
}

# (REUSE) Prepare before imports
{
  # Because variables is the same when sourcing, we depend on file hash.
  # Also, we don't use variable for variable name here, because it will fall in the same problem.
  # We must pass "${BASH_SOURCE[*]}" as variable and not define it in function itself, because Bash will replace it there.
  eval "source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")=\"${PWD}\"" || exit "$?"

  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit "$?"
}

# Imports
source "./scripts/package/install_command.sh" || exit "$?"
source "./scripts/messages.sh" || exit "$?"
source "./scripts/xpath/load_xml.sh" || exit "$?"
source "./scripts/xpath/get_nodes_count.sh" || exit "$?"
source "./scripts/xpath/get_node_attribute_value.sh" || exit "$?"
source "./scripts/xpath/get_node_with_attribute_value.sh" || exit "$?"
source "./scripts/xpath/fill_lambda_and_delta_and_variables_names.sh" || exit "$?"
source "./scripts/01_find_minimal/class_family_calculate.sh" || exit "$?"
source "./scripts/01_find_minimal/class_family_print.sh" || exit "$?"
source "./scripts/01_find_minimal/print_calculations_result.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

export ARRAY_INDEX_SEPARATOR="___"

export CALCULATE_K_ITERATION_LIMIT=50

# Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
export CELLS
declare -A CELLS=()

export LAST_CLASS_FAMILY_SYMBOLS
declare -a LAST_CLASS_FAMILY_SYMBOLS=()

# Start main script of Automata Parser
function automata_parser() {
  print_info "Welcome to ${C_HIGHLIGHT}Automata Parser${C_RETURN}!"

  local file_path="${1}" && shift
  if [ -z "${file_path}" ]; then
    print_error "You need to specify file path!"
    return 1
  fi

  install_command "xpath" "libxml-xpath-perl" || return "$?"

  load_xml "${file_path}" || return "$?"

  print_info "Parsing..."

  fill_lambda_and_delta_and_variables_names || return "$?"

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
      lines_to_find_family_class["1"]+=" ${current_lambda:-"${TABLE_EMPTY_CELL_VALUE}"}"
    done

    # Make sure to not add extra line because we count them in class_family_calculate function
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      lines_to_find_family_class["1"]+="
"
    fi
  done
  # ----------------------------------------

  # ----------------------------------------
  # Calculate K
  # ----------------------------------------
  # Initialization values must be different here
  local class_family_previous="0"
  local class_family_current="1"
  local class_family_id=0
  local class_families_count=0
  export LAST_CALCULATED_CLASS_FAMILY_ID=0

  while [[ ${class_family_current} != "${class_family_previous}" ]] && ((class_family_id < CALCULATE_K_ITERATION_LIMIT)); do
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
            local class_members_as_string="${CLASS_FAMILIES["${class_name}"]}"

            if [ -z "${class_members_as_string}" ]; then
              continue
            fi

            # Add extra spaces to match first and last numbers in class_members_as_string
            if [[ " ${class_members_as_string} " == *" ${current_delta} "* ]]; then
              class_family_linked_cell_value="${class_name}"
              break
            fi
          done

          if [[ -z ${class_family_linked_cell_value} ]]; then
            print_error "Calculation for ${CLASS_FAMILY_SYMBOL} cell value failed! class_name = \"${class_name}\""
            return 1
          fi

          CELLS["${CLASS_FAMILY_SYMBOL}${class_family_id_previous}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${class_family_linked_cell_value}"

          lines_to_find_family_class["${class_family_id}"]+=" ${class_family_linked_cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}"
        done

        # Make sure to not add extra line because we count them in class_family_calculate function
        if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
          lines_to_find_family_class["${class_family_id}"]+="
"
        fi
      done
    fi

    class_family_calculate "${ELLIPSES_VALUES_AS_STRING}" "${lines_to_find_family_class["${class_family_id}"]}" "${class_family_id}" || return "$?"
    LAST_CALCULATED_CLASS_FAMILY_ID="$((class_families_count))"
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
  # Calculate ellipses values of input automate
  # ----------------------------------------
  export INPUT_AUTOMATE_ELLIPSES_VALUES="${ELLIPSES_VALUES_AS_STRING//"
"/", "}"
  # ----------------------------------------

  # ----------------------------------------
  # Calculate start ellipse of input automate
  # ----------------------------------------
  export INPUT_AUTOMATE_START_ELLIPSE_VALUE
  INPUT_AUTOMATE_START_ELLIPSE_VALUE="$(get_node_attribute_value "${START_ARROW_TARGET}" "mxCell" "${ATTRIBUTE_VALUE}")" || return "$?"
  # ----------------------------------------

  # ----------------------------------------
  # Calculate ellipses values of result automate
  # ----------------------------------------
  if ((!was_error)); then
    local symbol_id
    for ((symbol_id = 0; symbol_id < CLASS_SYMBOLS_COUNT; symbol_id++)); do
      local ellipse_value="${CLASS_SYMBOLS["${symbol_id}"]}"
      local class_name="${ellipse_value}${LAST_CALCULATED_CLASS_FAMILY_ID}"
      local class_members_as_string="${CLASS_FAMILIES["${class_name}"]}"

      if [ -z "${class_members_as_string}" ]; then
        break
      fi

      LAST_CLASS_FAMILY_SYMBOLS+=("${ellipse_value}")
    done
  fi

  export LAST_CLASS_FAMILY_SYMBOLS_COUNT="${#LAST_CLASS_FAMILY_SYMBOLS[@]}"

  export OUTPUT_AUTOMATE_ELLIPSES_VALUES="?"

  if ((!was_error)); then
    OUTPUT_AUTOMATE_ELLIPSES_VALUES="${LAST_CLASS_FAMILY_SYMBOLS[*]}"
    OUTPUT_AUTOMATE_ELLIPSES_VALUES="${OUTPUT_AUTOMATE_ELLIPSES_VALUES//" "/", "}"
  fi
  # ----------------------------------------

  # ----------------------------------------
  # Calculate start ellipse of result automate
  # ----------------------------------------
  export OUTPUT_AUTOMATE_START_ELLIPSE_VALUE="?"

  if ((!was_error)); then
    local symbol_id
    for ((symbol_id = 0; symbol_id < LAST_CLASS_FAMILY_SYMBOLS_COUNT; symbol_id++)); do
      local ellipse_value="${LAST_CLASS_FAMILY_SYMBOLS["${symbol_id}"]}"
      local class_name="${ellipse_value}${LAST_CALCULATED_CLASS_FAMILY_ID}"
      local class_members_as_string="${CLASS_FAMILIES["${class_name}"]}"

      # Add extra spaces to match first and last numbers in class_members_as_string
      if [[ " ${class_members_as_string} " == *" ${INPUT_AUTOMATE_START_ELLIPSE_VALUE} "* ]]; then
        OUTPUT_AUTOMATE_START_ELLIPSE_VALUE="${ellipse_value}"
        break
      fi
    done
  fi
  # ----------------------------------------

  # ----------------------------------------
  # Calculate result automate
  # ----------------------------------------
  local symbol_id
  for ((symbol_id = 0; symbol_id < LAST_CLASS_FAMILY_SYMBOLS_COUNT; symbol_id++)); do
    local ellipse_value="${LAST_CLASS_FAMILY_SYMBOLS["${symbol_id}"]}"
    local class_name="${ellipse_value}${LAST_CALCULATED_CLASS_FAMILY_ID}"
    local class_members_as_string="${CLASS_FAMILIES["${class_name}"]}"

    # shellcheck disable=SC2206
    declare -a class_members=(${class_members_as_string})

    local any_member="${class_members["0"]}"

    # lambda
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"

      CELLS["${LAMBDA_MIN}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${any_member}"]}"
    done

    # delta
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"

      local delta_value="${CELLS["${CLASS_FAMILY_SYMBOL}$((LAST_CALCULATED_CLASS_FAMILY_ID - 1))${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${any_member}"]}"
      # Remove index
      delta_value="${delta_value//"$((LAST_CALCULATED_CLASS_FAMILY_ID - 1))"/""}"

      CELLS["${DELTA_MIN}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${delta_value}"
    done
  done
  # ----------------------------------------

  print_calculations_result "${was_error}" || return "$?"

  if ((was_error)); then
    print_error "Parsing: failed!"
  else
    print_success "Parsing: done!"
  fi

  return "${was_error}"
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    automata_parser "$@" || exit "$?"
  fi
}
