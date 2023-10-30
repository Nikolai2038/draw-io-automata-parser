#!/bin/bash

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
  source_previous_directory="${PWD}"
  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || return "$?"
}

# Imports
source "../../1_portable/messages.sh"

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || return "$?"
}

export VARIABLES_NAMES
declare -a VARIABLES_NAMES=()

export VARIABLES_NAME_COUNT=0

function fill_lamda_and_delta_and_variables_names() {
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
        print_error "Value is empty for arrow from ellipse with value \"${ellipse_value}\"! You must add text to arrow in format \"<variable name>/<variable value>\"" || return "$?"
        return 1
      fi

      print_info "- Calculate data for arrow with value ${C_HIGHLIGHT}${arrow_value}${C_RETURN}!"

      local arrow_target_id="${arrow_targets_ids["${arrow_id_in_list}"]}"
      local arrow_target_node
      arrow_target_node="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${arrow_target_id}")" || return "$?"
      local arrow_target_value
      arrow_target_value="$(get_node_attribute_value "${arrow_target_node}" "${ATTRIBUTE_VALUE}")" || return "$?"

      local arrow_variable_regexpr='([^\/]+)\/([^\/]+)'

      local arrow_variable_name
      arrow_variable_name="$(echo "${arrow_value}" | sed -En "s/${arrow_variable_regexpr}/\1/p")" || return "$?"

      local arrow_variable_value
      arrow_variable_value="$(echo "${arrow_value}" | sed -En "s/${arrow_variable_regexpr}/\2/p")" || return "$?"

      if [ -z "${arrow_variable_name}" ] || [ -z "${arrow_variable_value}" ]; then
        print_error "Failed to get variable name and value from arrow with value \"${arrow_value}\" from ellipse with value \"${ellipse_value}\"! You must add text to arrow in format \"<variable name>/<variable value>\"" || return "$?"
        return 1
      fi

      # Collecting all variables names into "variables_names" array
      VARIABLES_NAMES+=("${arrow_variable_name}")

      local cell_value="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      if [ -n "${cell_value}" ]; then
        print_error "From ellipse with value \"${ellipse_value}\" there are more than one arrows with variable name \"${arrow_variable_name}\"!" || return "$?"
        return 1
      fi

      CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_variable_value}"
      CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${arrow_variable_name}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]="${arrow_target_value}"
    done
  done

  # Sort variables names
  local variables_names_string_sorted
  variables_names_string_sorted="$(echo "${VARIABLES_NAMES[@]}" | tr ' ' '\n' | sort --unique)" || return "$?"
  mapfile -t VARIABLES_NAMES <<< "${variables_names_string_sorted}" || return "$?"

  VARIABLES_NAME_COUNT="${#VARIABLES_NAMES[@]}"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    fill_lamda_and_delta_and_variables_names "$@" || exit "$?"
  fi
}
