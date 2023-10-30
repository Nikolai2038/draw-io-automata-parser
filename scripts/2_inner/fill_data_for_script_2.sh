#!/bin/bash

# ========================================
# Source this file only if wasn't sourced already
# ========================================
CURRENT_FILE_HASH="$(realpath "${BASH_SOURCE[0]}" | sha256sum | cut -d ' ' -f 1)" || exit "$?"
if [ -n "${SOURCED_FILES["hash_${CURRENT_FILE_HASH}"]}" ]; then
  return
fi
SOURCED_FILES["hash_${CURRENT_FILE_HASH}"]=1
# ========================================

export VARIABLES_NAMES
declare -a VARIABLES_NAMES=()
export VARIABLES_NAME_COUNT=0

export ELLIPSES_NAMES
declare -a ELLIPSES_NAMES=()
export ELLIPSES_NAME_COUNT=0

export SINGLE_ARROW="ε"
export SINGLE_ARROW_REPLACEMENT="EEEEE"

export CAN_GO_TO_ELLIPSE_FOR_VALUE
declare -A CAN_GO_TO_ELLIPSE_FOR_VALUE=()

function fill_data_for_script_2() {
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

    local arrows_from_ellipse
    arrows_from_ellipse="$(get_node_with_attribute_value "${CONNECTED_ARROWS_XML}" "${ATTRIBUTE_SOURCE}" "${ellipse_id}")" || return "$?"
    local arrows_from_ellipse_count
    arrows_from_ellipse_count="$(get_nodes_count "${arrows_from_ellipse}")" || return "$?"
    if ((arrows_from_ellipse_count < 1)); then
      continue
    fi

    local arrow_ids_as_string
    arrow_ids_as_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_ID}")" || return "$?"
    if [ -z "${arrow_ids_as_string}" ]; then
      print_error "Arrow ids as string is empty!" || return "$?"
      return 1
    fi
    declare -a arrow_ids
    mapfile -t arrow_ids <<< "${arrow_ids_as_string}" || return "$?"

    # Arrows values can be specified in arrow itself, or in separate label.
    # We check first arrow value, and if it is empty, we seek for its label.
    local arrow_values_as_string
    arrow_values_as_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_VALUE}")"
    declare -a arrow_values
    mapfile -t arrow_values <<< "${arrow_values_as_string}" || return "$?"

    local arrow_targets_ids_string
    arrow_targets_ids_string="$(get_node_attribute_value "${arrows_from_ellipse}" "${ATTRIBUTE_TARGET}")"
    declare -a arrow_targets_ids
    mapfile -t arrow_targets_ids <<< "${arrow_targets_ids_string}" || return "$?"

    local arrow_id_in_list
    for ((arrow_id_in_list = 0; arrow_id_in_list < arrows_from_ellipse_count; arrow_id_in_list++)); do
      local arrow_value="${arrow_values["${arrow_id_in_list}"]}"

      # If arrow value is empty, we seek for its label.
      if [ -z "${arrow_value}" ]; then
        local arrow_id="${arrow_ids["${arrow_id_in_list}"]}"

        local arrow_label_xml
        arrow_label_xml="$(get_node_with_attribute_value "${arrows_labels_xml}" "${ATTRIBUTE_PARENT}" "${arrow_id}")" || return "$?"

        local arrow_value
        arrow_value="$(get_node_attribute_value "${arrow_label_xml}" "${ATTRIBUTE_VALUE}")" || return "$?"
      fi

      if [ -z "${arrow_value}" ]; then
        print_error "Value is empty for arrow from ellipse with value \"${ellipse_value}\"! You must add text to arrow in format \"<variable name>\"" || return "$?"
        return 1
      fi

      if [ "${arrow_value}" == "${SINGLE_ARROW}" ]; then
        arrow_value="${SINGLE_ARROW_REPLACEMENT}"
      fi

      local arrow_target_id="${arrow_targets_ids["${arrow_id_in_list}"]}"
      local arrow_target_node
      arrow_target_node="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${arrow_target_id}")" || return "$?"
      local arrow_target_value
      arrow_target_value="$(get_node_attribute_value "${arrow_target_node}" "${ATTRIBUTE_VALUE}")" || return "$?"

      # Add new next ellipse available
      local current_value="${CAN_GO_TO_ELLIPSE_FOR_VALUE["${ARRAY_INDEX_SEPARATOR}${ellipse_value}${ARRAY_INDEX_SEPARATOR}${arrow_value}"]}"
      if [ -n "${current_value}" ]; then
        current_value+=" "
      fi
      current_value+="${arrow_target_value}"
      CAN_GO_TO_ELLIPSE_FOR_VALUE["${ARRAY_INDEX_SEPARATOR}${ellipse_value}${ARRAY_INDEX_SEPARATOR}${arrow_value}"]="${current_value}"

      # Collecting all variables names into "variables_names" array
      VARIABLES_NAMES+=("${arrow_value}")
    done
  done

  # Sort variables names
  local variables_names_string_sorted
  variables_names_string_sorted="$(echo "${VARIABLES_NAMES[@]}" | tr ' ' '\n' | sort --unique)" || return "$?"
  mapfile -t VARIABLES_NAMES <<< "${variables_names_string_sorted}" || return "$?"
  VARIABLES_NAME_COUNT="${#VARIABLES_NAMES[@]}"

  return 0
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  fill_data_for_script_2 "$@" || exit "$?"
fi
# ========================================
