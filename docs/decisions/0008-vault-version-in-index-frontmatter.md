# ADR-0008: Vault Version in index.md Frontmatter

## Status
Accepted

## Context
Primitives evolve. Vault format may need to change. `bocek update` pulls new primitives but must never silently break existing project vaults. A versioning mechanism is needed so primitives can detect format mismatches.

## Decision
The vault's `index.md` carries a `vault_version` field in its YAML frontmatter, starting at 1. Primitives check this version on load and warn on mismatch. No migration tooling built upfront — just the version marker so future migrations have something to key off.

```yaml
---
vault_version: 1
---
```

## Alternatives Considered
**Separate version file (`.bocek/vault/VERSION`):** Extra file for a single integer. Rejected — frontmatter on index.md is sufficient and keeps the vault entry point self-describing.

**Migration tooling built now:** Premature. Version 1 hasn't shipped yet. Build migration scripts when version 2 is needed, not before.

## Consequences
- **Positive**: Every vault is versioned from day one — future migrations have a reliable marker
- **Positive**: Zero overhead — one line of frontmatter
- **Positive**: Primitives can warn clearly: "this vault is version 1, this primitive expects version 2"
- **Negative**: No automatic migration — human must run a migration script when one exists

## Revisit When
- When vault version 2 is needed — at that point, build the migration script
