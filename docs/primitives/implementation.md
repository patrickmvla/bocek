# Implementation Primitive: Design

## Context
The implementation primitive is where everything Bocek has built pays off. The vault is full of decisions, research, and contracts. The compiled format exists. Now the model writes code — constrained by everything that came before.

Without Bocek, the model gets "build me a checkout API" and generates route handlers from training data defaults. With Bocek, the model reads the compiled vault and implements from a specification. Every line of code has a decision behind it. Every decision has evidence behind it.

The fundamental failure mode this primitive prevents: LLMs sprint toward completion and cut corners on everything between. Next-token prediction naturally favors the token that moves toward a working output. The disciplined token — the one that stops and checks the contract — is statistically less likely. The primitive makes that disciplined token the only valid path.

## Goals
- Implement strictly within vault constraints — no improvisation, no training data defaults
- Treat missing decisions as errors, not opportunities to fill gaps
- Verify every unit of work against the vault contract before advancing
- Narrate constraint-following visibly — quote vault entries, cite decisions, demonstrate compliance
- Produce code that is traceable back to the vault — every architectural choice is a documented decision

## Non-Goals
- Not a code generator — it doesn't produce code from vague descriptions
- Not an optimizer — performance improvements without vault backing are out of scope
- Not a refactoring tool — reshaping existing code is the refactoring primitive's job
- Not a decision maker — when a decision is missing, it stops and flags, it doesn't decide

## Design

### Core mechanism: contract executor

The model is a contractor who can't proceed to the next phase until the inspector signs off on the current one. The inspector is the vault.

**Before writing any function:**
1. Read the compiled vault entry for the feature
2. Quote the specific contract this function must satisfy
3. Then implement

**Before making any architectural choice inline:**
1. Check if there's a vault decision covering it
2. If yes, follow it and cite it
3. If no, stop — flag the gap, don't pick the expedient option

**After completing any unit of work:**
1. Verify against the contract — trace inputs through code, confirm outputs match spec
2. Confirm error handling matches every error the contract defines
3. Check that no behavior was introduced that the contract doesn't mention

**Before moving to the next component:**
1. Confirm the current one is complete as specified — not "functionally working," complete
2. Verify integration points match adjacent component contracts

### Refuse to improvise

When the model encounters a decision it needs that isn't in the vault, it does not fill the gap from training data. It stops and reports:

- What decision is missing
- Why it's needed (which implementation step is blocked)
- What the options are (from training data, clearly labeled as unvetted)
- Instruction to resolve in design mode or give a directive

The gap report gives the human enough context to make a quick decision or to switch to design mode for a thorough one.

### Narration requirement

The model visibly demonstrates constraint-following. Not silent compliance — active citation.

"The contract specifies 409 on inventory conflict. I'm implementing the version check in the transaction. If versions mismatch, I return 409 with body `{error: 'inventory_conflict'}` as specified in [[payment-api-contract]]."

This serves two purposes:
1. The human verifies the model is actually following constraints, not claiming to
2. The narration forces the model's attention back to the vault — quoting a constraint makes the model follow it more reliably than silently reading it

### Compiled vault consumption

The implementation primitive triggers lazy compilation (ADR-0007) at session start:
1. Read `.bocek/vault/index.md` to identify relevant features
2. Check if `.compiled/{feature}.md` is stale
3. Recompile if needed
4. Load the compiled context for the feature being implemented

The compiled vault enters context just-in-time at the high-attention end — aligned with context engineering research (ADR-0011).

### Two-layer architecture (ADR-0011, ADR-0012)

**Core** (~800-2,000 tokens, persistent):
- Mode identity — contract executor, not code generator
- Refuse-to-improvise mandate
- Step-by-step verification loop: read contract → quote → implement → verify → confirm → advance
- Narration requirement with vault citations
- Compiled vault loading instruction
- Gap protocol — stop and flag, don't fill
- Tool constraints — source file writes allowed, vault writes allowed
- Reference table:

| When | Read |
|------|------|
| Implementing against a contract | references/contract-following.md |
| Verifying completed work | references/verification.md |
| Flagging a missing decision | references/gap-flagging.md |
| Applying code quality patterns | references/code-quality.md |
| Checkpointing progress | references/session-continuity.md |
| Verifying component integration | references/integration-verification.md |

**References** (loaded on demand, with concrete code block examples per ADR-0015):
- Contract-following protocol — demonstrated cycle of quote → implement → verify → flag with actual code blocks
- Verification patterns — how to trace inputs through code against contracts, confirm error handling matches spec
- Gap flagging format — what to include so the human can resolve quickly, with example gap reports
- Code quality constraints — which patterns to apply based on vault tech stack decisions
- Session continuity — how to checkpoint implementation progress to state.md (files changed, contracts satisfied, contracts remaining)
- Integration verification — how to verify a component integrates correctly with adjacent contracts

### Session continuity

Checkpoint to `.bocek/state.md` after each contract is satisfied. State captures:
- Feature being implemented
- Contracts satisfied (with file references)
- Contracts remaining
- Files created or modified
- Any gaps flagged and their resolution status
- Next contract to implement

## Trade-offs

**Speed vs discipline:** The verification loop slows implementation compared to unconstrained generation. This is intentional. The tokens spent on verification are cheaper than the tokens spent debugging code that silently deviated from the design.

**Narration overhead vs reliability:** Quoting vault entries in every implementation step adds visible overhead. But the narration is the mechanism that keeps the model honest — without it, the model silently drifts toward training data defaults as the contract fades from attention.

**Strictness vs flexibility:** The refuse-to-improvise mandate means the model stops when it could plausibly continue. Some gaps are genuinely trivial (variable naming, log message format). But the primitive treats all gaps the same — because "trivial" gaps are where silent architectural drift begins. The human can resolve trivial gaps with a quick directive.

**Contract completeness dependency:** The implementation primitive is only as good as the vault. If the design phase produced vague or incomplete contracts, implementation will flag many gaps. This is a feature — it surfaces design debt at the cheapest possible moment (before code is written, not after).
