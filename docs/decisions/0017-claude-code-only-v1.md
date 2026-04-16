# ADR-0017: Claude Code Only for V1

## Status
Accepted

## Context
The original design document raised multi-agent compatibility as an open question — whether the vault format and primitives should be portable to Cursor, Codex, Gemini CLI, OpenCode, and other AI coding tools.

## Decision
V1 targets Claude Code exclusively. No portability considerations, no abstraction layers for other tools, no testing against other runtimes.

## Alternatives Considered
**Design for portability from the start:** Would require abstracting hooks, primitives, and vault interactions across different tool APIs. Rejected because it adds complexity to every decision without a user to serve — the builder uses Claude Code.

## Consequences
- **Positive**: Every design decision can leverage Claude Code's specific capabilities (hooks, settings.local.json, commands, tool names) without abstraction
- **Positive**: Simpler implementation — no compatibility layers
- **Negative**: Porting to other tools later may require rework — but the vault format (markdown + frontmatter) is inherently portable, and primitives are just markdown files

## Revisit When
- If there's demand from users on other tools
- If a second tool gains Claude Code's hook enforcement capability
