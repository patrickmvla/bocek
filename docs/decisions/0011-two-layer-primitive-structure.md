# ADR-0011: Two-Layer Primitive Structure (Dense Core + On-Demand References)

## Status
Accepted

## Context
Research into context engineering revealed several findings that directly impact primitive design:

1. **Anthropic recommends 800-2,000 tokens for well-specified agent prompts.** Our initial target of 5,000-8,000 words (~7,000-10,000 tokens) is 4-10x larger.

2. **"Lost in the middle" problem.** Models attend strongly to beginning and end of context, poorly to everything between. Instructions stated once at the beginning lose attention as conversation accumulates. Accuracy drops 30%+ for middle-positioned information.

3. **Context rot is real.** Every model degrades as context grows (Chroma, 18 models tested). Some hold at 95% then nosedive to 60% past a threshold.

4. **Anthropic's own pattern in Claude Code.** Small CLAUDE.md files loaded upfront + just-in-time file retrieval via tools. This is the proven production architecture.

5. **Big prompts work but cost 3.5x more input tokens** (Red Hat experiments). Small models fail with big prompts entirely.

A monolithic 8,000-word primitive would load all behavioral instructions at once, competing with conversation history as the session grows. The adversarial patterns (self-attack, calibration, meta-analysis, concreteness enforcement) would degrade precisely when they're needed most — deep into complex design sessions.

## Decision
Each primitive has two layers:

**Core** (800-2,000 tokens): Loads at session start. Encodes the fundamental behavioral contract — what the mode IS, how decisions work, the calibration table, and explicit instructions to read reference files for detailed patterns. Dense, forceful, designed to survive attention degradation. Lives at `~/.bocek/primitives/design.md`.

**References** (loaded on demand): Detailed behavioral patterns, mental models, vault-write formats, example interactions. The core tells the model to read these when needed. They load via tool calls (file reads), entering context just-in-time at the high-attention end of the conversation. Live at `~/.bocek/primitives/references/`.

This mirrors Anthropic's own architecture: small instructions upfront, detailed knowledge retrieved just-in-time.

## Alternatives Considered
**Monolithic primitive (one large file):** Original approach. 5,000-8,000 words loaded at once. Rejected because it exceeds Anthropic's recommended prompt size by 4-10x, and the "lost in the middle" problem means behavioral instructions deep in the file lose attention as conversation grows. The adversarial patterns would degrade precisely when most needed.

**Many small files with no core:** Fully decomposed, everything loaded just-in-time. Rejected because the model needs a persistent behavioral contract that stays in the high-attention zone (beginning of context). Without a core, the model has no anchor and falls back to default helpful behavior.

## Consequences
- **Positive**: Core stays in the highest-attention zone (beginning of context) throughout the session
- **Positive**: References load at the high-attention end (most recent context) when consulted
- **Positive**: Aligned with Anthropic's recommended prompt size and their production architecture
- **Positive**: References can be updated independently of the core — more modular maintenance
- **Negative**: The model must actively read reference files — if the core's instructions to do so degrade, it won't consult them
- **Negative**: Two things to maintain per primitive instead of one — but the modularity makes each piece simpler

## Revisit When
- If future models show significantly different attention patterns (e.g., uniform attention across context)
- If the core's instructions to read references consistently degrade in long sessions — may need reinforcement hooks
- If Anthropic's recommended prompt size changes significantly

## References
- Anthropic: "Effective context engineering for AI agents" — https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Chroma: "Context Rot" research — https://www.trychroma.com/research/context-rot
- Red Hat: "Big vs small prompts for AI agents" — https://developers.redhat.com/articles/2026/02/23/prompt-engineering-big-vs-small-prompts-ai-agents
- ByteByteGo: "A guide to context engineering for LLMs" — https://blog.bytebytego.com/p/a-guide-to-context-engineering-for
- "Lost in the Middle" position bias research
