# Toggle Script: Design

## Context
The toggle script (`bocek`) is the only integration point between Bocek and Claude Code's infrastructure. It writes hooks into `.claude/settings.local.json` when activated and strips them when deactivated. This is a sensitive operation — malformed JSON breaks the user's entire Claude Code setup.

Claude Code's settings system merges hooks across scopes (concatenated and deduplicated). Settings.local.json is auto-gitignored. The file watcher picks up changes automatically — no session restart needed after toggling.

## Goals
- Safely add and remove Bocek's hook entry from settings.local.json
- Never break existing settings — preserve all non-Bocek entries
- Be idempotent — running `bocek on` twice produces the same result
- Provide recovery path for any failure via backups
- Report clear status information

## Non-Goals
- Not a project scaffolding tool — doesn't create vault structure (primitives handle that)
- Not a session manager — doesn't start or control Claude Code sessions
- Not a primitive loader — the human tells Claude to read primitives

## Design

### Commands

**`bocek on`**

```bash
# 1. Check dependencies
command -v jq >/dev/null 2>&1 || { echo "bocek requires jq. Install: brew install jq (mac) or apt install jq (linux)"; exit 1; }

# 2. Ensure .claude/ directory exists
mkdir -p "$PROJECT_ROOT/.claude"

# 3. Read existing settings or default to empty object
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.local.json"
if [ -f "$SETTINGS_FILE" ]; then
  CURRENT=$(cat "$SETTINGS_FILE")
else
  CURRENT='{}'
fi

# 4. Backup before modifying
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bocek-backup"
fi

# 5. Merge Bocek hook entry (idempotent)
BOCEK_HOOK='{
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
}'

# Deep merge — adds Bocek hook without touching other settings
# If PreToolUse already has entries, appends Bocek's entry
MERGED=$(echo "$CURRENT" | jq --argjson bocek "$BOCEK_HOOK" '
  . as $base |
  $bocek.hooks.PreToolUse[0] as $new_hook |
  # Check if Bocek hook already exists (by command match)
  if ($base.hooks.PreToolUse // [] | map(select(.hooks[0].command == "~/.bocek/scripts/enforce-mode.sh")) | length) > 0
  then $base  # Already registered, no change
  else
    $base * { hooks: { PreToolUse: (($base.hooks.PreToolUse // []) + [$new_hook]) } }
  end
')

# 6. Write back valid JSON
echo "$MERGED" | jq '.' > "$SETTINGS_FILE"

# 7. Create mode file if it doesn't exist
mkdir -p "$PROJECT_ROOT/.bocek"
if [ ! -f "$PROJECT_ROOT/.bocek/mode" ]; then
  echo "idle" > "$PROJECT_ROOT/.bocek/mode"
fi

# 8. Ensure gitignore covers settings.local.json
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  grep -q "settings.local.json" "$PROJECT_ROOT/.gitignore" || echo ".claude/settings.local.json" >> "$PROJECT_ROOT/.gitignore"
fi

echo "bocek: hooks registered. Next Claude Code session will pick them up."
echo "bocek: mode set to idle. Load a primitive to begin."
```

**`bocek off`**

```bash
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.local.json"

# Exit if no settings file
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "bocek: no settings.local.json found. Nothing to remove."
  exit 0
fi

# Backup before modifying
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bocek-backup"

# Remove Bocek hook entry, preserve everything else
CLEANED=$(cat "$SETTINGS_FILE" | jq '
  if .hooks.PreToolUse then
    .hooks.PreToolUse |= map(select(.hooks[0].command != "~/.bocek/scripts/enforce-mode.sh"))
    | if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end
    | if (.hooks | length) == 0 then del(.hooks) else . end
  else . end
')

# If result is empty object, delete the file
if [ "$(echo "$CLEANED" | jq 'length')" -eq 0 ]; then
  rm "$SETTINGS_FILE"
  echo "bocek: hooks removed. settings.local.json deleted (was empty)."
else
  echo "$CLEANED" | jq '.' > "$SETTINGS_FILE"
  echo "bocek: hooks removed. Other settings preserved."
fi
```

**`bocek status`**

