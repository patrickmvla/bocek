# ADR-0012: Core vs Reference Content Split for Primitives

## Status
Accepted

## Context
ADR-0011 established the two-layer primitive structure. This decision defines what content belongs in each layer. The split must be informed by context engineering research: the core sits in the highest-attention zone (beginning of context) and must survive attention degradation. References load just-in-time at the high-attention end when consulted.

The architecture mirrors Vercel's proven skill pattern (SKILL.md core + individual rule files as references), arrived at independently through context engineering research.

## Decision

### Core (800-2,000 tokens, persistent, beginning of context)
The behavioral contract that never gets forgotten:
- What this mode IS — one paragraph identity
- The decision-under-pressure mechanism — the fundamental interaction loop
- Response calibration table (sound reasoning → accept; confident-but-wrong → attack; no reasoning → refuse; impatience → push harder; honest uncertainty → help)
- Explicit instructions to read specific reference files for detailed patterns
- Vault write trigger — when and how to write decisions
- Tool constraints — what the model cannot touch in this mode

### References (loaded on demand, just-in-time at high-attention end)
Detailed techniques the model consults when needed:
- Self-attack protocol
- Pattern meta-analysis (tracking human decision biases)
- Concreteness enforcement (decomposing abstract decisions)
- Mental model library (trace read/write paths, map failure modes, etc.)
- Vault entry format (frontmatter, structure, content requirements)
- Example interactions demonstrating the adversarial pattern

### Principle
The core tells the model WHAT it is and HOW to calibrate. The references tell it the DETAILED TECHNIQUES for each behavior.

## Alternatives Considered
**Everything in core:** Would exceed Anthropic's recommended 800-2,000 token prompt size. Behavioral details deep in a large core file would fall into the low-attention middle zone as conversation grows.

**Everything in references, minimal core:** The model needs a persistent anchor. Without a strong core, it falls back to default helpful behavior. The calibration table especially must persist — it's what makes the model adversarial instead of accommodating.

**Dynamic core that changes mid-session:** Over-engineering. The core is a stable contract. What changes is which references the model consults.

## Consequences
- **Positive**: Core stays in highest-attention zone, references arrive fresh at high-attention end
- **Positive**: Mirrors the Vercel skill architecture validated at 320K+ installs
- **Positive**: Each reference can be developed, tested, and iterated independently
- **Positive**: Mental model library can grow over time without changing the core
- **Negative**: The model must reliably consult references when the core instructs it to — if this instruction degrades, detailed behaviors are lost
- **Negative**: More files to maintain — but each file is simpler and more focused

## Revisit When
- If the model consistently fails to consult references when instructed — may need reinforcement via hooks or vault state
- If specific reference patterns prove unnecessary in practice — prune them
