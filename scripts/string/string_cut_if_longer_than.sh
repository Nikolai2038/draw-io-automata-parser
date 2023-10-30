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
  if [ "${IS_DEBUG_BASH}" == "1" ]; then
    echo "Directory before imports: \"${PWD}\"." >&2
  fi

  source_previous_directory="${PWD}"
  # We use "cd" instead of specifying file paths directly in the "source" comment, because these comments do not change when files are renamed or moved.
  # Moreover, we need to specify exact paths in "source" to use links to function and variables between files (language server).
  cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit "$?"
}

# Imports
# ...

# (REUSE) Prepare after imports
{
  cd "${source_previous_directory}" || exit "$?"

  if [ "${IS_DEBUG_BASH}" == "1" ]; then
    echo "Directory after imports: \"${PWD}\"." >&2
  fi
}

# Cuts text if it is longer than the specified max length
#
# <Argument 1>: Text
# [Argument 2]: Max length
function string_cut_if_longer_than() {
  # String itself
  local text="${1}" && shift
  # Maximum length (if not specified, then there are no restrictions)
  local max_length="${1}" && shift

  local text_length="${#text}" || return "$?"
  if [ -n "${max_length}" ] && ((text_length > max_length)); then
    text="${text:0:"${max_length}"}"
  fi

  echo -e "${text}"
  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    string_cut_if_longer_than "$@" || exit "$?"
  fi
}
