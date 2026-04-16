# ADR-0019: Toggle Script Uses jq with Backup for JSON Manipulation

## Status
Accepted

## Context
The `bocek on/off` toggle must add and remove hook entries from `.claude/settings.local.json`. This file may contain other settings from the user or other tools. Malformed JSON breaks Claude Code's settings loading entirely — not just Bocek, everything.

Research into Claude Code's settings behavior revealed:
- Hooks merge across scopes (concatenated and deduplicated, not replaced)
- Settings.local.json is auto-gitignored by Claude Code when it creates the file
- File watcher picks up changes automatically — no session restart needed
- Malformed JSON is reported by `/status` but may break settings loading

The JSON manipulation is the highest-risk operation in the entire toggle script. Alternatives: sed/awk (fragile, can produce invalid JSON), Python (dependency), Node.js (dependency), jq (purpose-built for JSON, near-universal on developer machines).

## Decision
The toggle script uses `jq` for all JSON manipulation and fails explicitly if `jq` is not installed. No sed/awk JSON hacking. No Python/Node fallback. If the user doesn't have `jq`, the script tells them to install it.

Before every write, the script creates a backup at `.claude/settings.local.json.bocek-backup`. If the write fails or produces invalid JSON, the user can restore from backup.

**`bocek on`:**
1. Check `jq` is installed — fail with install instructions if not
2. Read `.claude/settings.local.json` or default to `{}`
3. Backup existing file to `.claude/settings.local.json.bocek-backup`
4. Merge Bocek hook entry via `jq` (idempotent — won't duplicate if already present)
5. Write back valid JSON
6. Create `.bocek/mode` set to `idle` if it doesn't exist
7. Ensure `.claude/settings.local.json` is gitignored

**`bocek off`:**
1. Read `.claude/settings.local.json` — exit if doesn't exist
2. Backup existing file
3. Remove only the Bocek hook entry via `jq` — preserve all other settings
4. If hooks object is now empty, remove it
5. If entire file is now `{}`, delete the file
6. Do NOT touch `.bocek/mode` or vault — those persist independently

## Alternatives Considered
**sed/awk for JSON editing:** Fragile, cannot handle nested JSON reliably, can produce invalid JSON. Rejected — the risk of breaking the user's Claude Code setup is unacceptable.

**Python fallback:** Would provide `json` module for safe manipulation. Rejected — Bocek's zero-dependency philosophy. Python may not be installed or may be the wrong version.

**Node.js with `JSON.parse/stringify`:** Same issue — Node dependency.

**Write the entire file from scratch on `bocek on`:** Would lose any existing non-Bocek settings. Rejected — destructive.

**No backup:** The backup costs one file copy and provides a recovery path if anything goes wrong. No reason to skip it.

## Consequences
- **Positive**: `jq` is purpose-built for JSON — safe, correct, handles edge cases
- **Positive**: Backup provides recovery path for any failure
- **Positive**: Idempotent — running `bocek on` twice is safe
- **Positive**: Non-destructive — `bocek off` only removes Bocek's entries
- **Negative**: Requires `jq` — but `jq` is available via `brew install jq`, `apt install jq`, and is pre-installed on many developer systems
- **Negative**: One additional dependency beyond pure bash — but it's the right tool for the job and the alternative (fragile JSON manipulation) is unacceptable

## Revisit When
- If `jq` proves to be a real installation barrier for users (unlikely for the target audience)
- If Claude Code adds a CLI for programmatic settings manipulation (would replace the need for direct JSON editing)
