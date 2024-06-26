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
  eval "source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")=\"${PWD}\"" || exit "$?"

  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit "$?"
}

# Imports
source "./_constants.sh" || exit "$?"
source "../table/table_print.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function print_with_delimiter() {
  local delimiter="${1}" && shift

  local IFS="${delimiter}"
  echo "${*}"

  return 0
}

# First argument is variable name.
# Then pass ellipses names.
function find_next_ellipses_for_variable_name() {
  local variable_name_in_list="${1}" && shift

  local result=""

  local is_first=1
  while [ "$#" -gt 0 ]; do
    local ellipse_name_in_list="${1}" && shift

    local value
    value="$(array_get "${ARRAY_CAN_GO_TO_ELLIPSE_FOR_VALUE}" "${ellipse_name_in_list}" "${variable_name_in_list}")" || return "$?"

    # Skip values with no arrows
    if [ -z "${value}" ]; then
      continue
    fi

    declare -a next_ellipses_array
    IFS=" " read -r -a next_ellipses_array <<< "${value}"

    # Sort values
    local next_ellipses_array_sorted
    next_ellipses_array_sorted="$(echo "${next_ellipses_array[@]}" | tr ' ' '\n' | sort --unique --numeric-sort)" || return "$?"
    mapfile -t next_ellipses_array <<< "${next_ellipses_array_sorted}" || return "$?"

    if ((!is_first)); then
      result+=" "
    fi
    result+="${next_ellipses_array[*]}"
    is_first=0
  done

  # Sort values
  local result_sorted
  result_sorted="$(echo "${result}" | tr ' ' '\n' | sort --unique --numeric-sort)" || return "$?"
  mapfile -t result <<< "${result_sorted}" || return "$?"

  echo "${result[@]}"

  return 0
}

function print_result_for_script_2() {
  local was_error="${1:-0}" && shift

  # Set column name for exit automata function
  table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_1}" "0" "$((VARIABLES_NAME_COUNT + 1))" "${IS_COMBINATION_CONTAINS_LAST_ELLIPSE_COLUMN_NAME}" || return "$?"
  table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_2}" "0" "$((VARIABLES_NAME_COUNT + 1))" "${IS_COMBINATION_CONTAINS_LAST_ELLIPSE_COLUMN_NAME}" || return "$?"

  declare -a combinations=("${START_ARROW_TARGET_VALUE}")
  local combinations_count="${#combinations[@]}"

  local combination_id
  for ((combination_id = 0; combination_id < combinations_count; combination_id++)); do
    local combination_as_string="${combinations["${combination_id}"]}"
    declare -a combination
    IFS=" " read -r -a combination <<< "${combination_as_string}"

    local is_combination_contains_last_ellipse=0
    local ellipse_value_to_check
    for ellipse_value_to_check in "${combination[@]}"; do
      if [ "${ellipse_value_to_check}" == "${LAST_ELLIPSE_VALUE}" ]; then
        is_combination_contains_last_ellipse=1
        break
      fi
    done

    table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_1}" "$((combination_id + 1))" "$((VARIABLES_NAME_COUNT + 1))" "${is_combination_contains_last_ellipse}" || return "$?"
    table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_2}" "$((combination_id + 1))" "$((VARIABLES_NAME_COUNT + 1))" "${is_combination_contains_last_ellipse}" || return "$?"

    local combination_as_string_with_braces
    combination_as_string_with_braces="{$(print_with_delimiter "," "${combination_as_string:-"${EMPTY_SPACE_SYMBOL}"}")}" || return "$?"

    table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_1}" "$((combination_id + 1))" "0" "${combination_as_string_with_braces}" || return "$?"
    table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_2}" "$((combination_id + 1))" "0" "$((combination_id + 1))" || return "$?"

    local variable_name_id_in_list
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"

      local next_ellipses_for_variable_name_as_string
      next_ellipses_for_variable_name_as_string="$(find_next_ellipses_for_variable_name "${variable_name_in_list}" "${combination[@]}")" || return "$?"

      local next_ellipses_for_variable_name_as_string2
      next_ellipses_for_variable_name_as_string2="{$(print_with_delimiter "," "${next_ellipses_for_variable_name_as_string:-"${EMPTY_SPACE_SYMBOL}"}")}" || return "$?"

      local was_already=0
      local combination_id2
      for ((combination_id2 = 0; combination_id2 < combinations_count; combination_id2++)); do
        local combination_as_string2="${combinations["${combination_id2}"]}"
        if [ "${combination_as_string2}" == "${next_ellipses_for_variable_name_as_string}" ]; then
          was_already=1
          break
        fi
      done

      table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_1}" "$((combination_id + 1))" "$((variable_name_id_in_list + 1))" "${next_ellipses_for_variable_name_as_string2}" || return "$?"

      if ([ -n "${next_ellipses_for_variable_name_as_string}" ] || ((IS_PRINT_EMPTY_COMBINATION))); then
        table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_2}" "$((combination_id + 1))" "$((variable_name_id_in_list + 1))" "$((combination_id2 + 1))" || return "$?"
        if ((!was_already)); then
          combinations+=("${next_ellipses_for_variable_name_as_string}")
          combinations_count="${#combinations[@]}"
        fi
      else
        table_set_cell_value "${TABLE_NAME_FOR_SCRIPT_02_2}" "$((combination_id + 1))" "$((variable_name_id_in_list + 1))" "-" || return "$?"
      fi
    done
  done

  table_print "${TABLE_NAME_FOR_SCRIPT_02_1}" || return "$?"
  print_success "" || return "$?"
  table_print "${TABLE_NAME_FOR_SCRIPT_02_2}" || return "$?"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    print_result_for_script_2 "$@" || exit "$?"
  fi
}
