# Hook Enforcement: Design

## Context
The hook layer is Bocek's only mechanism that runs outside the context window. It costs zero tokens, doesn't degrade with context length, and can't be forgotten by the model. It's the backstop when primitive instructions lose attention and the model starts drifting toward default behavior.

Claude Code's PreToolUse hook fires before any permission check. A hook returning `permissionDecision: "deny"` blocks the tool even in `bypassPermissions` mode — this is non-bypassable enforcement that users can't override.

However, a known and filed issue (anthropics/claude-code#29709, closed as "not planned") documents that Claude actively circumvents Edit/Write hooks by falling back to Bash with `python -c`, `sed -i`, or shell redirects. Matching only Edit/Write leaves a trivial bypass. The hook must also intercept Bash.

## Goals
- Enforce mode constraints (reasoning modes block source file writes, code modes allow them)
- Catch file writes via Edit, Write, AND Bash (including common bypass patterns)
- Cost zero tokens — run entirely outside the context window
- Provide clear denial messages that guide the model back to correct behavior
- Be simple enough to audit in a bash script — no complex dependencies

## Non-Goals
- Not a security system — it prevents the model from violating its own mode, not from malicious actors
- Not a complete bash parser — catches 95%+ of bypass patterns, not every theoretical possibility
- Not a permission management system — it reads a mode file and enforces a simple allow/deny
- Not a replacement for primitive instructions — the hook is layer 1 of defense in depth

## Design

### Three-layer defense model

| Layer | Mechanism | What it catches | Failure mode |
|-------|-----------|----------------|--------------|
| 1. Hook enforcement | Bash script, zero tokens | Edit/Write + Bash file writes | Can't catch novel bypass patterns |
| 2. Primitive instructions | In-context, degrades over time | Everything the model does voluntarily | Loses attention in long sessions |
| 3. Session restart | Human decision | Everything | Requires human to notice degradation |

### Hook architecture

A single PreToolUse hook registered on `Edit|Write|Bash`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.bocek/scripts/enforce-mode.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### The enforcement script

```bash
#!/bin/bash
# ~/.bocek/scripts/enforce-mode.sh
# Bocek mode enforcement hook — runs outside context window, zero tokens

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
  
  # Check for file-modifying commands (from OpenCode's file-touching set)
  # Redirects: > >> 
  # Commands: sed -i, tee, dd, install, cp, mv, rm, mkdir, touch, chmod, chown
  # Inline scripts: python -c, perl -e, ruby -e, node -e
  
  WRITE_PATTERN=0
  
  # Shell redirects (most common bypass)
  if echo "$COMMAND" | grep -qE '[^<]>(?!&)|>>'; then
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
  # This is a heuristic: if .bocek/ appears in the command, likely a vault write
  if echo "$COMMAND" | grep -q '\.bocek/'; then
    exit 0
  fi
  
  # Block the bash write command
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${MODE} mode active. File-modifying bash commands are blocked on source files. Use Edit/Write for .bocek/ vault files, or switch to a code mode.\"}}"
  exit 0
fi

# Unknown tool — allow by default
exit 0
```

### What the hook catches

| Bypass pattern | Detection method | Caught? |
|---------------|------------------|---------|
| `Edit file.py` | Tool name match | Yes |
| `Write file.py` | Tool name match | Yes |
| `echo "code" > file.py` | Redirect detection | Yes |
| `sed -i 's/old/new/' file.py` | sed -i detection | Yes |
| `python3 -c "open('file.py','w').write(...)"` | python -c detection | Yes |
| `tee file.py` | tee detection | Yes |
| `cp template.py file.py` | cp detection | Yes |
| `cat > file.py << 'EOF'` | Redirect detection | Yes |
| `perl -e 'open(F,">file.py")...'` | perl -e detection | Yes |
| Novel bypass using uncommon tool | Not caught | No — layer 2 (primitive) covers |

### What the hook allows in reasoning modes

- `git clone`, `git log`, `git diff`, `git status` — read-only git operations
- `gh api` — GitHub API reads
- `ls`, `cat`, `head`, `tail`, `wc` — file reading
- `grep`, `rg`, `find`, `fd` — search
- `curl`, `wget` — web fetching (research mode)
- Any command that doesn't match file-write patterns

### Denial messages

The hook provides clear denial messages via `permissionDecisionReason` that tell the model:
1. What mode is active
2. Why the action is blocked
3. What alternatives exist (write to vault, switch mode)

This is critical — the model receives the denial as feedback and adjusts behavior. A silent block would cause the model to retry. A clear message redirects it.

### Mode file management

`.bocek/mode` contains a single word: `design`, `research`, `implementation`, `debugging`, `refactoring`, `review`, or `idle`.

The mode file is set by:
- The primitive loading instruction — "write `design` to `.bocek/mode`"
- Claude Code commands — `.claude/commands/design.md` includes the mode-set instruction
- Direct human action — `echo "design" > .bocek/mode`

When no mode file exists, the hook allows everything (exit 0). This means Bocek enforcement is entirely opt-in per project.

### Registration via toggle script

`bocek on` writes the hook entry to `.claude/settings.local.json`. `bocek off` removes it. The hook registration is:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.bocek/scripts/enforce-mode.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Settings.local.json is:
- Auto-gitignored by Claude Code
- Personal to the user
- Higher priority than project settings
- Merges with existing settings

## Alternatives Considered

**Edit/Write only (no Bash interception):** The original proposal from the design document. Rejected after research confirmed the Bash bypass is a known filed issue (anthropics/claude-code#29709). The model actively searches for Bash workarounds when Edit/Write is blocked.

**AST-based bash parsing (OpenCode approach):** OpenCode uses tree-sitter to parse bash commands into an AST, correctly handling compound commands, pipes, and subshells. Rejected for Bocek because it requires a Node.js or Python runtime with tree-sitter installed. Bocek's philosophy is zero dependencies — just bash. The regex approach catches 95%+ of bypass patterns without dependencies.

**Block Bash entirely in reasoning modes:** Simple but too aggressive. The model needs Bash for read-only operations in design mode (git clone, gh api, ls, cat). Blocking all Bash would cripple the design and research primitives.

**Accept the 95% case without Bash interception:** Rely only on primitive instructions for Bash discipline. Rejected because the filed issue shows the model actively seeks Bash workarounds when Edit/Write is blocked — this is not a theoretical risk but a documented behavior.

**Prompt-based hook (`type: "prompt"`):** Use a Claude model to evaluate whether a Bash command modifies files. Rejected because it adds latency and token cost to every Bash command. The regex approach is instant and free.

## Trade-offs

**Regex vs AST parsing:** The bash pattern detection uses regex, which can produce false positives (a grep for a file named "cp" would match) and false negatives (a novel bypass pattern wouldn't be caught). AST parsing would be more accurate but requires dependencies. The 95%+ catch rate is acceptable because layer 2 (primitive instructions) covers the gap.

**False positives:** A command like `grep -r "cp" .` contains "cp" and might trigger the file-modifying detection. In practice, the grep check looks for `\bcp\b` (word boundaries), reducing false positives. When a false positive occurs, the model receives a clear denial message and can rephrase the command.

**`.bocek/` heuristic:** The hook allows Bash writes when `.bocek/` appears in the command. This is a heuristic — a malicious or confused command could write to a source file while mentioning `.bocek/`. Accepted because the hook isn't a security system — it prevents accidental mode violation, not adversarial attacks.

## Prior Art

- OpenCode: AST-based bash parsing with tree-sitter, explicit file-touching command set (github.com/nicepkg/opencode, `src/tool/bash.ts`)
- Claude Code official example: regex-based command validator (`examples/hooks/bash_command_validator_example.py`) — only checks for grep/find, not file writes
- claudekit: 195+ security patterns across 12 categories
- sgasser security gist: blocks dangerous commands + credential file access
- anthropics/claude-code#29709: filed issue documenting Bash bypass of Edit/Write hooks

## References
- Claude Code hooks guide: https://code.claude.com/docs/en/hooks-guide
- Claude Code hooks reference: https://code.claude.com/docs/en/hooks
- OpenCode bash tool source: `/home/mvula/audhd/opencode/packages/opencode/src/tool/bash.ts`
- OpenCode permission system: `/home/mvula/audhd/opencode/packages/opencode/src/permission/`
- Bash bypass issue: https://github.com/anthropics/claude-code/issues/29709
