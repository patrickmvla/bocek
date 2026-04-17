#!/bin/bash
# Bocek session-start banner — tells Claude the current mode and available slash commands
# Registered via: bocek on
# Removed via: bocek off

MODE_FILE="$CLAUDE_PROJECT_DIR/.bocek/mode"
if [ ! -f "$MODE_FILE" ]; then
  exit 0
fi

MODE=$(cat "$MODE_FILE")

case "$MODE" in
  design|research|review)
    RULES="Reasoning mode: source-file writes outside .bocek/ are blocked. Vault writes always allowed."
    ;;
  implementation|debugging|refactoring)
    RULES="Code mode: all writes allowed. Implementation mode recompiles .bocek/vault/.compiled/ lazily."
    ;;
  idle|*)
    RULES="No primitive loaded. Use a slash command to begin."
    ;;
esac

CONTEXT="Bocek active. Current mode: \`$MODE\`. $RULES

Switch modes with slash commands: /design, /research, /implementation, /debugging, /refactoring, /review. Each command loads the matching primitive from ~/.bocek/primitives/ and updates .bocek/mode."

jq -nc --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
