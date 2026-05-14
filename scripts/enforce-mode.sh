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

# --- Helper: deny with structured reason ---
deny_with_reason() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# --- Vault path convention enforcement (mode-independent) ---
# Per [[mandatory-feature-folders]], [[research-subfolder]], [[context-md-as-vocabulary]]:
# - Vault root only holds index.md and CONTEXT.md; all other entries live in feature folders.
# - Research-type entries live in .research/ subfolders inside their feature folder.
# These rules apply in ALL modes (code and reasoning) — structural enforcement, not modal.
# Doctrine without enforcement is what [[mandatory-feature-folders]] was vaulted to correct.
check_vault_path() {
  local path="$1"
  [ -z "$path" ] && return 0

  # Only applies to writes inside .bocek/vault/
  case "$path" in
    *"/.bocek/vault/"*) ;;
    *) return 0 ;;
  esac

  # P4: flat-vault rejection
  # Match .bocek/vault/{slug}.md (no feature subfolder); allow only index.md and CONTEXT.md
  if [[ "$path" == *"/vault/"*".md" && "$path" != *"/vault/"*"/"*".md" ]]; then
    local base
    base=$(basename "$path" .md)
    if [[ "$base" != "index" && "$base" != "CONTEXT" ]]; then
      deny_with_reason "Vault path violation: '$base.md' at vault root is forbidden. Vault entries must live in a feature folder: .bocek/vault/{feature}/$base.md. Only index.md and CONTEXT.md may sit at the vault root (per [[mandatory-feature-folders]] + [[context-md-as-vocabulary]])."
    fi
  fi

  # R4: flat-research rejection
  # Match .bocek/vault/{feature}/*-research.md when NOT already inside a .research/ subfolder
  if [[ "$path" == *"/vault/"*"/"*"-research.md" && "$path" != *"/vault/"*"/.research/"* ]]; then
    local feature_dir
    feature_dir=$(dirname "$path")
    deny_with_reason "Research entry must live in the .research/ subfolder. Try: $feature_dir/.research/$(basename "$path") (per [[research-subfolder]])."
  fi
}

# R4 (frontmatter check): reject writes of `type: research` entries to non-.research/ paths
# regardless of filename. Catches the case where someone names a research file without the
# `-research.md` suffix and tries to write it at the feature-folder root.
# For Write: content is in arg $2 (from tool_input.content).
# For Edit: arg $2 empty; check the existing file at $1 instead.
# For Bash: this check is not applied (content is not available from JSON; heredocs and
# multi-step redirects can't be parsed safely from a single command string).
check_frontmatter_type_research() {
  local path="$1"
  local content="$2"
  [ -z "$path" ] && return 0

  # Only applies inside .bocek/vault/
  case "$path" in
    *"/.bocek/vault/"*) ;;
    *) return 0 ;;
  esac

  # Skip if already in .research/ — that's the legitimate target
  case "$path" in
    *"/.research/"*) return 0 ;;
  esac

  # Skip top-level vault meta — index.md and CONTEXT.md are exempted from feature-folder rules
  case "$(basename "$path")" in
    index.md|CONTEXT.md) return 0 ;;
  esac

  # Extract frontmatter type. awk reads either the inline content (Write) or the on-disk file (Edit).
  local frontmatter_type
  if [ -n "$content" ]; then
    frontmatter_type=$(printf '%s' "$content" | awk '/^---$/{if(c)exit;c=1;next} c && /^type:/{print $2; exit}' 2>/dev/null | tr -d '[:space:]')
  elif [ -f "$path" ]; then
    frontmatter_type=$(awk '/^---$/{if(c)exit;c=1;next} c && /^type:/{print $2; exit}' "$path" 2>/dev/null | tr -d '[:space:]')
  else
    return 0
  fi

  if [ "$frontmatter_type" = "research" ]; then
    local feature_dir
    feature_dir=$(dirname "$path")
    deny_with_reason "Research entry (frontmatter declares type: research) must live in the .research/ subfolder. Try: $feature_dir/.research/$(basename "$path") (per [[research-subfolder]])."
  fi
}

