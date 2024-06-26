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
source "./class_family_print.sh" || exit "$?"
source "./_constants.sh" || exit "$?"

# (REUSE) Prepare after imports
{
  eval "cd \"\${source_previous_directory_$(get_text_hash "${BASH_SOURCE[*]}")}\"" || exit "$?"
}

function print_calculations_result() {
  local was_error="${1:-0}" && shift

  # ----------------------------------------
  # Creating table 1 and table 2 headers
  # ----------------------------------------
  local table_1_headers_line_1_lambda_part=""
  local table_1_headers_line_1_delta_part=""
  local table_1_headers_line_1_class_family_part=""

  local table_2_headers_line_1_lambda_part=""
  local table_2_headers_line_1_delta_part=""

  local table_1_headers_line_2_variables_part=""
  local table_2_headers_line_2_variables_part=""

  local variable_name_id_in_list
  for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
    table_1_headers_line_1_lambda_part+="${TABLE_BEFORE_CELL_VALUE}${LAMBDA}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    table_1_headers_line_1_delta_part+="${TABLE_BEFORE_CELL_VALUE}${DELTA}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"

    table_2_headers_line_1_lambda_part+="${TABLE_BEFORE_CELL_VALUE}${LAMBDA_MIN}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    table_2_headers_line_1_delta_part+="${TABLE_BEFORE_CELL_VALUE}${DELTA_MIN}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
  done

  # For lambda and delta columns
  local column_id
  for ((column_id = 0; column_id < 2; column_id++)); do
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      table_1_headers_line_2_variables_part+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"

      table_2_headers_line_2_variables_part+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    done
  done

  # Start from (K1) to (last K - 1) because (last K) and (last K - 1) are the same
  for ((class_family_id = 1; class_family_id < class_families_count - 1; class_family_id++)); do
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      table_1_headers_line_1_class_family_part+="${TABLE_BEFORE_CELL_VALUE}${CLASS_FAMILY_SYMBOL}${class_family_id}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"

      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      table_1_headers_line_2_variables_part+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    done
  done

  local table_1_headers_line_1="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${table_1_headers_line_1_lambda_part}${table_1_headers_line_1_delta_part}${table_1_headers_line_1_class_family_part}"
  local table_1_headers_line_2="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${table_1_headers_line_2_variables_part}"
  local table_1_headers="${table_1_headers_line_1}\n${table_1_headers_line_2}"

  local table_2_headers_line_1="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${table_2_headers_line_1_lambda_part}${table_2_headers_line_1_delta_part}"
  local table_2_headers_line_2="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${table_2_headers_line_2_variables_part}"
  local table_2_headers="${table_2_headers_line_1}\n${table_2_headers_line_2}"
  # ----------------------------------------

  # ----------------------------------------
  # Horizontal border for table 1
  # ----------------------------------------
  local table_1_headers_line_1_with_spaces
  table_1_headers_line_1_with_spaces="$(echo -e "${table_1_headers_line_2}" | expand -t ${TAB_SIZE})" || return "$?"
  local table_1_width="${#table_1_headers_line_1_with_spaces}"

  local table_1_horizontal_border=""
  local symbol_id
  for ((symbol_id = 0; symbol_id < table_1_width; symbol_id++)); do
    table_1_horizontal_border+="${TABLE_HORIZONTAL_BORDER_SYMBOL}"
  done
  # ----------------------------------------

  # ----------------------------------------
  # Horizontal border for table 2
  # ----------------------------------------
  local table_2_headers_line_1_with_spaces
  table_2_headers_line_1_with_spaces="$(echo -e "${table_2_headers_line_2}" | expand -t ${TAB_SIZE})" || return "$?"
  local table_2_width="${#table_2_headers_line_1_with_spaces}"

  local table_2_horizontal_border=""
  local symbol_id
  for ((symbol_id = 0; symbol_id < table_2_width; symbol_id++)); do
    table_2_horizontal_border+="${TABLE_HORIZONTAL_BORDER_SYMBOL}"
  done
  # ----------------------------------------

  # ----------------------------------------
  # Table 1 content
  # ----------------------------------------
  local table_1_content=""
  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"

    table_1_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${ellipse_value}${TABLE_AFTER_CELL_VALUE}"

    # lambda
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_1_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    # delta
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_1_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    # Start from (K1) to (last K - 1) because (last K) and (last K - 1) are the same
    for ((class_family_id = 1; class_family_id < class_families_count - 1; class_family_id++)); do
      for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
        local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
        local cell_value="${CELLS["${CLASS_FAMILY_SYMBOL}${class_family_id}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
        table_1_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
      done
    done

    table_1_content+="${BORDER_SYMBOL}"

    # Make sure last line is not line break because `sort` later will move it to the top
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      table_1_content+="\n"
    fi
  done
  # ----------------------------------------

  # ----------------------------------------
  # Table 2 content
  # ----------------------------------------
  local table_2_content=""
  local symbol_id
  for ((symbol_id = 0; symbol_id < LAST_CLASS_FAMILY_SYMBOLS_COUNT; symbol_id++)); do
    local ellipse_value="${LAST_CLASS_FAMILY_SYMBOLS["${symbol_id}"]}"

    table_2_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${ellipse_value}${TABLE_AFTER_CELL_VALUE}"

    # lambda
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${LAMBDA_MIN}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_2_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    # delta
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${DELTA_MIN}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_2_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    table_2_content+="${BORDER_SYMBOL}"

    # Make sure last line is not line break because `sort` later will move it to the top
    if ((symbol_id != LAST_CLASS_FAMILY_SYMBOLS_COUNT - 1)); then
      table_2_content+="\n"
    fi
  done
  # ----------------------------------------

  # ----------------------------------------
  # Print
  # ----------------------------------------
  echo "${BOLD_LINE}"
  echo "Result:"
  echo "${BOLD_LINE}"
  echo "${SYMBOL_ELLIPSES_VALUES} = { ${INPUT_AUTOMATE_ELLIPSES_VALUES} }"
  echo "${SYMBOL_START_ELLIPSE_VALUE} = ${INPUT_AUTOMATE_START_ELLIPSE_VALUE}"
  echo ""
  echo "${table_1_horizontal_border}"
  echo -e "${table_1_headers}"
  echo "${table_1_horizontal_border}"
  echo -e "${table_1_content}"
  echo "${table_1_horizontal_border}"

  # Print class families
  echo ""
  for ((class_family_id = 0; class_family_id < class_families_count; class_family_id++)); do
    echo -n "${CLASS_FAMILY_SYMBOL}${class_family_id} = "
    class_family_print "${class_family_id}" "${DO_PRINT_CLASS_FAMILY_ID}" || return "$?"
  done
  if ((!was_error)); then
    echo "${CLASS_FAMILY_SYMBOL}${LAST_CALCULATED_CLASS_FAMILY_ID} == ${CLASS_FAMILY_SYMBOL}$((LAST_CALCULATED_CLASS_FAMILY_ID - 1)) == ${CLASS_FAMILY_SYMBOL}"
  fi

  echo ""
  echo "${SYMBOL_ELLIPSES_VALUES}${MIN} = { ${OUTPUT_AUTOMATE_ELLIPSES_VALUES} }"
  echo "${SYMBOL_START_ELLIPSE_VALUE}${MIN} = ${OUTPUT_AUTOMATE_START_ELLIPSE_VALUE}"
  echo ""
  echo "${table_2_horizontal_border}"
  echo -e "${table_2_headers}"
  echo "${table_2_horizontal_border}"
  echo -e "${table_2_content}"
  echo "${table_2_horizontal_border}"
  echo "${BOLD_LINE}"
  # ----------------------------------------

  return 0
}

# (REUSE) Add ability to execute script by itself (for debugging)
{
  if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
    print_calculations_result "$@" || exit "$?"
  fi
}
