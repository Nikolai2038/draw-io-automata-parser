#!/bin/bash

if [ -n "${IS_FILE_SOURCED_COLORS}" ]; then
  return
fi

# ========================================
# Colors for messages
# ========================================
# Color for message
export C_INFO='\e[0;36m'
# Color for successful execution
export C_SUCCESS='\e[0;32m'
# Color for error
export C_WARNING='\e[0;33m'
# Color for error
export C_ERROR='\e[0;31m'

# Color for highlighted text
export C_HIGHLIGHT='\e[1;95m'

# Reset color
export C_RESET='\e[0m'

# Special text that will be replaced with the previous one
export C_RETURN='COLOR_RETURN'
# ========================================

export IS_FILE_SOURCED_COLORS=1
