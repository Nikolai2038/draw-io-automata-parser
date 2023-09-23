#!/bin/bash

if [ -n "${IS_FILE_SOURCED_CLASS_FAMILY}" ]; then
  return
fi

export CLASS_FAMILY_SYMBOL="K"

declare -g -A K=()

export IS_FILE_SOURCED_CLASS_FAMILY=1
