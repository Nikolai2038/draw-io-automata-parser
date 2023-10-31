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

function class_family_print() {
  local class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify class family id!"
    return 1
  fi

  local do_print_class_family_id="${1}" && shift
  if [ -z "${class_family_id}" ]; then
    print_error "You need to specify do or do not print class family id!"
    return 1
  fi

  echo -n "{"

  local is_first_class_to_print=1

  local class_symbol_id
  for ((class_symbol_id = 0; class_symbol_id < CLASS_SYMBOLS_COUNT; class_symbol_id++)); do
    local class_symbol="${CLASS_SYMBOLS["${class_symbol_id}"]}"
    local class_key="${class_symbol}${class_family_id}"

    local class_value="${CLASS_FAMILIES["${class_key}"]}"

    if [ -z "${class_value}" ]; then
      continue
    fi

    if ((is_first_class_to_print)); then
      is_first_class_to_print=0
    else
      echo -n ","
    fi

    echo -n " ${class_symbol}"

    local class_value_with_commas
    class_value_with_commas="$(echo "${class_value}" | sed -E 's/ /,/g')" || return "$?"

    if ((do_print_class_family_id)); then
      echo -n "${class_family_id}={${class_value_with_commas}}"
    else
      echo -n "={${class_value_with_commas}}"
    fi
  done

  echo " }"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    class_family_print "$@" || exit "$?"
  fi
}
