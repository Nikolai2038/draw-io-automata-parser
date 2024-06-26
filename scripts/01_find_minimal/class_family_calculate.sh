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
source "../messages.sh" || exit "$?"
source "./_constants.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function class_family_calculate() {
  local ellipses_values_as_string="${1}" && shift
  if [ -z "${ellipses_values_as_string}" ]; then
    print_error "You need to specify ellipses values as string!"
    return 1
  fi

  local lines_to_find_family_class="${1}" && shift
  if [ -z "${lines_to_find_family_class}" ]; then
    print_error "You need to specify string to find family class!"
    return 1
  fi

  local class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify class family id!"
    return 1
  fi

  declare -a ellipses_values=()
  mapfile -t ellipses_values <<< "${ellipses_values_as_string}" || return "$?"

  declare -a lines=()
  mapfile -t lines <<< "${lines_to_find_family_class}" || return "$?"

  local lines_count="${#lines[@]}"

  local free_symbol_id=0
  declare -A line_to_symbol=()

  local line_id
  for ((line_id = 0; line_id < lines_count; line_id++)); do
    local line="${lines["${line_id}"]}"

    local class_symbol="${line_to_symbol["${line}"]}"
    if [ -z "${class_symbol}" ]; then
      line_to_symbol["${line}"]="${CLASS_SYMBOLS["${free_symbol_id}"]}${class_family_id}"
      class_symbol="${line_to_symbol["${line}"]}"
      ((free_symbol_id++))
      if ((free_symbol_id >= CLASS_SYMBOLS_COUNT)); then
        echo "Need to increase CLASS_SYMBOLS array!"
        return 1
      fi
    fi

    if [ -n "${CLASS_FAMILIES["${class_symbol}"]}" ]; then
      CLASS_FAMILIES["${class_symbol}"]+=" "
    fi

    CLASS_FAMILIES["${class_symbol}"]+="${ellipses_values["${line_id}"]}"
  done

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    class_family_calculate "$@" || exit "$?"
  fi
}
