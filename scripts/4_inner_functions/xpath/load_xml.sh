#!/bin/bash

if [ -n "${IS_FILE_SOURCED_LOAD_XML}" ]; then
  return
fi

function load_xml() {
  # ========================================
  # 1. Imports
  # ========================================

  cd "$(dirname "${BASH_SOURCE[0]}")" || return "$?"
  source "./../../2_external_functions/messages.sh" || return "$?"
  source "./../../3_inner_constants/xpath/attributes.sh" || return "$?"
  source "./get_node_attribute_value.sh" || return "$?"
  source "./get_node_with_attribute_value.sh" || return "$?"
  cd - >/dev/null || return "$?"

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

  print_info "Loading file \"${file_path}\"..."

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
  export XML_ELLIPSES
  XML_ELLIPSES="$(echo "<xml>${xml_elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"ellipse;\")
    ]
  ")" || return "$?"
  export ellipses_count
  ellipses_count="$(get_nodes_count "${XML_ELLIPSES}")" || return "$?"

  if ((ellipses_count < 1)); then
    print_error "No ellipses found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${ellipses_count}${C_RETURN} ellipses!"
  # ----------------------------------------

  # ----------------------------------------
  # Arrows
  # ----------------------------------------
  local arrows_xml
  arrows_xml="$(echo "<xml>${xml_elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"edgeStyle\")
    ]
  ")" || return "$?"
  local arrows_count
  arrows_count="$(get_nodes_count "${arrows_xml}")" || return "$?"

  if ((arrows_count < 1)); then
    print_error "No arrows found!"
    return 1
  fi
  print_success "Found ${C_HIGHLIGHT}${arrows_count}${C_RETURN} arrows!"
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

  local start_arrow_xml="${start_arrows_count}"
  print_success "Start arrow found!"

  # Find first ellipsis id
  local start_arrow_target_id
  start_arrow_target_id="$(get_node_attribute_value "${start_arrow_xml}" "${ATTRIBUTE_TARGET}")" || return "$?"
  if [ -z "${start_arrow_target_id}" ]; then
    print_error "Start arrow ID is empty!"
    return 1
  fi

  # Find first ellipsis node
  local start_arrow_target
  start_arrow_target="$(get_node_with_attribute_value "${XML_ELLIPSES}" "${ATTRIBUTE_ID}" "${start_arrow_target_id}")" || return "$?"

  # Find first ellipsis value
  export START_ARROW_TARGET_VALUE
  START_ARROW_TARGET_VALUE="$(get_node_attribute_value "${start_arrow_target}" "${ATTRIBUTE_VALUE}")" || return "$?"
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
  export CONNECTED_ARROWS_XML
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
  print_success "Found ${connected_arrows_count} connected arrows!"
  # ----------------------------------------

  print_success "Loading file \"${file_path}\": done!"
  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  load_xml "$@" || exit "$?"
fi

export IS_FILE_SOURCED_LOAD_XML=1
