# Review Output Format

Review findings are written to the vault as context entries.

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

## Summary
- X findings total: Y drift, Z gaps, W orphans
- Critical: [count]
- Major: [count]
- Minor: [count]

## Findings

### [DRIFT] — [short description]
**Vault says:** [quote with [[wikilink]]]
**Code does:** [actual behavior at file:line]
**Discrepancy:** [specific difference]
**Severity:** [critical|major|minor]
**Recommendation:** [fix code | update vault | investigate]

### [GAP] — [short description]
...

### [ORPHAN] — [short description]
...

## Patterns observed
[Any patterns across findings — systematic drift in one area,
cluster of orphans suggesting a missing design dimension, etc.]

## Recommendations
[Ordered list of what to address first, based on severity and pattern]
```

## After writing

Update `.bocek/vault/index.md` with the review entry. Update `.bocek/state.md` with review progress.

Drift findings may trigger:
- **Implementation mode** — to fix code that doesn't match the vault
- **Design mode** — to update the vault if the code is actually correct and the vault is outdated