# Per [[context-md-folder-name-enforcement]]: writes that would CREATE a new feature folder
# require a matching `**Term:**` header in `.bocek/vault/CONTEXT.md`. Existing folders are
# grandfathered (gate fires only at folder-creation time). Exemptions: `_shared/`,
# `.research/` subfolders (inherit parent), `index.md` + `CONTEXT.md` (top-level meta).
# Match rule: lowercase + collapse runs of `[ -]` to single `-`, then string-equal.
check_feature_folder_match() {
  local path="$1"
  [ -z "$path" ] && return 0

  # Only applies inside .bocek/vault/
  case "$path" in
    *"/.bocek/vault/"*) ;;
    *) return 0 ;;
  esac

  # Skip top-level vault meta
  case "$(basename "$path")" in
    index.md|CONTEXT.md) return 0 ;;
  esac

  # Skip _shared/ (cross-feature escape hatch)
  case "$path" in
    *"/vault/_shared/"*) return 0 ;;
  esac

  # Compute vault dir and the immediate feature folder name
  local rel="${path#*/.bocek/vault/}"
  local feature="${rel%%/*}"
  local vault_dir="${path%/.bocek/vault/*}/.bocek/vault"
  local feature_dir="$vault_dir/$feature"

  # If feature folder already exists, allow — gate fires only at folder-creation
  if [ -d "$feature_dir" ]; then
    return 0
  fi

  # New feature folder — check CONTEXT.md for a slugified match
  local context_file="$vault_dir/CONTEXT.md"
  local feature_slug
  feature_slug=$(printf '%s' "$feature" | tr '[:upper:]' '[:lower:]' | tr -s ' -' '-')

  # Suggested term name for the denial message (TitleCase from slug)
  local suggested_term
  suggested_term=$(printf '%s' "$feature" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))} 1')

  if [ ! -f "$context_file" ]; then
    deny_with_reason "Feature folder '$feature/' has no matching term in .bocek/vault/CONTEXT.md (CONTEXT.md doesn't exist yet). Run 'bocek bootstrap' to scaffold it, then add a '**$suggested_term:**' definition before creating the folder (per [[context-md-folder-name-enforcement]])."
  fi

  local found=0
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    local term_slug
    term_slug=$(printf '%s' "$term" | tr '[:upper:]' '[:lower:]' | tr -s ' -' '-')
    if [ "$term_slug" = "$feature_slug" ]; then
      found=1
      break
    fi
  done < <(grep -oE '^\*\*[^:*]+:\*\*' "$context_file" 2>/dev/null | sed 's/^\*\*//; s/:\*\*$//')

  if [ "$found" -eq 0 ]; then
    deny_with_reason "Feature folder '$feature/' has no matching term in .bocek/vault/CONTEXT.md. Add a '**$suggested_term:**' definition (one-line entry per references/shared/context-format.md) before creating the folder (per [[context-md-folder-name-enforcement]])."
  fi
}

# --- Handle Edit and Write tools ---
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

  # Vault path conventions apply in all modes
  check_vault_path "$FILE_PATH"

  # R4 frontmatter-type-check: reject type:research content at non-.research/ paths
  if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
    check_frontmatter_type_research "$FILE_PATH" "$CONTENT"
  else
    check_frontmatter_type_research "$FILE_PATH" ""
  fi

  # D1 feature-folder vocabulary gate: writes that would create a new feature folder
  # require a matching CONTEXT.md term
  check_feature_folder_match "$FILE_PATH"

  # Code modes allow everything else
  case "$MODE" in
    "implementation"|"debugging"|"refactoring"|"idle")
      exit 0
      ;;
  esac

  # Reasoning modes: writes to .bocek/ are allowed (already passed vault path checks)
  if [[ "$FILE_PATH" == *".bocek/"* ]]; then
    exit 0
  fi

  # Block all other writes in reasoning modes
  deny_with_reason "${MODE} mode active. Source file writes are blocked. Write to .bocek/ vault or switch to a code mode (implementation, debugging, refactoring) to modify source files."
fi

# --- Handle Bash tool ---
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Vault path convention enforcement for bash commands that mention .bocek/vault/*.md paths.
  # Heuristic: extract whitespace-bounded tokens that look like vault paths, check each.
  # Not bulletproof against quoted args with embedded spaces, but covers the common cases.
  for cand in $(echo "$COMMAND" | grep -oE '[^[:space:]]*\.bocek/vault/[^[:space:]]+\.md' | sort -u); do
    check_vault_path "$cand"
    check_feature_folder_match "$cand"
  done

  # Code modes allow everything else
  case "$MODE" in
    "implementation"|"debugging"|"refactoring"|"idle")
      exit 0
      ;;
  esac

  # Reasoning modes: detect write patterns; allow only .bocek/-targeted writes

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
  deny_with_reason "${MODE} mode active. File-modifying bash commands are blocked on source files. Use Edit/Write for .bocek/ vault files, or switch to a code mode."
fi

# Unknown tool — allow by default
exit 0
