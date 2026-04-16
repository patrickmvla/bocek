# Context Engineering: Design

## Context
Every architectural decision in Bocek is a context engineering decision. The primitives, the vault, the compilation format, the hook layer, the mode system — all exist to control what tokens are in the model's context window and when. This document captures the research findings that inform these decisions.

## Goals
- Ground all primitive and vault design decisions in current research, not assumptions
- Establish the constraints that context rot, position bias, and attention budgets impose
- Define patterns for instruction persistence across long sessions

## Non-Goals
- Not a general context engineering tutorial — only findings that impact Bocek's design
- Not a model comparison — findings are about patterns that hold across models, not model-specific behaviors

## Design

### The attention budget model

LLMs have a finite attention budget. Every token in context depletes it. The transformer architecture requires every token to attend to every other token — n² pairwise relationships for n tokens. As context grows, the model's ability to capture these relationships stretches thin.

This means context is not free storage. Every token Bocek puts in context has an opportunity cost — it dilutes attention on everything else. This is the foundation of the "intentional context tax" philosophy.

### Context rot

Research (Chroma, 18 frontier models including Claude Opus 4, GPT-4.1, Gemini 2.5):
- Every model degrades as input grows
- Degradation is not gradual — models hold steady then nosedive past a threshold
- Some models: 95% accuracy → 60% accuracy once a critical length is crossed
- Claude models show lowest hallucination rates and conservative abstention under uncertainty
- Significant degradation observed at ~2,500+ words of distractor content
- Accuracy at 15,000 words remains high (98-99%) but latency explodes (7x baseline)

**Bocek implication:** Sessions will accumulate context. The vault, the conversation history, the tool results — they all grow. The primitive's behavioral instructions must survive this growth. This drives the two-layer primitive architecture (ADR-0011).

### Position bias ("lost in the middle")

Models attend most strongly to the beginning and end of context. Information in the middle loses up to 30% accuracy compared to beginning or end.

This is structural — caused by Rotary Position Embedding (RoPE), not a training artifact. It won't be fixed by better training.

**Bocek implications:**
- Primitive core loads at session start → beginning of context → highest attention zone
- Reference files load just-in-time via tool calls → enter at the end of context → high attention zone
- Vault compiled files load just-in-time → same benefit
- Conversation history accumulates in the middle → lowest attention zone → this is where old tool results and resolved discussions correctly lose attention

### The structure paradox

Chroma found that models perform worse when the haystack preserves logical flow of ideas. Shuffled, incoherent haystacks paradoxically improve performance. Structural coherence makes distractors more convincing.

**Bocek implication:** The compiled vault format uses clear section headers and delimiters to help the model distinguish vault content from conversation history. The sections should be self-contained, not flowing prose that blends with surrounding context.

### Six competing layers

All context is composed of six competing information types (ByteByteGo):
1. System instructions (primitive core)
2. User input (human's questions and decisions)
3. Conversation history (accumulated exchanges)
4. Retrieved knowledge (vault files, cloned code)
5. Tool descriptions (Claude Code's tool definitions)
6. Tool outputs (file reads, command results)

Bocek controls layers 1 (primitive), 3 (session restart via vault), and 4 (scoped vault reads). It cannot control 2, 5, or 6.

### Anthropic's recommended patterns

From their engineering blog on context engineering for agents:

**Prompt size:** Well-specified agent prompts are 800-2,000 tokens. This is the size that persists through long sessions.

**The "right altitude":** Prompts must be specific enough to guide behavior, flexible enough to provide strong heuristics. Not brittle step-by-step scripts. Not vague platitudes.

**Compaction:** Summarize and restart when context fills. Claude Code triggers at 95% capacity, preserving architectural decisions, unresolved bugs, and implementation details while discarding redundant tool outputs.

**Structured note-taking:** Write to files outside the context window. Pull back in when needed. This IS the vault pattern.

**Sub-agents:** Specialized sub-agents with clean context windows for focused tasks. Each explores extensively but returns only 1,000-2,000 token summaries.

**Tool result clearing:** Remove raw tool outputs deep in message history. Once a tool has been called deep in history, the agent doesn't need the raw result again.

**Just-in-time retrieval:** Maintain lightweight identifiers (file paths, queries) and load data at runtime. "Progressive disclosure — agents incrementally discover relevant context through exploration."

### Big vs small prompts (Red Hat experiments)

Actual experimental data with AI agents:
- Big prompts: 630K input tokens across 154 API calls
- Small prompts: 180K input tokens across 326 API calls
- Big prompts cost 3.5x more tokens but make 2x fewer calls
- Small models fail with big prompts entirely
- Big prompts cause scope creep without extensive negative instructions

**Bocek implication:** The primitive core must be small enough to avoid scope creep and attention dilution, but comprehensive enough that the model doesn't fall back to default behavior. The two-layer architecture (small core + on-demand references) threads this needle.

## Trade-offs

**Token efficiency vs instruction depth:** The core primitive is constrained to 800-2,000 tokens. This means it can't encode every behavioral nuance — some patterns must live in references and be consulted on demand. The risk: if the model doesn't consult references when needed, it loses the nuanced behaviors.

**Session length vs instruction persistence:** Longer sessions degrade instruction following. Bocek's answer is compaction (restart with vault state) rather than fighting degradation. But this means the human must recognize when to restart — the model's degrading judgment can't be trusted to flag its own degradation.

**Structure vs attention:** Clear structure helps humans read the vault but paradoxically makes it harder for models to distinguish from distractors. Self-contained sections with clear delimiters mitigate this.

## References
- Anthropic: "Effective context engineering for AI agents" — https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Chroma: "Context Rot" — https://www.trychroma.com/research/context-rot
- ByteByteGo: "A guide to context engineering for LLMs" — https://blog.bytebytego.com/p/a-guide-to-context-engineering-for
- Red Hat: "Big vs small prompts for AI agents" — https://developers.redhat.com/articles/2026/02/23/prompt-engineering-big-vs-small-prompts-ai-agents
- "Lost in the Middle: How Language Models Use Long Contexts" — position bias research
- arXiv 2601.11564: "Context Discipline and Performance Correlation"
- arXiv 2510.04618: "Agentic Context Engineering" (ACE framework)
