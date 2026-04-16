# ADR-0018: Three-Layer Defense with Bash Interception

## Status
Accepted

## Context
The model actively circumvents Edit/Write hooks by falling back to Bash with `python -c`, `sed -i`, or shell redirects. This is documented in anthropics/claude-code#29709 (closed as "not planned") — Anthropic considers this by-design behavior.

A hook matching only Edit/Write provides zero enforcement in practice. The model discovers the Bash workaround within 3 blocked attempts.

OpenCode's approach (AST-based bash parsing with tree-sitter) is the most sophisticated in the ecosystem but requires Node.js/Python dependencies. Bocek's zero-dependency philosophy requires a simpler approach.

## Decision
Bocek uses a three-layer defense model:

**Layer 1 — Hook enforcement (zero tokens, non-bypassable):**
- Single PreToolUse hook matching `Edit|Write|Bash`
- Edit/Write: check file path, allow `.bocek/`, deny all else in reasoning modes
- Bash: regex detection of file-modifying patterns (redirects, sed -i, tee, cp, mv, rm, python -c, perl -e, etc.)
- `permissionDecision: "deny"` with clear message guiding the model to correct behavior
- Non-bypassable even in bypassPermissions mode

**Layer 2 — Primitive instructions (in-context, degrades over time):**
- The primitive tells the model what it can and can't do
- Effective when attention is strong, degrades in long sessions
- Catches anything the hook's regex misses

**Layer 3 — Session restart (human decision):**
- When both layers fail, context degradation has gone too far
- The vault has everything — restart is cheap
- Human must recognize degradation, which is the weakest link

## Alternatives Considered
**Edit/Write only:** Trivially bypassed. Rejected based on filed issue evidence.

**Block all Bash in reasoning modes:** Too aggressive — model needs Bash for git, gh api, ls, cat in design and research modes.

**AST parsing (OpenCode approach):** Most accurate but requires tree-sitter dependency. Violates zero-dependency philosophy.

**Accept 95% without Bash interception:** Model actively seeks Bash workarounds — this isn't a theoretical risk.

## Consequences
- **Positive**: Catches 95%+ of mode violations including the documented Bash bypass
- **Positive**: Zero tokens, zero dependencies, non-bypassable
- **Positive**: Clear denial messages redirect the model instead of confusing it
- **Negative**: Regex can produce false positives on edge cases — but the model can rephrase
- **Negative**: Novel bypass patterns not in the regex set won't be caught — layer 2 covers the gap
- **Negative**: Requires jq for JSON parsing — but jq is nearly universal on developer machines

## References
- anthropics/claude-code#29709: Bash bypass documentation
- OpenCode bash.ts: AST-based approach with tree-sitter
- Claude Code hooks guide: PreToolUse enforcement capabilities
