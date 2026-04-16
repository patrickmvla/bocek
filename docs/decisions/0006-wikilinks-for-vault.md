# ADR-0006: Wikilinks for Vault Cross-Referencing

## Status
Accepted

## Context
The vault's human-format files need to reference each other to form a knowledge graph. Two conventions exist: Obsidian-style wikilinks (`[[decision-name]]`) and standard markdown links (`[decision name](./path/to/file.md)`).

## Decision
We will use wikilinks (`[[name]]`) for all cross-references in vault files. The vault is designed to be opened in Obsidian for graph view and backlink navigation.

## Alternatives Considered
**Standard markdown links:** Render on GitHub, explicit paths. Rejected because they're more friction to write, break when files move, and don't enable Obsidian's graph view or automatic backlink discovery. The vault is primarily navigated in Obsidian or by the LLM, not browsed on GitHub.

## Consequences
- **Positive**: Vault works natively in Obsidian — graph view, backlinks, search all work out of the box
- **Positive**: Lower friction to create links — `[[name]]` vs `[name](../path/to/file.md)`
- **Positive**: Links survive file moves within the vault (Obsidian resolves by name, not path)
- **Negative**: GitHub won't render wikilinks as clickable — vault entries show raw `[[brackets]]` in PR reviews
- **Negative**: LLM needs to resolve wikilinks to file paths when navigating — but index.md handles this

## Revisit When
- If GitHub adds wikilink rendering support
- If PR review of vault entries becomes a primary workflow and the broken links cause real friction
