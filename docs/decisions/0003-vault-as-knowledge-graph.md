# ADR-0003: Vault as Knowledge Graph, Not Rigid Hierarchy

## Status
Accepted

## Context
The vault needs to serve as the persistent knowledge store for all engineering decisions, research, contracts, and context across a project. The initial proposal prescribed fixed files per feature (context.md, contracts.md, research.md, implementation.md, decisions/). This mirrors a filing cabinet — rigid, prescriptive, and mismatched with how engineering knowledge actually develops.

Obsidian vaults work because structure emerges from the work instead of being imposed upfront. Notes are created when knowledge crystallizes. Wikilinks create relationships organically. The graph reveals patterns that no hierarchy could predict.

## Decision
We will model the vault as a knowledge graph with lightweight conventions, not a rigid hierarchy. Any markdown file can live anywhere in `.bocek/vault/`. Files are linked via wikilinks. Frontmatter tags type, features, and relationships. Feature directories are optional grouping convenience. An `index.md` at vault root serves as the LLM's navigation entry point.

Conventions (not requirements):
- Frontmatter tags: `type` (decision, research, contract, context, exploration), `features` (list), `related` (wikilinks), `created`, `confidence`
- Feature directories group related files when it makes sense
- Files that span multiple features live at vault root or in their own grouping
- Wikilinks are the primary relationship mechanism
- The graph structure is more important than the folder structure

## Alternatives Considered
**Rigid hierarchy with prescribed files per feature:** Every feature gets context.md, contracts.md, research.md, implementation.md, decisions/. Rejected because real engineering work doesn't produce uniform artifacts. Some features need heavy research and no contracts. Forcing empty files or skipping prescribed ones both create friction. A rigid structure can't capture cross-feature relationships naturally.

**Flat directory with only tags:** All files at vault root, organized purely by frontmatter. Rejected because some grouping by feature is genuinely useful for both humans browsing and LLMs scoping reads. Optional directories give the best of both.

## Consequences
- **Positive**: Vault follows the shape of the work, not a template
- **Positive**: Cross-feature relationships captured naturally via wikilinks
- **Positive**: Steals proven patterns from Obsidian's model — backlinks, graph emergence, flexible structure
- **Positive**: Open to borrowing more from Obsidian as the design evolves
- **Negative**: Less predictable structure means the LLM needs `index.md` navigation — can't assume file locations
- **Negative**: Without discipline, vaults could become disorganized — but that's the human's responsibility, matching the "vault breathes" philosophy

## Revisit When
- If LLM navigation proves unreliable without predictable file locations
- If users consistently struggle to organize vault entries without more structure
- If additional Obsidian patterns (tags, Dataview queries, graph view conventions) should be formally adopted
