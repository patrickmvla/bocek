# ADR-0001: Dual-Format Vault (Human-Readable + Machine-Readable)

## Status
Accepted

## Context
Bocek's vault is the central data structure that every primitive reads from or writes to. It needs to serve two audiences: humans navigating design decisions (reading, reviewing in PRs, understanding rationale months later) and LLMs loading context before implementation (where token efficiency directly impacts reasoning quality).

Karpathy's LLM Wiki demonstrates that a single well-structured markdown format with an index/navigation layer works at the 50-200 source scale. However, Bocek vaults can grow significantly larger — a complex project could have hundreds of decisions across dozens of features. At that scale, the token cost of prose-format vault entries matters when the model needs to load relevant context before implementing.

## Decision
We will maintain two representations of vault knowledge: a human-readable format (Obsidian-style markdown with wikilinks and prose) and a machine-readable format (token-dense, structured, parseable). The system will manage bidirectional sync between them.

## Alternatives Considered
**Single format (Karpathy-style structured markdown):** Simpler, no sync problem, proven at research-wiki scale. Rejected because Bocek vaults will grow larger than research wikis, and the token cost of loading prose-format decisions before implementation degrades model reasoning quality. The scale difference makes the single-format approach insufficient.

## Consequences
- **Positive**: LLM gets maximally dense context when implementing — better reasoning per token
- **Positive**: Humans get navigable, readable documentation they can browse in Obsidian or on GitHub
- **Negative**: Bidirectional sync is a real engineering problem — must be solved reliably or the formats drift
- **Negative**: Two formats means two things to maintain, test, and version

## Revisit When
- If prototyping shows the machine format doesn't measurably improve LLM reasoning compared to well-structured markdown
- If the sync mechanism proves too fragile or complex to maintain reliably
- If vault sizes in practice stay small enough that token cost is negligible

## References
- Karpathy's LLM Wiki pattern: https://blog.starmorph.com/blog/karpathy-llm-wiki-knowledge-base-guide
- BMAD Method source code review (uses markdown throughout, no LLM-optimized format)
