#!/bin/bash

if [ -n "${IS_FILE_SOURCED_ATTRIBUTES}" ]; then
  return
fi

# ========================================
# Colors for messages
# ========================================
export ATTRIBUTE_ID="id"
export ATTRIBUTE_TARGET="target"
export ATTRIBUTE_SOURCE="source"
export ATTRIBUTE_VALUE="value"
# ========================================

export IS_FILE_SOURCED_ATTRIBUTES=1
