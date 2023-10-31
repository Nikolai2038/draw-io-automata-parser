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
source "../messages.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

# Sets the value of a variable with the specified keys
#
# <Argument 1>: Variable keys
# <Argument 2>: Variable value
function array_set() {
  # Number of arguments
  # The last argument will always be the value of the variable
  local args_amount="$#"
  if ((args_amount < 2)); then
    print_error "At least two arguments are required! The last value should be the assigned value for the variable. Before it you need to specify array keys. Number of arguments received: ${C_COMMAND}${args_amount}${C_RETURN}" || return "$?"
    return 1
  fi

  # Combined keys in one line
  local result_keys=""
  while [[ $# -gt 1 ]]; do
    # Variable key
    local key="${1}" && shift
    result_keys+="${key}"
  done

  # Hashed value of variable keys in one line
  local result_keys_hashed
  result_keys_hashed="$(get_text_hash "${result_keys}")" || return "$?"
  # Use upper case letters
  result_keys_hashed="${result_keys_hashed^^}"

  # The final key of the variable
  local result_variable_key="${ARRAY_PREFIX}${result_keys_hashed}"

  # New variable value
  local variable_value="${1//'"'/'\"'}" && shift

  # Setting the value
  eval "export ${result_variable_key}=\"${variable_value}\"" || return "$?"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    array_set "$@" || exit "$?"
  fi
}
