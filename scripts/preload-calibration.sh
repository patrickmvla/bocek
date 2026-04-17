#!/bin/bash
# Bocek calibration pre-load hook — injects shared/calibration.md into reasoning-mode turns
# Registered via: bocek on
# Removed via: bocek off

set -euo pipefail

MODE_FILE="$CLAUDE_PROJECT_DIR/.bocek/mode"
if [ ! -f "$MODE_FILE" ]; then
  exit 0
fi

MODE=$(cat "$MODE_FILE")

# Only inject in reasoning modes
case "$MODE" in
  design|research|review)
    ;;
  *)
    exit 0
    ;;
esac

CALIBRATION_FILE="$HOME/.bocek/references/shared/calibration.md"
if [ ! -f "$CALIBRATION_FILE" ]; then
  exit 0  # No calibration installed = no injection
fi

CALIBRATION_CONTENT=$(cat "$CALIBRATION_FILE")

# Inject as additionalContext via UserPromptSubmit hook output
jq -nc --arg ctx "$CALIBRATION_CONTENT" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
