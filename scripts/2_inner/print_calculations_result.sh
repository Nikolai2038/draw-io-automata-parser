#!/bin/bash

if [ -n "${IS_FILE_SOURCED_PRINT_CALCULATIONS_RESULT}" ]; then
  return
fi

# Tab size when printing in terminal
export TAB_SIZE=4
tabs -${TAB_SIZE}

export TABLE_BEFORE_CELL_VALUE="\t"
export TABLE_AFTER_CELL_VALUE="\t"
export TABLE_EMPTY_CELL_VALUE="?"
export TABLE_EMPTY_CELL_HEADER=" "

export BOLD_LINE="================================================================================"
export BORDER_SYMBOL="|"
export TABLE_HORIZONTAL_BORDER_SYMBOL="-"

export MIN="min"

export LAMBDA="λ"
export DELTA="δ"

export LAMBDA_MIN="${LAMBDA}_${MIN}"
export DELTA_MIN="${DELTA}_${MIN}"

export SYMBOL_ELLIPSES_VALUES="S"
export SYMBOL_START_ELLIPSE_VALUE="u0"

function print_calculations_result() {
  # ========================================
  # 1. Imports
  # ========================================

  local source_previous_directory="${PWD}"
  cd "$(dirname "$(find "$(dirname "${0}")" -name "$(basename "${BASH_SOURCE[0]}")" | head -n 1)")" || return "$?"
  source "../1_portable/messages.sh" || return "$?"
  source "./class_family_print.sh" || return "$?"
  cd "${source_previous_directory}" || return "$?"

  # ========================================
  # 2. Arguments
  # ========================================

  local was_error="${1:-0}" && shift

  # ========================================
  # 3. Main code
  # ========================================

  # ----------------------------------------
  # Creating table's headers
  # ----------------------------------------

  local headers_line_1_lambda_part=""
  local headers_line_1_delta_part=""
  local headers_line_1_class_family_part=""

  local headers_line_2_variables_part=""

  local variable_name_id_in_list
  for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
    headers_line_1_lambda_part+="${TABLE_BEFORE_CELL_VALUE}${LAMBDA}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    headers_line_1_delta_part+="${TABLE_BEFORE_CELL_VALUE}${DELTA}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
  done

  # For lambda and delta columns
  local column_id
  for ((column_id = 0; column_id < 2; column_id++)); do
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      headers_line_2_variables_part+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    done
  done

  # Start from (K1) to (last K - 1) because (last K) and (last K - 1) are the same
  for ((class_family_id = 1; class_family_id < class_families_count - 1; class_family_id++)); do
    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      headers_line_1_class_family_part+="${TABLE_BEFORE_CELL_VALUE}${CLASS_FAMILY_SYMBOL}${class_family_id}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"

      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      headers_line_2_variables_part+="${TABLE_BEFORE_CELL_VALUE}${variable_name_in_list}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}"
    done
  done

  local headers_line_1="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${headers_line_1_lambda_part}${headers_line_1_delta_part}${headers_line_1_class_family_part}"
  local headers_line_2="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${TABLE_EMPTY_CELL_HEADER}${TABLE_AFTER_CELL_VALUE}${BORDER_SYMBOL}${headers_line_2_variables_part}"

  local table_headers="${headers_line_1}\n${headers_line_2}"
  # ----------------------------------------

  # ----------------------------------------
  # Horizontal border for table
  # ----------------------------------------
  local headers_line_1_with_spaces
  headers_line_1_with_spaces="$(echo -e "${headers_line_1}" | expand -t ${TAB_SIZE})" || return "$?"
  local table_width="${#headers_line_1_with_spaces}"
  ((table_width += TAB_SIZE))

  local table_horizontal_border=""
  local symbol_id
  for ((symbol_id = 0; symbol_id < table_width; symbol_id++)); do
    table_horizontal_border+="${TABLE_HORIZONTAL_BORDER_SYMBOL}"
  done
  # ----------------------------------------

  # ----------------------------------------
  # Table content
  # ----------------------------------------
  local table_content=""

  for ((ellipse_id_in_list = 0; ellipse_id_in_list < ELLIPSES_COUNT; ellipse_id_in_list++)); do
    local ellipse_value="${ELLIPSES_VALUES["${ellipse_id_in_list}"]}"

    table_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${ellipse_value}${TABLE_AFTER_CELL_VALUE}"

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${LAMBDA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
      local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
      local cell_value="${CELLS["${DELTA}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
      table_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
    done

    # Start from (K1) to (last K - 1) because (last K) and (last K - 1) are the same
    for ((class_family_id = 1; class_family_id < class_families_count - 1; class_family_id++)); do
      for ((variable_name_id_in_list = 0; variable_name_id_in_list < VARIABLES_NAME_COUNT; variable_name_id_in_list++)); do
        local variable_name_in_list="${VARIABLES_NAMES["${variable_name_id_in_list}"]}"
        local cell_value="${CELLS["${CLASS_FAMILY_SYMBOL}${class_family_id}${ARRAY_INDEX_SEPARATOR}${variable_name_in_list}${ARRAY_INDEX_SEPARATOR}${ellipse_value}"]}"
        table_content+="${BORDER_SYMBOL}${TABLE_BEFORE_CELL_VALUE}${cell_value:-"${TABLE_EMPTY_CELL_VALUE}"}${TABLE_AFTER_CELL_VALUE}"
      done
    done

    table_content+="${BORDER_SYMBOL}"

    # Make sure last line is not line break because `sort` later will move it to the top
    if ((ellipse_id_in_list != ELLIPSES_COUNT - 1)); then
      table_content+="\n"
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
  echo "${table_horizontal_border}"
  echo -e "${table_headers}"
  echo "${table_horizontal_border}"
  echo -e "${table_content}" | sort --unique
  echo "${table_horizontal_border}"

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
  echo "${BOLD_LINE}"
  # ----------------------------------------

  return 0
}

# If script is not sourced - we execute it
if [ "${0}" == "${BASH_SOURCE[0]}" ]; then
  print_calculations_result "$@" || exit "$?"
fi

export IS_FILE_SOURCED_PRINT_CALCULATIONS_RESULT=1
