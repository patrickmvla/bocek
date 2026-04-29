# Review Output Format

Review findings are written to the vault as `context` entries. The format encodes what `/review` produces — coverage, classification, severity rationale, and idiom-aware drift.

## Frontmatter

```yaml
---
type: context
features: [reviewed-feature]
related: ["[[reviewed-decisions]]", "[[reviewed-contracts]]"]
created: YYYY-MM-DD
confidence: high
---
```

## Body structure

```markdown
# Review: [feature name] — [date]

## Coverage
[REQUIRED. Per *Coverage plan* in review.md — explicit accounting, no silent skipping.]
- **Vault entries in scope:** N
- **Reviewed:** M of N
- **Deferred:** [list with reason — "deferred [[entry-name]] because the area is mid-refactor"]
- **Idiom files applied:** [`idioms/typescript.md`, etc., or "none — no idiom file matches the stack"]

## Summary
- X findings total: Y drift, Z gaps, W orphans
- Critical: [count]
- Major: [count]
- Minor: [count]

## Findings

### [DRIFT] — [short description]
**Vault says:** [quote with [[wikilink]] or `idioms/[stack].md` cite]
**Code does:** [actual behavior at file:line]
**Discrepancy:** [specific difference]
**Severity:** [critical | major | minor]
**Severity rationale:** [REQUIRED. Why this severity per review.md *Production-grade default* gate 2.
Bar for critical: security / data loss / contract violation in user-facing path.
Bar for major: contract violation in internal path.
Bar for minor: undocumented behavior with no current consequence.]
**Recommendation:** [fix code | update vault | investigate]
**Reproducibility:** [REQUIRED for judgment-based findings. "Reproducible — another reviewer
following the contract from [[entry]] would reach the same finding" or
"Judgment-based — depends on read of failure semantics; downgrading severity by one tier."]

### [GAP] — [short description]
**Vault says:** [what the entry specifies]
**Code does NOT:** [what's missing — the contract isn't satisfied]
**Severity:** ...
**Severity rationale:** ...
**Recommendation:** ...

### [ORPHAN] — [short description]
**Code does:** [behavior at file:line, no vault entry justifies it]
**Vault gap:** [no entry covers this — could be undocumented behavior, dead code, or design gap]
**Severity:** ...
**Severity rationale:** ...
**Recommendation:** [vault it as a discovery | remove if dead | escalate to /design if a real
design gap]

### [IDIOM-DRIFT] — [short description]
[REQUIRED section if any idiom-file violations were found. Separated because these are
drift against the production-grade default, not against the project's specific vault.]
**Idiom says:** [quote from `idioms/[stack].md` with section name]
**Code does:** [actual behavior at file:line]
**Vault exception:** [if a vault entry justifies the deviation, name it; if not, this is a finding]
**Severity:** ...
**Severity rationale:** ...
**Recommendation:** [adopt the idiom | vault the exception with named reason]

## Patterns observed
[Any patterns across findings — systematic drift in one area, cluster of orphans suggesting
a missing design dimension, repeated idiom violations that suggest the team needs onboarding,
etc. Patterns are findings about the *findings* and often more valuable than individual items.]

## Recommendations
[Ordered list of what to address first, based on severity and pattern. Each item names the
mode that should handle it: /implementation for code fix, /design for vault update, etc.]
1. **[/implementation]** Fix [[finding]] — [reason]
2. **[/design]** Resolve [[gap]] — [reason]
3. **[/refactoring]** Clean up [[orphan]] — [reason]
```

## After writing

Update `.bocek/vault/index.md` with the review entry. Update `.bocek/state.md` with review progress.

Drift findings may trigger:
- **`/implementation`** — fix code that doesn't match the vault
- **`/design`** — update the vault if the code is correct and the vault is outdated
- **`/refactoring`** — clean up orphan code that no contract justifies
- **`/debugging`** — investigate a finding that's actually a bug, not a drift

## Reproducibility discipline

A finding that hinges on opinion ("I'd prefer this naming") is not a finding — it's a preference.
Either vault the preference once as a project standard (handed to /design) or drop it.

A finding that hinges on judgment about ambiguous behavior should be labeled as judgment-based
and downgraded one severity tier. The bar for major / critical is reproducibility — another
reviewer working from the same vault and idiom files should reach a substantially similar finding.
