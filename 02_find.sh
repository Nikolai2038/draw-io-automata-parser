#!/bin/bash

# (REUSE) Special function to get current script file hash
function get_text_hash() {
  echo "${*}" | sha256sum | cut -d ' ' -f 1 || return "$?"
  return 0
}

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
  # Because variables is the same when sourcing, we depend on file hash.
  # Also, we don't use variable for variable name here, because it will fall in the same problem.
  eval "source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")=\"${PWD}\"" || exit "$?"

  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit "$?"
}

# Imports
source "./scripts/package/install_command.sh" || exit "$?"
source "./scripts/messages.sh" || exit "$?"
source "./scripts/xpath/load_xml.sh" || exit "$?"
source "./scripts/xpath/get_nodes_count.sh" || exit "$?"
source "./scripts/xpath/get_node_attribute_value.sh" || exit "$?"
source "./scripts/xpath/get_node_with_attribute_value.sh" || exit "$?"
source "./scripts/xpath/fill_lamda_and_delta_and_variables_names.sh" || exit "$?"
source "./scripts/01_find_minimal/class_family_calculate.sh" || exit "$?"
source "./scripts/01_find_minimal/class_family_print.sh" || exit "$?"
source "./scripts/01_find_minimal/print_calculations_result.sh" || exit "$?"
source "./scripts/01_find_minimal/fill_data_for_script_2.sh" || exit "$?"
source "./scripts/01_find_minimal/print_result_for_script_2.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
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
