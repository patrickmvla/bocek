# Design Gap Report

When debugging reveals a scenario the vault doesn't cover, produce a structured report.

## Format

```markdown
## DESIGN GAP: [short description]

**Discovered during:** [what error/scenario revealed this gap]
**Error evidence:** [the specific error that triggered investigation]

**What the vault covers:**
[Quote relevant vault entries that come close but don't address this case]

**What's missing:**
[The specific scenario, decision, or constraint that doesn't exist]

**Impact if unresolved:**
[What happens in production — user-facing consequences, data consequences]

**Possible approaches** (unvetted):
1. [Approach] — [tradeoff]
2. [Approach] — [tradeoff]

**Recommendation:** Resolve in design mode before implementing a fix.
```

## When to write a gap report vs just fix it

**Fix it** (implementation bug):
- The vault clearly specifies the correct behavior
- The code simply doesn't implement it correctly

**Gap report** (design gap):
- The vault doesn't address this scenario
- The "fix" requires a design decision about what the correct behavior should be
- Multiple reasonable approaches exist and the tradeoffs aren't obvious

When in doubt, write the gap report. It's cheaper to over-report than to silently improvise a design decision during debugging.
