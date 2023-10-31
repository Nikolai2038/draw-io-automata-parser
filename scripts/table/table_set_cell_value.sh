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
source "./_constants.sh" || exit "$?"
source "../variable/variables_must_be_specified.sh" || exit "$?"
source "../array/array_set.sh" || exit "$?"
source "./table_get_column_width.sh" || exit "$?"
source "./table_set_column_width.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function table_set_cell_value() {
  local table_name="${1}" && shift
  local row_id="${1}" && shift
  local column_id="${1}" && shift
  local cell_value="${1}" && shift
  variables_must_be_specified "table_name" "row_id" "column_id" || return "$?"

  array_set "${TABLE_CELL_PREFIX}" "${table_name}" "${row_id}" "${column_id}" "${cell_value}" || return "$?"

  local column_max_width
  column_max_width="$(table_get_column_width "${table_name}" "${column_id}")" || return "$?"

  local cell_width="${#cell_value}"
  if ((cell_width > column_max_width)); then
    table_set_column_width "${table_name}" "${column_id}" "${cell_width}" || return "$?"
  fi

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    table_set_cell_value "$@" || exit "$?"
  fi
}
