# ADR-0016: Mental Models as Domain Activators, Not Reasoning Scripts

## Status
Accepted

## Context
Mental models are one of Bocek's rarest capabilities in the ecosystem (only BMAD and Superpowers attempt them). The initial approach was to encode step-by-step thinking patterns — "trace the request lifecycle, ask these five questions at each boundary." This mirrors how checklists work, not how senior engineers think.

Research revealed critical findings:

**MeMo paper (arxiv 2402.18252):** LLMs autonomously select and apply mental models when given domain naming + worked examples. The key mechanism is **retrieval cues** — naming a domain ("financial analysis", "geographical knowledge") activates pre-trained knowledge in that area. Performance improved 4-13% across domains. The system doesn't prescribe which model to use; the LLM makes context-dependent selections.

**Vocabulary research (arxiv 2505.17037):** Overly specific vocabulary **degrades** reasoning. Verb specificity especially hurts — telling the model exactly HOW to reason disrupts logical reasoning chains. The sweet spot is balanced terminology that activates the right knowledge area without constraining reasoning.

**Multi-dimensional reasoning (HuggingFace):** The most effective activation creates **productive dissonance** — multiple perspectives that force internal debate before synthesis. A single prescribed perspective narrows reasoning; competing tensions widen it.

A file that says "think like this" (prescribed steps, specific verbs) cripples the model's next-token reasoning. A file that says "think in these lines" (domain naming, key tensions, hard-won knowledge) activates latent knowledge without constraining it.

## Decision
Mental models are domain-specific activators, not reasoning scripts. Each mental model file contains:

1. **Domain naming** — tell the model what domain this is (activates relevant training data)
2. **Key tensions** — the tradeoffs that define this domain (creates productive dissonance)
3. **What gets missed** — hard-won insights that the model's training data has but won't surface by default (shifts probability toward low-default but high-value reasoning)
4. **When this went wrong** — concrete examples of decisions going wrong (activation cues sourced during research primitive sessions, not fabricated)

Mental model files contain NO:
- Step-by-step reasoning processes
- Checklists of things to consider
- Prescribed analysis templates
- Specific instructions on how to think
- Generic "best practices"

Mental models are loaded on demand by any primitive when the conversation enters a specific domain. They are reference files, not core instructions.

## Alternatives Considered
**Step-by-step thinking patterns ("trace the request lifecycle, ask five questions at each boundary"):** The initial approach. Rejected because it constrains the model into a prescribed reasoning process. The vocabulary research shows that telling the model HOW to reason (verb specificity) degrades performance. Senior engineers don't follow scripts — they have internalized domain tensions that fire automatically based on context.

**Generic frameworks applied across all domains ("decompose → options → recommend"):** What Microsoft Amplifier does with zen-architect. Rejected because database design and frontend architecture require fundamentally different reasoning. A generic framework treats all domains the same, which is the training-data default Bocek exists to override.

**No mental models — rely on the model's inherent knowledge:** The model already knows about database access patterns, but it won't activate that knowledge unless something shifts the probability distribution. The MeMo research shows 4-13% improvement from mental model activation. Doing nothing leaves performance on the table.

## Consequences
- **Positive**: Activates latent knowledge without constraining reasoning — the model's full training data is available, just focused
- **Positive**: Domain-specific tensions create productive dissonance — the model reasons about tradeoffs, not follows instructions
- **Positive**: Mental models work across all six primitives — the same data-layer activator helps design, implementation, debugging, and review differently depending on the primitive's intent
- **Positive**: Library grows organically — new mental models are added as new domains become relevant
- **Negative**: Harder to write than checklists — capturing domain tensions requires deep engineering knowledge
- **Negative**: Effectiveness depends on the model's training data quality for each domain — less-represented domains may not activate as strongly
- **Negative**: "When this went wrong" examples need to be sourced from real engineering (research primitive), not fabricated

## References
- MeMo: "Towards Generalist Prompting for Large Language Models by Mental Models" — https://arxiv.org/abs/2402.18252
- "Prompt Engineering: How Prompt Vocabulary affects Domain Knowledge" — https://arxiv.org/abs/2505.17037
- "Eliciting Reasoning in Language Models with Cognitive Tools" — https://www.matrig.net/publications/articles/ebouky2025.pdf
- Multi-Dimensional Reasoning Prompts — https://discuss.huggingface.co/t/make-your-llm-think-differently-multi-dimensional-reasoning-prompts/159175
- Microsoft Amplifier zen-architect — https://github.com/microsoft/amplifier-foundation
