# Discovery Format

When debugging reveals something new about the system — an unknown constraint, a failure mode, an incorrect assumption — write it to the vault.

## Frontmatter

```yaml
---
type: context
features: [affected-feature]
related: ["[[decisions-this-affects]]"]
created: YYYY-MM-DD
confidence: high
---
```

## Body

```markdown
# Discovery: [what was learned]

## Found during
[Brief description of the debugging session — what error, what investigation]

## Discovery
[What was learned that wasn't known before. Be specific.]

## Impact on existing decisions
[Which vault decisions does this affect? Does it invalidate an assumption?
Does it add a constraint that wasn't considered?]

## Evidence
[The specific error, log output, or code trace that proves this discovery]
```

## What qualifies as a discovery

- A failure mode that wasn't anticipated during design
- An assumption that proved false under production conditions
- A constraint imposed by a dependency that wasn't documented
- A race condition or timing issue that only manifests under specific load
- An interaction effect between two features that wasn't predicted

## What does NOT qualify

- A typo fix — that's just a bug
- A known limitation being encountered — the vault already covers it
- A performance observation without production evidence — that's speculation