```bash
echo "=== Bocek Status ==="

# Check hook registration
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.local.json"
if [ -f "$SETTINGS_FILE" ] && jq -e '.hooks.PreToolUse[] | select(.hooks[0].command == "~/.bocek/scripts/enforce-mode.sh")' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "Hooks: registered"
else
  echo "Hooks: not registered (run 'bocek on')"
fi

# Check current mode
MODE_FILE="$PROJECT_ROOT/.bocek/mode"
if [ -f "$MODE_FILE" ]; then
  echo "Mode: $(cat "$MODE_FILE")"
else
  echo "Mode: no mode file"
fi

# Check vault state
VAULT_DIR="$PROJECT_ROOT/.bocek/vault"
if [ -d "$VAULT_DIR" ]; then
  ENTRY_COUNT=$(find "$VAULT_DIR" -name "*.md" -not -path "*/.compiled/*" | wc -l)
  echo "Vault: $ENTRY_COUNT entries"
  if [ -f "$VAULT_DIR/index.md" ]; then
    VERSION=$(grep "vault_version" "$VAULT_DIR/index.md" | head -1 | grep -o "[0-9]*")
    echo "Vault version: ${VERSION:-unknown}"
  fi
else
  echo "Vault: not initialized"
fi

# Check primitives
PRIMITIVES_DIR="$HOME/.bocek/primitives"
if [ -d "$PRIMITIVES_DIR" ]; then
  PRIM_COUNT=$(find "$PRIMITIVES_DIR" -maxdepth 1 -name "*.md" | wc -l)
  echo "Primitives: $PRIM_COUNT installed at $PRIMITIVES_DIR"
else
  echo "Primitives: not installed (run 'bocek update' or reinstall)"
fi
```

**`bocek update`**

```bash
PRIMITIVES_DIR="$HOME/.bocek/primitives"

if [ ! -d "$PRIMITIVES_DIR/.git" ]; then
  echo "bocek: primitives directory is not a git repo. Reinstall bocek."
  exit 1
fi

cd "$PRIMITIVES_DIR"
git pull --ff-only 2>&1

if [ $? -eq 0 ]; then
  echo "bocek: primitives updated."
else
  echo "bocek: update failed. Check network and try again."
  exit 1
fi
```

### Project root detection

The toggle script needs to find the project root. Strategy:

1. Walk up from `$PWD` looking for `.git/`
2. If found, that's the project root
3. If not found, use `$PWD`

This matches how Claude Code discovers project settings.

### What `bocek on` does NOT do

- Does NOT create vault structure — the primitives create `.bocek/vault/` when first needed
- Does NOT load primitives — the human tells Claude to read a primitive
- Does NOT start a Claude Code session — the user does that
- Does NOT modify project settings.json — only settings.local.json (personal, gitignored)

### Installation location

The `bocek` script installs to `~/.local/bin/bocek` (or equivalent PATH location). The enforcement script installs to `~/.bocek/scripts/enforce-mode.sh`. Both are set executable during installation.

### Error handling

Every JSON write is validated before it replaces the file:

```bash
# Validate before writing
if echo "$MERGED" | jq '.' > /dev/null 2>&1; then
  echo "$MERGED" | jq '.' > "$SETTINGS_FILE"
else
  echo "bocek: ERROR — generated invalid JSON. Settings not modified."
  echo "bocek: backup preserved at ${SETTINGS_FILE}.bocek-backup"
  exit 1
fi
```

If validation fails, the original file is untouched and the backup is preserved.

## Trade-offs

**jq dependency vs safety:** `jq` is the only dependency Bocek has beyond bash. Accepted because the alternative (sed/awk JSON manipulation) risks breaking the user's Claude Code setup. The cost of installing `jq` is trivial compared to the cost of corrupted settings.

**Backup on every toggle:** Creates a backup file on every `bocek on` and `bocek off`. This means the backup always reflects the state before the last toggle, not the original state. Accepted because a single backup is simpler than a backup chain, and the most common recovery scenario is "undo the last toggle."

**Idempotency check by command string:** The script detects existing Bocek hooks by matching the command string `~/.bocek/scripts/enforce-mode.sh`. If the user manually changes this path, the idempotency check fails and the hook gets duplicated. Accepted because manual modification of the hook entry is an edge case, and duplicated hooks are deduplicated by Claude Code.

## Prior Art
- Claude Code settings documentation: https://code.claude.com/docs/en/settings
- Claude Code hooks guide: https://code.claude.com/docs/en/hooks-guide
- OpenCode permission system: `/home/mvula/audhd/opencode/packages/opencode/src/permission/`

## References
- ADR-0018: Three-layer defense with Bash interception
- ADR-0019: Toggle uses jq with backup
