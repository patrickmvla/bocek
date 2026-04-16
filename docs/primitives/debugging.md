# Debugging Primitive: Design

## Context
Debugging with LLMs typically devolves into guessing. The model sees vague symptoms, generates plausible-sounding theories from training data, and produces fixes that may solve the symptom while violating design constraints. Common failure: the model "fixes" an inventory conflict by removing the version check — eliminating the error but destroying the optimistic locking that was a deliberate decision.

Bocek's debugging primitive works from evidence, not vibes. The human provides hard data. The model traces it against the vault and the code. Hypotheses are grounded in error messages and stack traces, not in what the model thinks might be wrong.

## Goals
- Require concrete error evidence before any diagnosis — no guessing from descriptions
- Trace errors against vault constraints to distinguish implementation bugs from design gaps
- Fix implementation bugs while preserving all vault constraints
- Flag design gaps instead of silently working around them
- Write discoveries to the vault when debugging reveals unknown constraints or failure modes

## Non-Goals
- Not a monitoring tool — it doesn't watch for errors proactively
- Not a testing framework — writing tests is implementation mode's job
- Not a design reviser — if the design is causing the error, that goes back to design mode
- Not a performance profiler — slow code isn't a bug unless it violates a vault constraint

## Design

### Evidence-first mandate

The debugging primitive refuses to theorize without evidence. Required inputs before any diagnosis:

- **Error messages** — exact text, not paraphrased
- **Stack traces** — full trace, not truncated
- **Log output** — relevant log lines around the failure
- **Failing test output** — test name, assertion, expected vs actual
- **Reproduction steps** — what triggers the failure

If the human says "checkout is broken" without evidence, the model's response is "show me the error message" — not "let me look at the checkout code."

### Vault-aware diagnosis

Once evidence is in hand, the model reads relevant vault entries before forming hypotheses. The vault tells it:
- What behavior was designed (not a bug)
- What constraints must be preserved in any fix
- What was explicitly decided against (don't accidentally reintroduce rejected approaches)
- What failure modes were anticipated during design

### The debugging loop

1. **Human provides error evidence** — messages, traces, logs, reproduction steps
2. **Model reads relevant vault entries** — understands what was designed, what constraints exist
3. **Model forms hypotheses** — grounded in the evidence AND the vault, not training data guesses
4. **Model traces through code** — reads the actual code path, follows the execution, doesn't speculate
5. **Model identifies root cause** — explicitly classifies:
   - **Implementation bug**: code doesn't match what the vault specifies → fix it
   - **Design gap**: vault doesn't cover this scenario → flag it, don't improvise a design
   - **Incorrect assumption**: a vault decision was based on an assumption that doesn't hold → flag for design review
6. **Model fixes** (if implementation bug) — while preserving ALL vault constraints, narrating which constraints it's protecting
7. **Model flags** (if design gap or incorrect assumption) — reports what's missing, what the options are, and why this can't be fixed without a design decision
8. **Model writes discovery to vault** (if something new was learned) — "found that X assumption doesn't hold under Y condition"

### Two-layer architecture (ADR-0011, ADR-0012)

**Core** (~800-2,000 tokens, persistent):
- Mode identity — evidence-based diagnosis, not guess-based
- Evidence-first mandate — refuse to theorize without error data
- Vault-aware diagnosis requirement — read vault before forming hypotheses
- Root cause classification — implementation bug vs design gap vs incorrect assumption
- Fix constraints — preserve all vault decisions, narrate which constraints are being protected
- Tool constraints — source file writes allowed, vault writes allowed
- Reference table:

| When | Read |
|------|------|
| Tracing an error through code | references/trace-protocol.md |
| Classifying root cause | references/root-cause-classification.md |
| Fixing while preserving constraints | references/constraint-preserving-fix.md |
| Flagging a design gap | references/design-gap-report.md |
| Writing a discovery to vault | references/discovery-format.md |

**References** (loaded on demand, with concrete examples per ADR-0015):
- Trace protocol — demonstrated example of following a stack trace through code, reading each function, identifying where behavior diverges from contract
- Root cause classification — examples showing the difference between "code is wrong" vs "design didn't cover this" vs "assumption was incorrect"
- Constraint-preserving fix — example of fixing a bug while narrating which vault constraints are being preserved and why the fix doesn't violate them
- Design gap report — example of a well-structured gap report that gives the human enough context to resolve quickly
- Discovery format — vault entry format for discoveries (type: `context` with discovery details, linked to the decisions they affect)

### Session continuity

Checkpoint to `.bocek/state.md` when root cause is identified and after fix is applied. State captures:
- Error being investigated (with evidence summary)
- Root cause classification
- Fix applied (if implementation bug)
- Gaps flagged (if design gap)
- Discoveries written to vault
- Verification status — whether the fix resolves the original error

## Trade-offs

**Speed vs discipline:** Reading the vault before debugging adds time. But fixing a bug by violating a design decision creates a worse bug — one that passes tests but breaks architecture. The vault read is insurance against making things worse.

**Strictness vs pragmatism:** Some bugs are trivially obvious and don't need vault consultation. But "obviously trivial" is where silent architectural drift begins. A typo fix is trivial. "Fixing" a timeout by increasing it to 60 seconds might violate a latency constraint that was a deliberate decision.

**Discovery scope:** The debugging primitive might uncover systemic issues that affect multiple features. Writing these to the vault is valuable but risks scope creep. The primitive writes the discovery and flags it — but doesn't pursue the implications across features. That's a design mode task.
