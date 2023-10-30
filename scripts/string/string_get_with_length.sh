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
source "./string_cut_if_longer_than.sh"

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || return "$?"
}

# Outputs a string with the specified length. If the string is too long, it cuts off. If it is too short, spaces are added to it.
#
# <Argument 1>: String
# <Argument 2>: Required length
function get_with_length() {
  # String itself
  local text="${1}" && shift

  # Maximum length
  local max_length="${1}" && shift
  if [[ -z ${max_length} ]]; then
    bccsPrintError "Введите требуемую длину!"
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
    get_with_length "$@" || exit "$?"
  fi
}
