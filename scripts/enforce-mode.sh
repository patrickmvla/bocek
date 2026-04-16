#!/bin/bash
# Bocek mode enforcement hook — runs outside context window, zero tokens
# Registered via: bocek on
# Removed via: bocek off

# Read mode file
MODE_FILE="$CLAUDE_PROJECT_DIR/.bocek/mode"
if [ ! -f "$MODE_FILE" ]; then
  exit 0  # No mode file = no enforcement
fi

MODE=$(cat "$MODE_FILE")
INPUT=$(cat)  # Read JSON from stdin

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# Code modes allow everything
case "$MODE" in
  "implementation"|"debugging"|"refactoring"|"idle")
    exit 0
    ;;
esac

# Reasoning modes (design, research, review) — block source file writes

# --- Handle Edit and Write tools ---
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

  # Allow writes to .bocek/ (vault writes always permitted)
  if [[ "$FILE_PATH" == *".bocek/"* ]]; then
    exit 0
  fi

  # Block all other writes in reasoning modes
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${MODE} mode active. Source file writes are blocked. Write to .bocek/ vault or switch to a code mode (implementation, debugging, refactoring) to modify source files.\"}}"
  exit 0
fi

# --- Handle Bash tool ---
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  WRITE_PATTERN=0

  # Shell redirects (most common bypass)
  # Strip /dev/null redirects first, then check for remaining redirects
  CMD_STRIPPED=$(echo "$COMMAND" | sed 's|>[>&]*\s*/dev/null||g; s|2>&1||g')
  if echo "$CMD_STRIPPED" | grep -qE '[^<>]>([^>&]|$)|>>'; then
    WRITE_PATTERN=1
  fi

  # sed in-place editing
  if echo "$COMMAND" | grep -qE '\bsed\b.*-i'; then
    WRITE_PATTERN=1
  fi

  # tee (writes to files)
  if echo "$COMMAND" | grep -qE '\btee\b'; then
    WRITE_PATTERN=1
  fi

  # File-modifying commands
  if echo "$COMMAND" | grep -qE '\b(cp|mv|rm|mkdir|touch|chmod|chown|install|dd)\b'; then
    WRITE_PATTERN=1
  fi

  # Inline script execution (python -c, perl -e, etc.)
  if echo "$COMMAND" | grep -qE '\b(python3?|perl|ruby|node)\b.*(-c|-e)\b'; then
    WRITE_PATTERN=1
  fi

  # If no write pattern detected, allow (read-only bash is fine)
  if [ "$WRITE_PATTERN" -eq 0 ]; then
    exit 0
  fi

  # Write pattern detected — check if target is .bocek/
  if echo "$COMMAND" | grep -q '\.bocek/'; then
    exit 0
  fi

  # Block the bash write command
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${MODE} mode active. File-modifying bash commands are blocked on source files. Use Edit/Write for .bocek/ vault files, or switch to a code mode.\"}}"
  exit 0
fi

# Unknown tool — allow by default
exit 0
