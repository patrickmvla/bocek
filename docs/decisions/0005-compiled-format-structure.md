# ADR-0005: Compiled Format Uses Structured Markdown, Not Token-Dense Compression

## Status
Accepted

## Context
ADR-0004 established that the machine format is a compiled artifact generated from human vault files. The question remained: what does the compiled format actually look like? Initial direction was maximally token-dense — no prose, imperative constraints, telegraphic notation.

Research across three production systems revealed a consistent pattern:

**Anthropic's official docs**: Recommend XML tags for system-level API formatting, structured sections with clear headers for content.

**Cline (production Claude tool, TypeScript)**: Uses plain text with ALL CAPS section headers separated by `====`. Does NOT use XML for context presentation — XML is reserved for tool invocation formatting only. Context reaches the model via tool results (file reads), not system prompts.

**Vercel's agent-skills (320k+ installs, close Anthropic partnership)**: Uses a two-layer architecture:
- Individual rule files (source) → compiled AGENTS.md (build output)
- AGENTS.md is explicitly labeled "mainly for agents and LLMs"
- Format is well-structured markdown with full prose explanations, code examples, impact ratings, and table of contents
- NOT token-dense — Vercel's bet is that models reason better from clear explanations than compressed formats

Key insight: vault content reaches the model through file reads (tool results), not system prompts. The formatting that matters is what works best inside tool results. All three production systems converge on structured markdown, not XML or compressed notation.

## Decision
The compiled format will use clear, well-structured markdown optimized for navigability and clarity, not token density. Each compiled file will contain:

1. Header with feature name, compilation date, source count
2. Table of contents linking to sections
3. Constraints section — each constraint with brief rationale and source attribution
4. Contracts section — full type signatures, API shapes, state machines with source attribution
5. Dependencies section — cross-feature requirements with context and source attribution
6. Consistent heading hierarchy throughout

The format follows Vercel's proven pattern: compile many individual source files into one navigable document with consistent formatting, clear hierarchy, and prioritization.

## Alternatives Considered
**Token-dense compressed format (imperative constraints, no prose):** Initial direction. Rejected after research showed production systems optimizing for clarity over density. Models reason better from clear explanations than telegraphic notation.

**XML-structured format:** Based on Anthropic's API docs. Rejected because vault content reaches the model via tool results (file reads), not system prompts. Cline and Vercel both use plain markdown for tool-result-level context, not XML.

**JSON/YAML structured data:** Anthropic recommends JSON for state tracking data. Not appropriate for design decisions and contracts, which are better expressed in prose + code notation.

## Consequences
- **Positive**: Format is grounded in what production systems actually use, not theoretical optimization
- **Positive**: Compiled files are readable by humans too — useful for debugging and review
- **Positive**: Consistent with Vercel's approach (close Anthropic partnership, presumably well-tested)
- **Negative**: Larger token footprint than maximally compressed format — but evidence suggests this produces better model reasoning
- **Negative**: Format decisions based on current model behavior may need revisiting as models evolve

## Revisit When
- If future Claude models show measurably different attention patterns for compressed vs. prose formats
- If vault sizes grow large enough that token cost becomes a practical bottleneck despite per-feature scoping
- If Anthropic publishes specific guidance for tool-result-level formatting (distinct from system prompt guidance)

## References
- Vercel agent-skills: github.com/vercel-labs/agent-skills (AGENTS.md pattern)
- Cline source: github.com/cline/cline (system prompt components)
- Anthropic prompting best practices: platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering
