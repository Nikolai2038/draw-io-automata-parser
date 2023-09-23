#!/bin/bash

if [ -n "${IS_FILE_SOURCED_CLASS_SYMBOLS}" ]; then
  return
fi

declare -a CLASS_SYMBOLS=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")
export CLASS_SYMBOLS_COUNT="${#CLASS_SYMBOLS[@]}"

export IS_FILE_SOURCED_CLASS_SYMBOLS=1
