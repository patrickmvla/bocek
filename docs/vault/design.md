# Vault: Design

## Context
The vault is Bocek's persistent knowledge store — the central data structure that every primitive reads from or writes to. It lives at `.bocek/vault/` in the project root, gets committed to the project's repo, and travels with the code. It captures design decisions, research findings, contracts, and implementation context across a project's lifecycle.

The vault has no precedent that combines all of its properties: Obsidian-style knowledge graph structure, dual-format representation (human-readable + compiled), integration with an enforced design-before-implementation workflow, and zero startup context cost. The closest parallels are Karpathy's LLM Wiki (single-format knowledge base for research) and Vercel's agent-skills (compiled AGENTS.md from individual rule files).

## Goals
- Persist engineering knowledge across sessions so new conversations inherit previous decisions
- Serve two audiences: humans navigating decisions (browsing, PR review, future reference) and LLMs loading context before implementation
- Support organic growth — structure follows the work, not a template
- Enable Obsidian compatibility for graph view, backlinks, and search without depending on Obsidian
- Survive `bocek update` — format changes must never silently break existing vaults

## Non-Goals
- Not a replacement for code comments or inline documentation — the vault captures *why*, the code captures *how*
- Not an archive — the vault breathes, grows during active work, compacts when features ship
- Not a real-time sync system — there is no bidirectional sync between human and machine formats
- Not a database — no query language, no indexing beyond the flat index.md catalog
- Not portable across projects — each project has its own vault; cross-project knowledge lives in the user's primitives and references

## Design

### Two layers, one direction

The vault has two representations of the same knowledge:

**Human layer** — Obsidian-style markdown files with YAML frontmatter and wikilinks. Any file, anywhere in `.bocek/vault/`, organized by optional feature directories. This is the source of truth. All edits happen here. Files are created when knowledge crystallizes — "vault that" — not on a schedule or template.

Each file carries frontmatter:
```yaml
---
type: decision | research | contract | context | exploration
features: [checkout, inventory]
related: ["[[session-format]]", "[[stripe-research]]"]
created: 2026-04-16
confidence: high | medium | low
---
```

Cross-references use wikilinks (`[[name]]`), which are resolved by name not path — surviving file moves within the vault.

**Compiled layer** — One structured markdown file per feature scope, living in `.bocek/vault/.compiled/` (gitignored). Generated from human files by the implementation primitive on demand. Optimized for clarity and navigability, not token density — following the Vercel AGENTS.md pattern. Contains constraints with rationale, contracts with type signatures, and resolved cross-feature dependencies. Every item traces back to its source file.

Compilation is lazy — triggered by the implementation primitive at load time, only when compiled files are stale relative to source files. No manual command, no hook, no eager rebuilding.

### Navigation

`index.md` at the vault root is the LLM's entry point. A flat catalog grouped by feature, one line per entry with type and summary. Maintained automatically by primitives during vault writes.

```yaml
---
vault_version: 1
---
```

The version field in index.md frontmatter enables future format migrations. Primitives check this on load and warn on mismatch.

### Directory structure

```
.bocek/
  vault/
    index.md                          ← LLM entry point, auto-maintained
    .compiled/                        ← gitignored, per-feature compiled files
      checkout.md
      auth.md
    checkout/                         ← optional feature grouping
      why-optimistic-locking.md       ← decision
      stripe-integration-research.md  ← research
      payment-api-contract.md         ← contract
    auth/
      session-format.md               ← decision
    inventory-locking-patterns.md     ← cross-feature, lives at vault root
  mode                                ← current mode (design|research|implement|idle)
  state.md                            ← current phase, active feature, resume point
```

Feature directories are optional grouping convenience, not required structure. Files that span multiple features live at the vault root. The graph structure (wikilinks) is more important than the folder structure.

### Lifecycle

**Growing** — Active feature work. Research, decisions, contracts accumulating. Thick and detailed.

**Compacting** — Feature ships. Human triggers cleanup. Working notes collapse into distilled knowledge. "Summarize the auth vault into a single knowledge entry."

**Referencing** — Months later. Compacted entry tells you what was decided and why. New research cycle starts if deeper exploration is needed.

The human decides what stays and what goes. The primitive helps with cleanup but doesn't auto-compact.

### Write cadence

Writes happen at knowledge crystallization points — the moment something shifts from "exploring" to "we now know something." Not every conversational turn (bloat) and not only final decisions (too thin). The human triggers the write.

If a session dies mid-conversation, `state.md` records the exploration state: "exploring inventory locking strategy, no decision yet, resume probing." Next session picks up the question, not the debate.

## Alternatives Considered

**Rigid hierarchy with prescribed files per feature** (context.md, contracts.md, research.md, implementation.md, decisions/): Predictable but mismatched with how engineering knowledge develops. Real features produce non-uniform artifacts. Some need heavy research and no contracts. Forcing empty files or skipping prescribed ones both create friction. Cannot capture cross-feature relationships naturally.

**Single format (Karpathy-style):** Simpler, no compilation step, proven at research-wiki scale. Rejected because Bocek vaults will grow larger than research wikis — hundreds of decisions across dozens of features. Token cost of loading prose-format decisions before implementation degrades model reasoning.

**XML-structured compiled format:** Based on Anthropic's API documentation recommendations. Rejected after research showed vault content reaches the model via file reads (tool results), not system prompts. Cline and Vercel both use plain markdown for tool-result-level context.

**Token-dense compressed compiled format:** Maximally efficient but rejected after research showed Vercel's production LLM format (AGENTS.md) uses full prose explanations. Models reason better from clear explanations than telegraphic notation.

## Trade-offs

**Flexibility vs predictability:** The knowledge graph structure means the LLM can't assume file locations — it must read index.md first. This adds one read operation but enables organic structure that follows the work.

**Dual format vs simplicity:** Two representations means a compilation step. But one-way lazy compilation is simple and the sync problem is eliminated. The cost is worth paying for the audience-appropriate output.

**Obsidian conventions vs portability:** Wikilinks don't render on GitHub. Accepted because the vault is primarily navigated in an editor or Obsidian, not browsed on GitHub.

## Prior Art

- **Karpathy's LLM Wiki**: Three-layer architecture (raw → wiki → CLAUDE.md). Single-format markdown with frontmatter and index.md navigation. Proven at 50-200 source scale. Source: https://blog.starmorph.com/blog/karpathy-llm-wiki-knowledge-base-guide
- **Vercel agent-skills**: Two-layer architecture (individual rule files → compiled AGENTS.md). AGENTS.md explicitly labeled "mainly for agents and LLMs." Uses structured markdown with prose, not compressed notation. Source: github.com/vercel-labs/agent-skills
- **BMAD Method**: Single-format markdown throughout. No LLM-optimized companion format. 67-86% context consumption at startup. Source: github.com/bmadcode/BMAD-METHOD

## References
- ADR-0001 through ADR-0008 document individual decisions
- Cline system prompt source: github.com/cline/cline (prompt component architecture)
- Anthropic prompting best practices: platform.claude.com
