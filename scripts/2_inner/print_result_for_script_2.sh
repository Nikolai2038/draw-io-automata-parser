#!/bin/bash

# ========================================
# Source this file only if wasn't sourced already
# ========================================
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
# ========================================

export EMPTY_SPACE_SYMBOL="∅"

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

    local value="${CAN_GO_TO_ELLIPSE_FOR_VALUE["${ARRAY_INDEX_SEPARATOR}${ellipse_name_in_list}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}"]}"

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
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  # source "./scripts/..." || return "$?"
  # source "./scripts/..." || return "$?"
  # source "./scripts/..." || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local was_error="${1:-0}" && shift

  # ========================================
  # 3. Main code
  # ========================================

  declare -a combinations=("${START_ARROW_TARGET_VALUE}")
  local combinations_count="${#combinations[@]}"

  local variable_name_id_in_list
  for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
    local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
    if [ "${variable_name_in_list}" == "${SINGLE_ARROW_REPLACEMENT}" ]; then
      variable_name_in_list="${SINGLE_ARROW}"
    fi

    echo -en "\t${variable_name_in_list}"
  done
  echo ""

  local combination_id
  for ((combination_id = 0; combination_id < combinations_count; combination_id++)); do
    local combination_as_string="${combinations["${combination_id}"]}"
    declare -a combination
    IFS=" " read -r -a combination <<< "${combination_as_string}"

    local combination_as_string_with_braces
    combination_as_string_with_braces="{$(print_with_delimiter "," "${combination_as_string:-"${EMPTY_SPACE_SYMBOL}"}")}" || return "$?"

    echo -en "${combination_as_string_with_braces}"
    local variable_name_id_in_list
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"

      local next_ellipses_for_variable_name_as_string
      next_ellipses_for_variable_name_as_string="$(find_next_ellipses_for_variable_name "${variable_name_in_list}" "${combination[@]}")" || return "$?"

      local next_ellipses_for_variable_name_as_string2
      next_ellipses_for_variable_name_as_string2="{$(print_with_delimiter "," "${next_ellipses_for_variable_name_as_string:-"${EMPTY_SPACE_SYMBOL}"}")}" || return "$?"

      echo -en "\t${next_ellipses_for_variable_name_as_string2}"

      local was_already=0
      local combination_id2
      for ((combination_id2 = 0; combination_id2 < combinations_count; combination_id2++)); do
        local combination_as_string2="${combinations["${combination_id2}"]}"
        if [ "${combination_as_string2}" == "${next_ellipses_for_variable_name_as_string}" ]; then
          was_already=1
          break
        fi
      done

      if ((!was_already)); then
        combinations+=("${next_ellipses_for_variable_name_as_string}")
        combinations_count="${#combinations[@]}"
      fi
    done
    echo ""
  done

  return 0
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  print_result_for_script_2 "$@" || exit "$?"
fi
# ========================================
