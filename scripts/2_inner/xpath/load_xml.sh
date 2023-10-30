#!/bin/bash

# Source this file only if wasn't sourced already
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

export ATTRIBUTE_ID="id"
export ATTRIBUTE_TARGET="target"
export ATTRIBUTE_SOURCE="source"
export ATTRIBUTE_VALUE="value"
export ATTRIBUTE_PARENT="parent"

export XML_ELLIPSES
export ELLIPSES_COUNT
export CONNECTED_ARROWS_XML

export ELLIPSES_VALUES_AS_STRING

export ELLIPSES_IDS
declare -a ELLIPSES_IDS

export ELLIPSES_VALUES
declare -a ELLIPSES_VALUES

function load_xml() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "./../../1_portable/messages.sh" || return "$?"
  source "./get_node_attribute_value.sh" || return "$?"
  source "./get_node_with_attribute_value.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local file_path="${1}" && shift
  if [ -z "${file_path}" ]; then
    print_error "You need to specify file path!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  print_info "Loading file ${C_HIGHLIGHT}${file_path}${C_RETURN}..."

  local file_content
  file_content="$(cat "${file_path}")" || return "$?"

  # ----------------------------------------
  # Elements
  # ----------------------------------------
  local xml_elements
  xml_elements="$(echo "${file_content}" | xpath -q -e "
    //mxCell
  ")" || return "$?"
  local elements_count
  elements_count="$(get_nodes_count "${xml_elements}")" || return "$?"

  if ((elements_count < 1)); then
    print_error "No elements found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${elements_count}${C_RETURN} elements!"
  # ----------------------------------------

  # ----------------------------------------
  # Ellipses
  # ----------------------------------------
  XML_ELLIPSES="$(echo "<xml>${xml_elements}</xml>" | xpath -q -e '
    //mxCell[
      starts-with(@style, "ellipse;")
    ]
  ')" || return "$?"
  ELLIPSES_COUNT="$(get_nodes_count "${XML_ELLIPSES}")" || return "$?"

  if ((ELLIPSES_COUNT < 1)); then
    print_error "No ellipses found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${ELLIPSES_COUNT}${C_RETURN} ellipses!"
  # ----------------------------------------

  # ----------------------------------------
  # Arrows
  # ----------------------------------------
  local arrows_xml
  arrows_xml="$(echo "<xml>${xml_elements}</xml>" | xpath -q -e '
    //mxCell[
      starts-with(@style, "edgeStyle")
    ]
  ')" || return "$?"
  local arrows_count
  arrows_count="$(get_nodes_count "${arrows_xml}")" || return "$?"

  if ((arrows_count < 1)); then
    print_error "No arrows found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${arrows_count}${C_RETURN} arrows!"
  # ----------------------------------------

  # ----------------------------------------
  # Arrows labels
  # ----------------------------------------
  export arrows_labels_xml
  arrows_labels_xml="$(echo "<xml>${xml_elements}</xml>" | xpath -q -e '
    //mxCell[
      starts-with(@style, "edgeLabel")
    ]
  ')" || return "$?"
  local arrows_labels_count
  arrows_labels_count="$(get_nodes_count "${arrows_labels_xml}")" || return "$?"
  print_success "Found ${C_HIGHLIGHT}${arrows_labels_count}${C_RETURN} label arrows!"
  # ----------------------------------------

  # ----------------------------------------
  # Start arrow
  # ----------------------------------------
  local start_arrows_xml
  start_arrows_xml="$(echo "<xml>${arrows_xml}</xml>" | xpath -q -e "
    //mxCell[
      not(@source)
      and
      @target
    ]
  ")" || return "$?"
  local start_arrows_count
  start_arrows_count="$(get_nodes_count "${start_arrows_xml}")" || return "$?"

  if ((start_arrows_count < 1)); then
    print_error "No start arrow found! You need to create arrow with no source but connect it to some ellipse."
    return 1
  elif ((start_arrows_count > 1)); then
    print_error "Only one start arrow is allowed! Found: ${start_arrows_count}. IDs:"
    get_node_attribute_value "${start_arrows_xml}" "${ATTRIBUTE_ID}"
    return 1
  fi

  local start_arrow_xml="${start_arrows_xml}"
  print_success "Start arrow found!"

  # Find first ellipsis id
  local start_arrow_target_id
  start_arrow_target_id="$(get_node_attribute_value "${start_arrow_xml}" "${ATTRIBUTE_TARGET}")" || return "$?"
  if [ -z "${start_arrow_target_id}" ]; then
    print_error "Start arrow ID is empty!"
    return 1
  fi

  # Find first ellipsis node
  export START_ARROW_TARGET
  START_ARROW_TARGET="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${start_arrow_target_id}")" || return "$?"

  export START_ARROW_TARGET_VALUE
  START_ARROW_TARGET_VALUE="$(get_node_attribute_value "${START_ARROW_TARGET}" "${ATTRIBUTE_VALUE}")" || return "$?"
  # ----------------------------------------

  # ----------------------------------------
  # Disconnected arrows
  # ----------------------------------------
  local disconnected_arrows_xml
  disconnected_arrows_xml="$(echo "<xml>${arrows_xml}</xml>" | xpath -q -e "
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

  if [ -n "${disconnected_arrows_xml}" ]; then
    local disconnected_arrows_count
    disconnected_arrows_count="$(get_nodes_count "${disconnected_arrows_xml}")" || return "$?"
    if ((disconnected_arrows_count > 0)); then
      print_error "Found ${disconnected_arrows_count} disconnected arrows! IDs:"
      get_node_attribute_value "${disconnected_arrows_xml}" "${ATTRIBUTE_ID}"
      return 1
    fi
  fi
  print_success "No disconnected arrows found!"
  # ----------------------------------------

  # ----------------------------------------
  # Connected arrows
  # ----------------------------------------
  CONNECTED_ARROWS_XML="$(echo "<xml>${arrows_xml}</xml>" | xpath -q -e "
    //mxCell[
      @source
      and
      @target
    ]
  ")" || return "$?"
  local connected_arrows_count
  connected_arrows_count="$(get_nodes_count "${CONNECTED_ARROWS_XML}")" || return "$?"

  if ((connected_arrows_count < 1)); then
    print_error "No connected arrows found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${connected_arrows_count}${C_RETURN} connected arrows!"
  # ----------------------------------------

  # ----------------------------------------
  # Ellipses attributes
  # ----------------------------------------
  local ellipses_ids_as_string
  ellipses_ids_as_string="$(get_node_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}")" || return "$?"
  if [ -z "${ellipses_ids_as_string}" ]; then
    print_error "Ellipses ids as string is empty!"
    return 1
  fi
  mapfile -t ELLIPSES_IDS <<< "${ellipses_ids_as_string}" || return "$?"

  ELLIPSES_VALUES_AS_STRING="$(get_node_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_VALUE}")" || return "$?"
  if [ -z "${ELLIPSES_VALUES_AS_STRING}" ]; then
    print_error "Ellipses values as string is empty!"
    return 1
  fi
  mapfile -t ELLIPSES_VALUES <<< "${ELLIPSES_VALUES_AS_STRING}" || return "$?"
  # ----------------------------------------

  # ----------------------------------------
  # Sort ellipses attributes based on ellipses values
  # ----------------------------------------
  local ellipses_attributes_as_string
  local ellipse_id_in_list
  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    # Values goes first because we will sort based on them
    ellipses_attributes_as_string+="${ELLIPSES_VALUES["${ellipse_id_in_list}"]} ${ELLIPSES_IDS["${ellipse_id_in_list}"]}"

    # Make sure last line is not line break because `sort` later will move it to the top
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      ellipses_attributes_as_string+="\n"
    fi
  done

  ellipses_attributes_as_string="$(echo -e "${ellipses_attributes_as_string}" | sort --unique)" || return "$?"

  ellipses_ids_as_string="$(echo "${ellipses_attributes_as_string}" | cut -d ' ' -f 2)" || return "$?"
  ELLIPSES_VALUES_AS_STRING="$(echo "${ellipses_attributes_as_string}" | cut -d ' ' -f 1)" || return "$?"

  mapfile -t ELLIPSES_IDS <<< "${ellipses_ids_as_string}" || return "$?"
  mapfile -t ELLIPSES_VALUES <<< "${ELLIPSES_VALUES_AS_STRING}" || return "$?"
  # ----------------------------------------

  print_success "Loading file ${C_HIGHLIGHT}${file_path}${C_RETURN}: done!"
  return 0
}

# Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    load_xml "$@" || exit "$?"
  fi
}
