# Review Primitive: Design

## Context
Code review with LLMs typically defaults to the model's training data sense of "good code" — naming conventions, design patterns, complexity metrics. This is the exact probability distribution Bocek exists to override. A review that says "consider using the strategy pattern here" when the vault explicitly chose a simpler approach is the system fighting itself.

The review primitive's primary job is drift detection — finding where implementation silently deviated from vault decisions. Traditional code quality review is secondary and only flagged when severe enough to matter.

## Goals
- Detect drift between implemented code and vault decisions/contracts — the primary function
- Identify undocumented behavior — code that does things no vault entry covers
- Surface violated constraints — places where vault rules are broken
- Flag code quality issues only when severe and impactful — not stylistic preferences
- Produce actionable findings with vault citations, not generic improvement suggestions

## Non-Goals
- Not a linter — style and formatting belong to automated tools
- Not a design evaluator — questioning whether vault decisions were correct is design mode's job
- Not a test writer — that's implementation mode
- Not a refactoring engine — it identifies problems, doesn't fix them

## Design

### Priority ordering

The review primitive evaluates in this strict order:

**Priority 1 — Vault compliance:**
Does the code do what the vault says it should? For every vault decision and contract, trace it through the code. Find:
- Contracts violated — API shapes that don't match, error codes that differ, missing error paths
- Decisions ignored — vault says optimistic locking, code uses pessimistic
- Constraints broken — vault says no stored card data, code writes card info to database

**Priority 2 — Undocumented behavior:**
Does the code do things no vault entry covers? Find:
- Behavior that exists without a vault decision behind it — the model decided something during implementation that should have been flagged
- Side effects not in any contract — logging sensitive data, external API calls, state mutations
- Implicit assumptions — hardcoded values, magic numbers, unconstrained retries

**Priority 3 — Code quality (severe only):**
Is there code that's bad enough to cause production issues? Only flag:
- Bugs — actual logical errors, race conditions, resource leaks
- Security issues — injection, auth bypass, exposed secrets
- Performance traps — N+1 queries, unbounded loops, missing pagination
- NOT stylistic preferences, naming opinions, or pattern suggestions

### Drift detection mechanism

For each vault entry relevant to the code being reviewed:

1. **Read the vault entry** — decision, contract, or constraint
2. **Find the code that should implement it** — trace from the entry to the source
3. **Compare** — does the code match what the vault specifies?
4. **Classify the finding:**
   - **Drift** — code deviates from vault. Could be an implementation bug or a deliberate change that wasn't documented.
   - **Gap** — vault specifies something the code doesn't implement at all
   - **Orphan** — code implements something the vault doesn't mention
5. **Report with citations** — quote the vault entry, point to the code, show the discrepancy

### Finding format

Each finding is structured:

```markdown
### [DRIFT|GAP|ORPHAN] — short description

**Vault says:** [quote from vault entry with [[wikilink]]]
**Code does:** [what the code actually does with file:line reference]
**Discrepancy:** [specific difference]
**Severity:** critical | major | minor
**Recommendation:** [fix the code | update the vault | investigate further]
```

### Vault output

Review findings are written to the vault as type `context`:

```yaml
---
type: context
features: [feature-name]
related: ["[[reviewed-decisions]]"]
created: YYYY-MM-DD
confidence: high
---
```

Drift findings may trigger design mode (to update the vault) or implementation mode (to fix the code). The review primitive identifies — it doesn't fix.

### Two-layer architecture (ADR-0011, ADR-0012)

**Core** (~800-2,000 tokens, persistent):
- Mode identity — drift detector, vault compliance first
- Priority ordering — vault compliance, then undocumented behavior, then severe code quality
- Drift detection mandate — compare every relevant vault entry against code
- Finding classification — drift, gap, orphan
- No fixing — identify and report, don't change code
- Tool constraints — no source file writes, vault writes allowed
- Reference table:

| When | Read |
|------|------|
| Performing vault compliance check | references/vault-compliance.md |
| Classifying a finding | references/finding-classification.md |
| Identifying undocumented behavior | references/undocumented-behavior.md |
| Writing review findings to vault | references/review-output.md |
| Assessing code quality severity | references/severity-assessment.md |

**References** (loaded on demand, with concrete examples per ADR-0015):
- Vault compliance — example of reading a contract, tracing it through code, finding where the code deviates, and reporting the drift with citations
- Finding classification — examples of drift vs gap vs orphan with real code showing each pattern
- Undocumented behavior — example of finding code that does things no vault entry covers, tracing the behavior, and classifying it
- Review output — example of a complete review finding written to the vault
- Severity assessment — examples distinguishing severe quality issues (bugs, security, performance traps) from stylistic preferences the model should ignore

### Session continuity

Checkpoint to `.bocek/state.md` after each vault entry is reviewed. State captures:
- Feature being reviewed
- Vault entries reviewed (with finding count per entry)
- Vault entries remaining
- Critical findings summary
- Drift patterns observed across the review

## Trade-offs

**Vault-first vs comprehensive review:** Traditional code review covers everything. Bocek's review only covers vault compliance deeply, with code quality as a secondary concern. This means stylistic issues and minor improvements go unmentioned. The tradeoff is intentional — the model's training data taste for "good code" is exactly the default Bocek overrides.

**Strictness of classification:** Every piece of undocumented code gets flagged as an orphan. In practice, some orphans are trivially obvious (a logging statement doesn't need a vault decision). But flagging everything forces the human to decide what's intentional and what's drift. The cost of a false positive is a 2-second dismissal. The cost of a missed drift is architectural erosion.

**Review scope vs depth:** Reviewing an entire feature's vault compliance takes time. The model must read every relevant vault entry and trace it through code. For large features, this may span multiple sessions. The session continuity mechanism handles this — but the human needs to know that reviews aren't instant.
