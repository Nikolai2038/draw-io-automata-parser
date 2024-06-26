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
source "./string_cut_if_longer_than.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

# Outputs a string with the specified length. If the string is too long, it cuts off. If it is too short, spaces are added to it.
#
# <Argument 1>: String
# <Argument 2>: Required length
function string_get_with_length() {
  # String itself
  local text="${1}" && shift

  # Maximum length
  local max_length="${1}" && shift
  if [[ -z ${max_length} ]]; then
    print_error "Enter the required length!"
    return 1
  fi

  # Cutting
  text="$(string_cut_if_longer_than "${text}" "${max_length}")" || return "$?"

  local text_length="${#text}" || return "$?"

  local extra_spaces_count="$((max_length - text_length))"
  while [[ ${extra_spaces_count} -gt "0" ]]; do
    text+=" "
    extra_spaces_count=$((extra_spaces_count - 1))
  done

  echo -e "${text}"

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    string_get_with_length "$@" || exit "$?"
  fi
}
