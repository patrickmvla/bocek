# ADR-0015: Reference Files Include Concrete Code Block Examples

## Status
Accepted

## Context
Anthropic's prompting research states "examples are the 'pictures' worth a thousand words" and recommends 3-5 examples for best results. LLMs follow behavioral patterns more reliably when shown demonstrated behavior (few-shot) than when given abstract prose instructions.

Initial reference file designs were prose-based — describing what the model should do in words. This works for high-level behavioral contracts (the core) but is insufficient for detailed technique references where the model needs to know exactly what correct execution looks like.

## Decision
All reference files across all six primitives include concrete code block examples demonstrating the exact behavior expected. Not abstract instructions about what to do, but actual demonstrated patterns the model can match against.

Each reference shows the full cycle of correct behavior — input state, action taken, output produced, edge case handled — with real code blocks in the project's tech stack where applicable.

This applies to all primitives:
- Design: example of attacking a recommendation, example of concreteness enforcement
- Research: example of source evaluation, example of a conflicts section
- Implementation: example of contract-following with quote→implement→verify→flag cycle
- Debugging: example of hypothesis formation and trace
- Refactoring: example of contract-preserving restructure
- Review: example of drift detection with vault citation

## Alternatives Considered
**Prose-only references:** Describe behaviors in words. Rejected because LLMs pattern-match against examples more reliably than they follow abstract instructions. Prose tells the model what to do; examples show what correct looks like.

**Examples in core only:** Would push the core beyond the 800-2,000 token budget. Examples are detailed and belong in references that load just-in-time at the high-attention end of context.

## Consequences
- **Positive**: Model's probability distribution shifts toward demonstrated patterns — most powerful steering mechanism available
- **Positive**: References become the system's most powerful component — curated, tested, evolving patterns
- **Positive**: Few-shot examples are permanent and on disk, not throwaway prompt snippets
- **Positive**: Examples can be iterated and improved based on real usage
- **Negative**: Reference files are larger — more content to write and maintain
- **Negative**: Examples must be kept current with vault format changes and tech stack evolution

## Revisit When
- If reference files become too large for effective just-in-time loading (measure token cost)
- If the model reliably follows prose instructions without examples on future model versions
