# Refactoring Primitive: Design

## Context
Refactoring with LLMs is the most dangerous mode. The model sees code it thinks is "bad" based on training data patterns, rewrites it, and breaks production. 5000 lines deleted because the model's sense of "clean code" overrode the reality that those lines handled edge cases discovered over months of production use.

The refactoring primitive is the most conservative of all six modes. It changes HOW code is structured without changing WHAT it does. The vault defines the WHAT. The code defines the HOW. Refactoring only touches the HOW — and only after proving it understands the current behavior completely.

## Goals
- Change structure without changing behavior — provably, not hopefully
- Never touch code the model doesn't fully understand
- Preserve all vault contracts — external interfaces are inviolable
- Require human approval on refactoring plans before execution
- Execute in small verified steps, not massive rewrites

## Non-Goals
- Not a code reviewer — evaluating code quality is review mode's job
- Not a feature builder — adding new behavior is implementation mode's job
- Not a design reviser — if refactoring reveals a contract needs to change, that goes to design mode
- Not a deletion tool — removing code requires understanding, not pattern-matching against "clean code" standards

## Design

### Core mandate: understand before touching

The model must prove it understands what code does BEFORE it changes anything. Not "I can see it's a loop" — deep understanding of the behavior, the edge cases, and why the code exists in its current form.

### The refactoring sequence

1. **Read completely** — every line, every branch, every edge case handler of the code being refactored. No skimming.

2. **Map behavior** — document what each piece does in terms of behavior, not structure. "This block handles the case where a payment succeeds but inventory was claimed by another transaction between the lock check and the commit."

3. **Read vault contracts** — understand what behavior is guaranteed externally. These are inviolable.

4. **Read tests** — understand what behavior is verified. Every test that passes now must pass after refactoring.

5. **Identify unknowns** — find code the model can't explain. Code that looks wrong or unnecessary but has no clear reason for removal. This code is NOT touched. The model asks the human: "these 47 lines handle a case I can't find a test for and can't trace to a vault decision. What does this handle? If you don't know, I'm not touching it."

6. **Propose the plan** — describe what changes structurally and prove behavior is preserved. The plan must state:
   - What is being restructured and why
   - What behavior is preserved (mapped to specific code paths)
   - What code is NOT being touched and why
   - What tests verify the behavior is unchanged

7. **Human approves** — the model does NOT execute until the human signs off on the plan. This is not optional. No refactoring executes without explicit approval.

8. **Execute in small steps** — incremental changes, each independently verifiable. After each step:
   - Run tests
   - Verify the contract is still satisfied
   - Confirm no behavioral change
   - Only then proceed to the next step

9. **Verify holistically** — after all steps complete, run the full test suite. Trace the critical paths through the refactored code. Confirm external interfaces haven't changed.

### The untouchable code rule

If the model encounters code it doesn't understand — code where it cannot explain why it exists, what edge case it handles, or what breaks if it's removed — it does NOT touch it.

That code might be:
- A production edge case fix from an incident
- A race condition handler discovered under load
- A workaround for a third-party library bug
- A regulatory requirement that isn't documented

The model's training data doesn't have that context. The vault might not either. The code's existence IS the documentation. The model asks the human. If the human doesn't know either, the code stays.

### Contract update protocol

When refactoring reveals that a vault contract should change (e.g., an internal restructure makes a different API shape more natural), the model:
1. Does NOT change the contract
2. Completes the refactoring preserving the current contract
3. Flags the potential contract improvement with reasoning
4. The human takes it to design mode if they agree

### Two-layer architecture (ADR-0011, ADR-0012)

**Core** (~800-2,000 tokens, persistent):
- Mode identity — most conservative mode, structure not behavior
- Understand-before-touching mandate
- Untouchable code rule — if you can't explain it, don't touch it
- Human approval requirement before execution
- Small verified steps — not massive rewrites
- Contract inviolability — external interfaces don't change
- Tool constraints — source file writes allowed, vault writes allowed
- Reference table:

| When | Read |
|------|------|
| Mapping existing behavior | references/behavior-mapping.md |
| Writing a refactoring plan | references/refactoring-plan.md |
| Executing incremental steps | references/incremental-execution.md |
| Handling unknown code | references/unknown-code-protocol.md |
| Flagging a contract change | references/contract-change-flag.md |
| Verifying behavior preservation | references/behavior-verification.md |

**References** (loaded on demand, with concrete examples per ADR-0015):
- Behavior mapping — example of documenting what code does behaviorally, tracing edge case handlers, identifying the "why" behind each branch
- Refactoring plan — example of a well-structured plan showing what changes, what's preserved, what's untouched, and what tests verify it
- Incremental execution — example of breaking a refactoring into small steps, running tests between each, rolling back when a test fails
- Unknown code protocol — example of identifying suspicious code, asking the human about it, and leaving it untouched when unexplained
- Contract change flag — example of noting a potential improvement without acting on it
- Behavior verification — example of tracing critical paths through refactored code to confirm behavioral equivalence

### Session continuity

Checkpoint to `.bocek/state.md` after human approves the plan and after each verified step. State captures:
- Code being refactored (file paths, line ranges)
- Approved refactoring plan
- Steps completed (with test results)
- Steps remaining
- Unknown code identified and human's responses
- Any contract change flags raised

## Trade-offs

**Conservatism vs progress:** The untouchable code rule and human approval requirement slow refactoring significantly. This is the correct tradeoff — the cost of breaking production code is orders of magnitude higher than the cost of a slower refactoring session.

**Small steps vs coherence:** Incremental changes can produce intermediate states that are awkward. But each intermediate state is verified and reversible. A single massive rewrite is not.

**Understanding requirement vs scope:** The model must understand every line it touches. For large legacy codebases, this limits the scope of what can be refactored in one session. This is a feature — it prevents the model from biting off more than it can verify.
