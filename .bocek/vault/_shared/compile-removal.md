---
type: decision
features: [_shared]
related: ["[[discovery-compile-instruction-lacks-output-path]]", "[[compile-step-rent-research]]", "[[vault-scale-audit-bokchoy]]", "[[mandatory-feature-folders]]", "[[research-subfolder]]"]
created: 2026-05-14
confidence: high
---

# Remove `.compiled/` from bocek's vault architecture; `/implementation` reads vault entries directly

## Decision

Bocek removes `.bocek/vault/.compiled/` as a concept. The implementation primitive reads vault entries directly from `vault/{feature}/*.md` files at write time, selecting which entries to load based on the task at hand. Research entries at `vault/{feature}/.research/*.md` are not loaded by default per `[[research-subfolder]]`; they are read on demand when reasoning requires citing evidence.

Concrete changes the implementation primitive (the source artifact, not a vault entry) must absorb:

- **`primitives/implementation.md:25`** — replace *"the compiled file at `.bocek/vault/.compiled/{feature}.md` if present, otherwise compile it from `.bocek/vault/{feature}/*`"* with direct-read framing: *"the relevant vault entries at `.bocek/vault/{feature}/*.md` — load decisions, contracts, discoveries, and gaps by default; research entries at `.bocek/vault/{feature}/.research/*.md` are read on demand when reasoning cites them (per `[[research-subfolder]]`)."*
- **`primitives/implementation.md:118`** — same replacement: drop *"read the compiled vault entry (`.bocek/vault/.compiled/{feature}.md`; compile from human files if stale)"*; replace with *"read the relevant entries from `.bocek/vault/{feature}/`."*
- **`references/implementation/contract-following.md:8`** — replace *"Pull the exact constraint from the compiled vault or the human vault entry."* with *"Pull the exact constraint from the relevant vault entry."*
- **`references/shared/vault-format.md`** path-convention layout — remove the `.compiled/` line and its annotation `← gitignored, per-feature compiled context`.
- **`.gitignore` in bocek-the-tool's repo** — remove any line listing `.bocek/vault/.compiled/` (verify with `grep`).
- **`bocek bootstrap`'s gitignore-line writing** in `scripts/bocek` — verify the bootstrap process doesn't append `.compiled/` to project gitignores.
- **`scripts/bocek` `cmd_status`** — no current mention of `.compiled/` per the read I did earlier, but verify and remove if present.

Polish #6 in `[[vault-scale-audit-bokchoy]]`'s queue (lazy-compile becomes a script) is resolved **by removal, not by implementation.** Polishes #2, #4, #5 remain on the queue.

## Reasoning

The decision is grounded in `[[compile-step-rent-research]]`, whose four findings converge:

- **F1 (production-cited; high):** Aider — the closest production analog to `.compiled/{feature}.md` in the AI-coding-agent space — explicitly rejects flat concatenation in favor of PageRank-scored dynamic selection within a token budget (default 1k tokens). Their documented rationale: *"adding many irrelevant files will often distract or confuse the LLM, resulting in worse coding results."* Flat compile is the documented anti-pattern.
- **F2 (docs-cited; high):** Anthropic prompt caching auto-caches stable prefixes with break-even after a single cache hit. The exact use case Anthropic names: *"cache the full codebase context so users can ask multiple questions about the code without repeatedly paying to process the entire repository."* The model layer already provides what `.compiled/` was supposed to provide.
- **F3 (production-cited; high):** GitHub Copilot's measurement on token efficiency: *"savings routinely hit 70 to 95%"* when an agent reads files on demand vs. loading everything upfront. Bocek's `/implementation` access pattern is exactly the selective-read pattern this measures.
- **F4 (production-cited within bocek; high):** Bokchoy's existence proof — `/implementation` ran multiple times against features containing 14-39 entries and shipped working code without `.compiled/` ever being written. Empirical evidence that the cache concept is not load-bearing for correctness.

