# Vault Entry Format

When writing a decision to the vault, use this structure.

## Frontmatter

```yaml
---
type: decision
features: [feature-name]
related: ["[[other-decision]]"]
created: YYYY-MM-DD
confidence: high | medium | low
---
```

**type** — `decision`, `research`, `contract`, `context`, or `exploration`
**features** — list of features this entry applies to
**related** — wikilinks to related vault entries
**created** — date the entry was written
**confidence** — how certain you are this will hold

## Body structure for decisions

```markdown
# [Decision Title — stated as what was chosen]

## Decision
[What was chosen, stated concretely enough to implement without clarification]

## Reasoning
[Why this option won — the human's defense that survived challenge]

## Strongest rejected alternative
[What lost and why — the full counter-argument that was considered and dismissed]

## Failure mode
[How the chosen approach breaks and under what conditions]

## Revisit when
[Specific conditions that should trigger reopening this decision]
```

## Index update

After writing the vault entry, add a line to `.bocek/vault/index.md`:

```markdown
- [[entry-name]] — type: decision — one-line summary
```

Group entries by feature. Create the feature heading if it doesn't exist.

## State checkpoint

After writing the vault entry, update `.bocek/state.md`:

```markdown
## Current state
- Feature: [active feature]
- Last resolved: [[entry-name]]
- In progress: [what's being explored]
- Next: [next question to address]
```

## Index initialization

If `.bocek/vault/index.md` doesn't exist, create it:

```yaml
---
vault_version: 1
---
```

Then add the entry line below.
