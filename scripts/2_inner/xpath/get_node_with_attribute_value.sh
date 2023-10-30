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

function get_node_with_attribute_value() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "../../1_portable/messages.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local xml="${1}" && shift
  if [ -z "${xml}" ]; then
    echo ""
    return 0
  fi

  local attribute_name="${1}" && shift
  if [ -z "${attribute_name}" ]; then
    print_error "You need to specify attribute name!" >&2
    return 1
  fi

  local attribute_value="${1}" && shift
  if [ -z "${attribute_value}" ]; then
    print_error "You need to specify attribute value!" >&2
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  echo "<xml>${xml}</xml>" | xpath -q -e "(//mxCell[@${attribute_name}=\"${attribute_value}\"]" || return "$?"

  return 0
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  get_node_with_attribute_value "$@" || exit "$?"
fi
# ========================================
