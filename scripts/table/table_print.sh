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
source "../array/array_get.sh" || exit "$?"
source "../string/string_get_with_length.sh" || exit "$?"
source "./table_get_column_width.sh" || exit "$?"
source "./table_get_cell_value.sh" || exit "$?"
source "./table_get_columns_number.sh" || exit "$?"
source "./table_get_rows_number.sh" || exit "$?"
source "./table_is_separator_after_row.sh" || exit "$?"
source "../string/string_repeat_symbol.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function table_print() {
  local table_name="${1}" && shift
  variables_must_be_specified "table_name" || return "$?"

  local rows_number
  rows_number="$(table_get_rows_number "${table_name}")" || return "$?"
  if [ -z "${rows_number}" ]; then
    print_error "You must define rows number first!" || return "$?"
    return 1
  fi

  local columns_number
  columns_number="$(table_get_columns_number "${table_name}")" || return "$?"
  if [ -z "${columns_number}" ]; then
    print_error "You must define columns number first!" || return "$?"
    return 1
  fi
  if ((columns_number == 0)); then
    print_error "Columns number is 0!" || return "$?"
    return 1
  fi

  local row_extra_prefix_after_first=" "
  local row_prefix="${TABLE_VERTICAL_BORDER} "
  local row_postfix=" ${TABLE_VERTICAL_BORDER}"

  local row_extra_prefix_after_first_width="${#row_extra_prefix_after_first}"
  local row_prefix_width="${#row_prefix}"
  local row_postfix_width="${#row_postfix}"

  # Find row width
  local row_text_width
  ((row_text_width = row_extra_prefix_after_first_width * (columns_number - 1) + row_prefix_width * columns_number + row_postfix_width))
  local column_id
  for ((column_id = 0; column_id < columns_number; column_id++)); do
    local column_width
    column_width="$(table_get_column_width "${table_name}" "${column_id}")" || return "$?"
    ((row_text_width += column_width))
  done

  local horizontal_border
  horizontal_border="$(string_repeat_symbol "${TABLE_HORIZONTAL_BORDER}" "${row_text_width}")" || return "$?"

  echo "${horizontal_border}"
  if ((rows_number > 0)); then
    local row_id
    for ((row_id = 0; row_id < rows_number; row_id++)); do
      local column_id
      for ((column_id = 0; column_id < columns_number; column_id++)); do
        local column_width
        column_width="$(table_get_column_width "${table_name}" "${column_id}")" || return "$?"

        local cell_value
        cell_value="$(table_get_cell_value "${table_name}" "${row_id}" "${column_id}")" || return "$?"

        cell_value="$(string_get_with_length "${cell_value}" "${column_width}")" || return "$?"

        if ((column_id > 0)); then
          echo -n "${row_extra_prefix_after_first}"
        fi
        echo -n "${row_prefix}${cell_value}"
      done
      echo "${row_postfix}"

      # Extra separators, if needed
      local is_separator_after_row
      is_separator_after_row="$(table_is_separator_after_row "${table_name}" "${row_id}")" || return "$?"
      if ((is_separator_after_row)); then
        echo "${horizontal_border}"
      fi
    done
  else
    string_get_with_length "No rows" "${row_text_width}" || return "$?"
  fi
  echo "${horizontal_border}"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    table_print "$@" || exit "$?"
  fi
}