Combined with `[[discovery-compile-instruction-lacks-output-path]]`'s finding that the cache file has never been written by any bocek session in any vault we've audited, the four-channel evidence base supports removal over either prose amendment (Option 1, dominated) or script-driven compile (Option 2, narrowly defensible only in F5's unverified regime).

The contradiction probe in the research entry searched for engineering-grade defense of always-load-full-context and found none. Only vendor marketing pages support flat-cat; every engineering-grade source (GitHub, Augment, multiple independent blogs, Aider's own design rationale) supports selective approaches (production-cited; high).

## Engineering substance applied

- **Operability:** removes a maintenance surface. Less code (no compile script owed), less doctrine (one fewer concept in the primitive prose), less drift (no doctrine-without-enforcement to re-derive — the same failure pattern `[[mandatory-feature-folders]]` and `[[discovery-compile-instruction-lacks-output-path]]` named).
- **Discoverability:** vault layout simplifies. `.bocek/vault/` contains `index.md` + feature folders. No more `.compiled/` dotfile that new contributors have to learn about and that has never actually contained anything in real use.
- **Context budget:** model-layer auto-caching (Anthropic prompt cache, 90% cost reduction on cached input, break-even after 1 hit) handles the re-read efficiency that `.compiled/` was designed to deliver. Bocek doesn't build parallel infrastructure to a thing the platform already provides.
- **Failure semantics:** under direct-read, if a vault entry is malformed or missing, the model surfaces it at read time as a specific error rather than silently producing a degraded compile. Sharper failure mode, easier to diagnose.

## Production-grade gates

- **Idiomatic** — YAGNI applied to dead infrastructure. The standard pattern when an artifact has never been produced in production is to remove the concept, not to add code to produce it (production-cited; high — every codebase audit recommendation in the engineering literature treats "dead infrastructure" the same way).
- **Industry-standard** — Aider's repo-map approach (dynamic selection within a budget, not flat concatenation) is the production-cited reference for "how AI coding agents handle project context." Anthropic's prompt caching is the production-cited reference for "how to amortize stable-prefix re-reads." Both, independently published by major systems, argue against the `.compiled/` shape bocek had documented (production-cited; high).
- **First-class** — uses platform abstractions. Anthropic's automatic prompt caching is the platform's intended mechanism for prefix-cache benefit; selective tool-call reads are the platform's intended mechanism for context budget. Bocek using these instead of building parallel infrastructure means it doesn't fight the platform.

## Rejected alternatives

### Option 1 — Prose amendment to `implementation.md:25`

**What:** Add an explicit write directive to the primitive: *"…synthesize and write the result to `.bocek/vault/.compiled/{feature}.md`."* Keep `.compiled/` as a concept; fix the missing instruction.

**Wins when:** Compile is genuinely valuable infrastructure AND prose enforcement is sufficient AND the team accepts inheriting the doctrine-without-enforcement failure pattern.

**Why not here:** The third condition fails reliably. Bocek has now observed this failure pattern three times (path-convention before `enforce-mode.sh`, `_shared/` discipline before the unimplemented mitigation gate, lazy-compile before this decision). Prose enforcement is empirically insufficient for any rule bocek wants to be load-bearing. Independently, the first condition is unverified per the research entry — compile may not be valuable infrastructure at all.

### Option 2 — Script-driven compile (`bocek vault compile <feature>`)

**What:** Add a subcommand to `scripts/bocek` that walks a feature folder, synthesizes entries into a structured `.compiled/{feature}.md`, and writes to disk. Implementation primitive invokes the script explicitly via Bash. Same enforcement-in-code pattern as `enforce-mode.sh`.

**Wins when:** F5's regime holds — curated synthesis (NOT flat-cat) is materially smaller and better than raw selective reads, AND bocek-using projects have multi-session-per-feature workloads where the artifact's *content* is reused beyond Anthropic's session-scoped 5-minute cache, AND the team accepts the synthesis-format design and maintenance cost.

**Why not here:** F5's conditions are unverified. The research entry's open thread #1 flags that no bocek-using project has been observed with this workload pattern. The synthesis format itself is underspecified — concatenation is rejected per F1, but contracts-only extraction requires markdown parsing logic bocek doesn't yet have a design for. Building the script absent evidence that its output pays rent is premature.

**What would have flipped the decision:** Evidence that any bocek user has the F5 workload (multi-session feature returns, willing to absorb synthesis maintenance). Or evidence that bocek's near-term scope widens to non-Anthropic agents (which would weaken F2's auto-cache argument). Neither was defended in the design session that vaulted this decision.

## Failure mode

**The closed-world Claude-Code-only assumption.** This decision assumes bocek runs against Anthropic-API-backed agents, where prompt caching provides the auto-cache benefit (F2). If bocek's scope widens to non-Anthropic agents (Cursor with arbitrary backend, Aider with local Ollama, Continue with OpenAI), F2 stops applying universally. At that point, having removed `.compiled/` means the cache layer needs to be rebuilt — institutional knowledge of "how should compile work" is the part that's harder to recover after the artifact's gone.

This is real risk but not load-bearing today. Bocek's primitives and README all reference Claude Code explicitly. The deprecated `docs/decisions/0017-claude-code-only-v1.md` (committed-deleted in working tree but historically the project's stance) named Claude Code as v1's scope. Widening is hypothetical, not in any current plan.

Quantitative signal that the failure mode is approaching: if a `mental-models/` entry, idiom file, or primitive starts referencing a non-Anthropic agent, the assumption is shifting and this decision needs re-derivation.

## Mitigations

1. **The decision entry captures the synthesis-design problem so future re-derivation doesn't start from scratch.** If `.compiled/` is reintroduced, the open threads in `[[compile-step-rent-research]]` (synthesis format, contracts-only extraction, parsing logic) are the starting points.
2. **The Revisit-when conditions below are explicit and quantitative.** No ambiguous "when it feels like it" — specific triggers.
3. **Removal is a single bocek release; reintroduction is a script + primitive amendment.** The lock-in tax is low because the reverse migration is straightforward.

## Idiom citations

None. This is a structural decision, not a stack-specific one.

## Revisit when

- **Bocek's scope widens beyond Claude Code / Anthropic API.** Specific signal: a primitive, reference, idiom, or mental model references a non-Anthropic agent. At that point F2 weakens and the cache-vs-no-cache calculation needs to be redone for each target agent.
- **A bocek-using project demonstrably hits F5's workload pattern.** Specific signal: any vault audit (`/review` mode) reports a feature folder where `/implementation` has returned 5+ times to the same feature across distinct sessions AND the user reports that the per-turn context cost feels high. That's the empirical trigger for "synthesis pays rent."
- **A specific synthesis insight emerges** that selective raw-reads cannot replicate — e.g., cross-entry dependency graphs, deduplication across research+decision pairs, contract-only extraction with reasoning stripped. If such an insight can be named concretely and tied to a measurable improvement, the F5 case becomes defensible.
- **Anthropic deprecates prompt caching** or changes pricing such that the auto-cache benefit disappears. Specific signal: cache-read pricing changes from current ~$0.30/MTok rate by more than 3x, or cache TTL drops below 1 minute. F2 collapses; re-derive.
