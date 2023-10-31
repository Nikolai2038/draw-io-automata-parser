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
source "./table_set_rows.sh" || exit "$?"
source "./table_set_columns.sh" || exit "$?"
source "./table_set_cell_value.sh" || exit "$?"
source "./table_print.sh" || exit "$?"
source "./table_add_separator_after_row.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function _table_test() {
  local table_name="test"
  local rows_number=1
  local columns_number=5

  table_set_rows "${table_name}" "${rows_number}" || return "$?"
  table_set_columns "${table_name}" "${columns_number}" || return "$?"

  local row_id
  for ((row_id = 0; row_id < rows_number; row_id++)); do
    local column_id
    for ((column_id = 0; column_id < columns_number; column_id++)); do
      table_set_cell_value "${table_name}" "${row_id}" "${column_id}" "0" || return "$?"
    done
  done

  table_set_cell_value "${table_name}" "3" "3" "1258254" || return "$?"
  table_set_cell_value "${table_name}" "3" "4" "" || return "$?"
  table_set_cell_value "${table_name}" "3" "5" "" || return "$?"
  table_add_separator_after_row "${table_name}" "0" || return "$?"
  table_add_separator_after_row "${table_name}" "1" || return "$?"

  table_print "${table_name}" return "$?"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    _table_test "$@" || exit "$?"
  fi
}
