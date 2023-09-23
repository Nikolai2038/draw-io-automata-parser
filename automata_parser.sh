#!/bin/bash

ATTRIBUTE_ID="id"
ATTRIBUTE_TARGET="target"

function get_nodes_count() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo "You need to specify XML!" >&2
    return 1
  fi

  echo "<xml>${xml}</xml>" | xpath -q -e "count(//mxCell)" || return "$?"

  return 0
}

function get_node_attribute() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo "You need to specify XML!" >&2
    return 1
  fi

  local attribute_name="${1}" && shift
  if [ -z "${attribute_name}" ]; then
    echo "You need to specify attribute name!" >&2
    return 1
  fi

  echo "${xml}" | xpath -q -e "(//mxCell)/@${attribute_name}" | sed -E "s/^ ${attribute_name}=\"([^\"]+)\"\$/\\1/" || return "$?"

  return 0
}

function get_node_with_attribute_value() {
  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo "You need to specify XML!" >&2
    return 1
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

  local elements
  elements="$(echo "${file_content}" | xpath -q -e "
    //mxCell
  ")" || return "$?"

  if [ -z "${elements}" ]; then
    echo "No elements found!" >&2
    return 1
  fi

  local ellipses
  ellipses="$(echo "<xml>${elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"ellipse;\")
    ]
  ")" || return "$?"

  if [ -z "${ellipses}" ]; then
    echo "No ellipses found!" >&2
    return 1
  fi

  local arrows
  arrows="$(echo "<xml>${elements}</xml>" | xpath -q -e "
    //mxCell[
      starts-with(@style, \"edgeStyle\")
    ]
  ")" || return "$?"

  if [ -z "${arrows}" ]; then
    echo "No arrows found!" >&2
    return 1
  fi

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
  if [ -z "${start_arrow}" ] || ((start_arrow_count < 1)); then
    echo "No start arrow found! You need to create arrow with no source but connect it to some ellipse." >&2
    return 1
  elif ((start_arrow_count > 1)); then
    echo "Only one start arrow is allowed! Found: ${start_arrow_count}" >&2
    return 1
  fi
  echo "Start arrow found!" >&2

  local start_arrow_target
  start_arrow_target="$(get_node_attribute "${start_arrow}" "${ATTRIBUTE_TARGET}")" || return "$?"

  echo "${start_arrow_target}"

  get_node_with_attribute_value "${ellipses}" "${ATTRIBUTE_ID}" "${start_arrow_target}"

  local connected_arrows
  connected_arrows="$(echo "<xml>${arrows}</xml>" | xpath -q -e "
    //mxCell[
      @source
    ]
  ")" || return "$?"

  if [ -z "${connected_arrows}" ]; then
    echo "No connected arrows found!" >&2
    return 1
  fi

  echo "Parsing file \"${filePath}\": done!" >&2
  return 0
}

# If script is not sourced - we execute it
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
