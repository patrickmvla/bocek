---
type: decision
features: [_shared]
related: ["[[mattpocock-skills-survey]]"]
created: 2026-05-14
confidence: high
---

# Vault lazily — decisions land only when concrete enough to implement

## Decision

Amend `primitives/design.md`'s *Vault writes* section to state explicitly: *"Vault lazily — wait until the decision is concrete enough to implement without follow-up. Speculative directions and pre-decisions stay in conversation, not in the vault."* Adopts matt's lazy-doc creation discipline (per `[[mattpocock-skills-survey]]` finding F7, shipped twice in matt's repo — `grill-with-docs` and the deprecated `ubiquitous-language`).

## Reasoning

bocek's existing rule — *"when a decision survives challenge, write it"* — handles WHAT qualifies but is silent on WHEN. The gap allows speculative writes: half-resolved decisions vaulted to "capture the direction" before the implementation contract crystallizes. Matt's pattern explicitly defers this: *"create documentation lazily — only when you have something concrete to capture; capture resolved terms in CONTEXT.md as they emerge, not in batches"* (production-cited at his repo; shipped in two iterations across years; high confidence in pattern stability).

For bocek, the failure mode of eager vaulting is observable: vaulting a decision before it's implementable means the implementation seat hits a contract that's underspecified, has to flag a gap, and the original decision either gets amended-in-place (drift) or superseded (churn). Lazy vaulting prevents that round-trip by holding the decision in conversation until it's concrete.

## Engineering substance applied

- **Operability:** simpler discipline. One sentence in the vault-writes section communicates the rhythm. No new file, no new script.
- **Failure semantics:** prevents under-specified vault entries that cause implementation friction. The amend-in-place vs supersede churn becomes rarer.

## Production-grade gates

- **Idiomatic** — adopted verbatim from matt's `grill-with-docs/CONTEXT-FORMAT.md`. Production-cited.
- **Industry-standard** — Eric Evans' DDD writeups, matt's two iterations, the broader ADR-community pattern of "only write ADRs for decisions that survive AND are concrete" (multiple independent sources). High.
- **First-class** — uses bocek's existing vault-writes flow. No new mechanism.

## Rejected alternatives

### (a) Skip — leave the existing "survives challenge" rule unchanged

**What:** Don't add the lazy-doc sentence. Trust that "survives challenge" implies "concrete enough."

**Wins when:** the existing rule is empirically sufficient; no observed instances of speculative/premature vaulting.

**Why not here:** the rule is silent on timing. Explicit reinforcement is cheap and matches matt's production-cited pattern.

### (b) Stricter — add the three-criteria gate (matt's `ADR-FORMAT.md` shape)

**What:** Require hard-to-reverse + surprising + real-trade-off (matt's full criteria from `ADR-FORMAT.md`). That's matt-take E in the survey — separate decision deferred to its own design session.

**Wins when:** vault noise is the failure mode being addressed (too many entries).

**Why not here:** that's a SEPARATE design decision (take E). Conflating it with G muddles two concerns: WHEN to vault (timing) vs. WHAT qualifies (threshold). G handles timing; E handles threshold. Keep them separate; vault E when its derivation runs.

## Failure mode

A user (or model) interprets "concrete enough" too strictly and never vaults legitimate decisions because they're "not quite implementable yet." Real risk: a decision sits in conversation across multiple sessions, gets forgotten, the project drifts without it being recorded.

Quantitative signal: a session ends with `state.md` referencing decisions that aren't in `index.md`. The next session reads state and looks for the entry, doesn't find it, asks "what was decided?" and the conversation context is gone.

## Mitigations

1. **state.md captures in-progress decisions** even before they vault. The session-continuity discipline (per `references/shared/session-continuity.md`) keeps in-flight reasoning visible across sessions.
2. **If a decision sits unvaulted past N sessions** (heuristic N=3), the design primitive should surface the lag: *"Decision X discussed in state.md across 3 sessions but never vaulted. Vault now or supersede."*

## Revisit when

- Observed lag: state.md repeatedly references a decision that never gets vaulted. If the pattern emerges, the "concrete enough" threshold is too strict; tighten the mitigation (N=3 → N=2 sessions).
- Take E (three-criteria gate) lands. At that point, this decision and E both govern vault-write discipline; verify they compose without contradiction.

## Implementation items queued

- **G1':** Amend `primitives/design.md`'s *Vault writes* section with the lazy-doc sentence. Verify wording matches the *Decision* section verbatim.
