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
source "./scripts/package/install_command.sh" || return "$?"
source "./scripts/messages.sh" || return "$?"
source "./scripts/xpath/load_xml.sh" || return "$?"
source "./scripts/xpath/get_nodes_count.sh" || return "$?"
source "./scripts/xpath/get_node_attribute_value.sh" || return "$?"
source "./scripts/xpath/get_node_with_attribute_value.sh" || return "$?"
source "./scripts/xpath/fill_lamda_and_delta_and_variables_names.sh" || return "$?"
source "./scripts/01_find_minimal/class_family_calculate.sh" || return "$?"
source "./scripts/01_find_minimal/class_family_print.sh" || return "$?"
source "./scripts/01_find_minimal/print_calculations_result.sh" || return "$?"
source "./scripts/01_find_minimal/fill_data_for_script_2.sh" || return "$?"
source "./scripts/01_find_minimal/print_result_for_script_2.sh" || return "$?"

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || return "$?"
}

export ARRAY_INDEX_SEPARATOR="___"

# Format for element: `cells["<column header 1 name><separator><column header 2 name><separator><row header name>"]="<cell value>"`
export CELLS
declare -A CELLS=()

# Start main script of Automata Parser
function automata_parser() {
  print_info "Welcome to ${C_HIGHLIGHT}Automata Parser${C_RETURN}!"

  local file_path="${1}" && shift
  if [ -z "${file_path}" ]; then
    print_error "You need to specify file path!"
    return 1
  fi

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

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    automata_parser "$@" || exit "$?"
  fi
}
