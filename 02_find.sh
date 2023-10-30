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

export ARRAY_INDEX_SEPARATOR="___"

# Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
export CELLS
declare -A CELLS=()

# Start main script of Automata Parser
function automata_parser() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "./scripts/1_portable/package/install_command.sh" || return "$?"
  source "./scripts/1_portable/messages.sh" || return "$?"
  source "./scripts/2_inner/xpath/load_xml.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_nodes_count.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/xpath/get_node_with_attribute_value.sh" || return "$?"
  source "./scripts/2_inner/xpath/fill_lamda_and_delta_and_variables_names.sh" || return "$?"
  source "./scripts/2_inner/class_family_calculate.sh" || return "$?"
  source "./scripts/2_inner/class_family_print.sh" || return "$?"
  source "./scripts/2_inner/print_calculations_result.sh" || return "$?"
  source "./scripts/2_inner/fill_data_for_script_2.sh" || return "$?"
  source "./scripts/2_inner/print_result_for_script_2.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  print_info "Welcome to ${C_HIGHLIGHT}Automata Parser${C_RETURN}!"

  local file_path="${1}" && shift
  if [ -z "${file_path}" ]; then
    print_error "You need to specify file path!"
    return 1
  fi

  # ========================================
  # 3. Main code
  # ========================================

  install_command "xpath" "libxml-xpath-perl" || return "$?"

  load_xml "${file_path}" || return "$?"

  print_info "Parsing..."

  local was_error=0
  fill_data_for_script_2 || was_error="$?"

  print_result_for_script_2 "${was_error}" || return "$?"

  if ((was_error)); then
    print_error "Parsing: failed!"
  else
    print_success "Parsing: done!"
  fi

  return "${was_error}"
}

# ========================================
# Add ability to execute script by itself (for debugging)
# ========================================
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  automata_parser "$@" || exit "$?"
fi
# ========================================
