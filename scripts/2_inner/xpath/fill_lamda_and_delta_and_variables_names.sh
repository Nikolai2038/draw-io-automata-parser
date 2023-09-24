#!/bin/bash

if [ -n "${IS_FILE_SOURCED_FILL_LAMDA_AND_DELTA_AND_VARIABLES_NAMES}" ]; then
  return
fi

export VARIABLES_NAMES
declare -a VARIABLES_NAMES=()

export VARIABLES_NAME_COUNT=0

function fill_lamda_and_delta_and_variables_names() {
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

  # None

  # ========================================
  # 3. Main code
  # ========================================

  local ellipse_id_in_list
  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    local ellipse_id="${ELLIPSES_IDS["${ellipse_id_in_list}"]}"
    local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"
    print_info "Calculate data for ellipse with value ${C_HIGHLIGHT}${ellipse_value}${C_RETURN}!"

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

    local arrow_targets_string
    arrow_targets_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_TARGET}")"
    declare -a arrow_targets
    mapfile -t arrow_targets <<<"${arrow_targets_string}" || return "$?"

    local arrow_id_in_list
    for ((arrow_id_in_list = 0; arrow_id_in_list < arrows_from_ellipse_count; arrow_id_in_list++)); do
      local arrow_value="${arrow_values["${arrow_id_in_list}"]}"

      print_info "- Calculate data for arrow with value ${C_HIGHLIGHT}${arrow_value}${C_RETURN}!"

      local arrow_target_id="${arrow_targets["${arrow_id_in_list}"]}"
      local arrow_target_node
      arrow_target_node="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${arrow_target_id}")" || return "$?"
      local arrow_target_value
      arrow_target_value="$(get_node_attribute_value "${arrow_target_node}" "${ATTRIBUTE_VALUE}")" || return "$?"

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
      VARIABLES_NAMES+=("${arrow_variable_name}")

      local cell_value="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      if [ -n "${cell_value}" ]; then
        print_error "From ellipse with value \"${ellipse_value}\" there are more than one arrows with variable name \"${arrow_variable_name}\"!"
        return 1
      fi

      CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_variable_value}"
      CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_target_value}"
    done
  done

  # Sort variables names
  local variables_names_string_sorted
  variables_names_string_sorted="$(echo "${VARIABLES_NAMES[@]}" | tr ' ' '\n' | sort --unique)" || return "$?"
  mapfile -t VARIABLES_NAMES <<<"${variables_names_string_sorted}" || return "$?"

  VARIABLES_NAME_COUNT="${#VARIABLES_NAMES[@]}"

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  fill_lamda_and_delta_and_variables_names "$@" || exit "$?"
fi

export IS_FILE_SOURCED_FILL_LAMDA_AND_DELTA_AND_VARIABLES_NAMES=1
