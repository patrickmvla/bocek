# Bocek — Design Overview

## Metadata

- **Mode**: Thorough
- **User Expertise**: Deep — fluent in bash, markdown-as-infrastructure, Claude Code internals (hooks, settings, commands, skills), Python tooling, TypeScript
- **Gravity**: Medium-high — vault format and primitive design are load-bearing decisions; toggle/hooks are low gravity

## Elevator Pitch

A knowledge-grounded engineering methodology engine for AI-assisted development. Works by loading mode-specific primitives (markdown files) on demand into Claude Code, enforcing design-before-implementation discipline via hooks, and persisting all decisions in a dual-format vault that lives in the project repo. For engineers who use AI coding assistants and want to use the model as a reasoning amplifier instead of a code generator. Solves the problem that nothing in the current ecosystem enforces design thinking, grounds decisions in fresh evidence, or preserves the reasoning trail across sessions.

## Constraints

- **Timeline**: Open-ended. No external deadline. Requires genuine engineering thought — not rushing.
- **Team**: Solo.
- **Budget/Infrastructure**: Near zero. Domain + static hosting for website. No cloud services, databases, or CI/CD beyond GitHub.
- **Tech stack expertise**: Bash (CLI/toggle), markdown (primitives/vault), Python (tooling scripts), TypeScript (website/tooling).

## Competitive Landscape

Closest competitor is BMAD Method (42k+ GitHub stars, scored 5/7 on capability matrix). Source code review revealed:
- Agent personas are personality-wrapped menu dispatchers — burn tokens on character maintenance, no engineering value
- Phase enforcement is purely instructional — no external mechanism, degrades under context pressure
- Step-file architecture accumulates in context — 62KB single workflow files, 96KB of SKILL.md at startup
- Node.js installer copies all skills into ~/.claude/skills/, causing always-on context cost
- Effective score closer to 3/7 when evaluated on implementation rather than feature description

The intersection of methodology tools (design enforcement, mental models, decision trails) and memory tools (persistent knowledge, context snapshots, session continuity) remains unoccupied.

## Key Differentiators

1. **Zero startup cost** — primitives don't register with Claude Code; invisible until invoked
2. **Hook-based enforcement** — mode constraints enforced by bash scripts outside the context window, not by instructions that degrade
3. **Dual-format vault** — human-readable (Obsidian-style knowledge graph) + compiled format (structured markdown optimized for clarity and navigability, not token density). Compiled per-feature, gitignored, regenerated from human files.
4. **Clone-and-study pattern** — research primitive directs model to clone and read production codebases, not rely on training data
5. **Intentional context tax** — context consumed is context the human chose to load, not system overhead

## Tech Stack

- **Core (primitives, vault, toggle, hooks)**: Bash + Markdown. No runtime, no dependencies.
- **Hook scripts**: Bash (runs outside context window)
- **Website (TBD (bocek.com, bocek.dev, or alternative))**: Astro + Bun runtime, deployed to Vercel free tier. Static-first, markdown-native, minimal JS.
- **Tooling scripts (if needed)**: Python or TypeScript depending on task

## Resolved Design Decisions

| ADR | Decision | Key rationale |
|-----|----------|---------------|
| [0001](decisions/0001-dual-format-vault.md) | Dual-format vault (human + machine) | Vault scale exceeds Karpathy single-format threshold |
| [0002](decisions/0002-project-directory-naming.md) | Project directory named `.bocek/` | Unambiguous namespace, consistent with `.git/`, `.vscode/` |
| [0003](decisions/0003-vault-as-knowledge-graph.md) | Vault as knowledge graph, not rigid hierarchy | Structure follows work; Obsidian-style wikilinks + frontmatter |
| [0004](decisions/0004-machine-format-as-compiled-artifact.md) | Machine format is compiled artifact | One-way compilation eliminates sync problem; per-feature scoping |
| [0005](decisions/0005-compiled-format-structure.md) | Compiled format uses structured markdown | Grounded in Vercel/Cline/Anthropic production patterns |
| [0006](decisions/0006-wikilinks-for-vault.md) | Wikilinks for cross-referencing | Obsidian-compatible, not Obsidian-dependent; convention predates tool |
| [0007](decisions/0007-lazy-compilation-in-implementation-primitive.md) | Lazy compilation in implementation primitive | Compile on demand when it matters; no extra hooks or commands |
| [0008](decisions/0008-vault-version-in-index-frontmatter.md) | Vault version in index.md frontmatter | Version marker from day one; migration tooling built when needed |
| [0009](decisions/0009-primitives-are-independent-modes.md) | Primitives are independent modes, not sequential stages | Enforcing sequence cripples engineering thought process |
| [0010](decisions/0010-six-primitives.md) | Six primitives covering full workflow | Design, research, implementation, debugging, refactoring, review |
| [0011](decisions/0011-two-layer-primitive-structure.md) | Two-layer primitive structure (core + references) | Grounded in context rot research and Anthropic's production patterns |
| [0012](decisions/0012-core-vs-reference-split.md) | Core vs reference content split | Core persists in attention; references load just-in-time with triggers |
| [0013](decisions/0013-fluid-cross-feature-design.md) | Fluid cross-feature design | Vault prevents cross-feature hallucination |
| [0014](decisions/0014-tiered-reference-code-access.md) | Tiered reference code access | GH API default, shallow clone fallback, security boundaries |
| [0015](decisions/0015-references-include-codeblock-examples.md) | References include code block examples | Few-shot examples shift probability distribution more than prose |
| [0016](decisions/0016-mental-models-as-domain-activators.md) | Mental models as domain activators, not reasoning scripts | Naming domain + presenting tensions activates latent knowledge without constraining |
| [0017](decisions/0017-claude-code-only-v1.md) | Claude Code only for v1 | No portability abstractions, leverage Claude Code specifics |
| [0018](decisions/0018-three-layer-defense-with-bash-interception.md) | Three-layer defense with Bash interception | Hook + primitive + session restart; catches documented Bash bypass |
| [0019](decisions/0019-toggle-uses-jq-with-backup.md) | Toggle uses jq with backup | Safe JSON manipulation; fails explicitly without jq |
| [0020](decisions/0020-install-follows-bun-pattern.md) | Install follows Bun's pattern | Tool-owned ~/.bocek/ directory, auto shell profile modification |

## Design Dimensions

| Dimension | Design doc | Status |
|-----------|-----------|--------|
| Vault | [vault/design.md](vault/design.md) | Complete |
| Context Engineering | [context-engineering/design.md](context-engineering/design.md) | Complete (research foundation) |
| Primitives — Design | [primitives/design.md](primitives/design.md) | Complete |
| Primitives — Research | [primitives/research.md](primitives/research.md) | Complete |
| Primitives — Implementation | [primitives/implementation.md](primitives/implementation.md) | Complete |
| Primitives — Debugging | [primitives/debugging.md](primitives/debugging.md) | Complete |
| Primitives — Refactoring | [primitives/refactoring.md](primitives/refactoring.md) | Complete |
| Primitives — Review | [primitives/review.md](primitives/review.md) | Complete |
| Mental Models | [mental-models/design.md](mental-models/design.md) | Complete |
| Hook Enforcement | [hooks/design.md](hooks/design.md) | Complete |
| Toggle Script | [toggle/design.md](toggle/design.md) | Complete |
| Install Script | [toggle/install.md](toggle/install.md) | Complete |
| Website | [website/design.md](website/design.md) | Complete |
| Repo Structure | ADR-0022 | Complete |

## Key Trade-offs

- **Activation vs constraint:** Mental models activate latent knowledge by naming domains and tensions, not by prescribing steps. This produces better reasoning but less predictable output.
- **Aggression vs accessibility:** The design primitive challenges the human's reasoning hard — Linus-style. This alienates users who want a helpful assistant. Intentional — Bocek is for people who want correct software, not comfortable interactions.
- **Tokens on design vs tokens on implementation:** The thesis: design tokens are investment tokens, implementation tokens without design are waste tokens. Bocek burns context on design so implementation surfs.
- **Zero startup vs intentional context tax:** Nothing loads until invoked. When it loads, it takes context deliberately. The alternative (BMAD's 67-86% always-on cost) is the anti-pattern.
- **Dual format vs simplicity:** Two vault representations (human + compiled) add complexity but serve different audiences optimally. One-way lazy compilation makes the sync problem disappear.
- **95% enforcement vs 100% enforcement:** The bash hook catches 95%+ of mode violations. Novel bypass patterns require the primitive's instructions (layer 2) or session restart (layer 3). Accepted because 100% enforcement would require AST parsing and a Node.js dependency.

## Risk Register

- **[HIGH]** Primitive instructions degrade in long sessions — context rot is structural, not fixable. Mitigation: two-layer architecture (core persists in high-attention zone), session restart via vault, hook enforcement as backstop.
- **[HIGH]** Design primitive's adversarial behavior may be too aggressive for adoption. Mitigation: this is the thesis, not a bug. The website deprograms users before they use the tool.
- **[MEDIUM]** Compiled vault format needs prototyping — the structure is designed but untested with real vault entries. Mitigation: format is simple structured markdown, easy to iterate.
- **[MEDIUM]** Mental model "when this went wrong" examples need research primitive sessions to populate — v1 may ship with thin examples. Mitigation: the domain tensions are the high-value content; examples enrich over time.
- **[MEDIUM]** jq dependency for toggle script — breaks zero-dependency philosophy for one tool. Mitigation: jq is near-universal on developer machines; the alternative (fragile JSON manipulation) risks breaking Claude Code settings.
- **[LOW]** Wikilinks don't render on GitHub — vault PRs show raw `[[brackets]]`. Mitigation: vault is navigated in editor/Obsidian, not GitHub.
- **[LOW]** Domain name TBD — needs availability check before launch.

## Revisit Triggers

- If context rot research shows future models have uniform attention → revisit two-layer primitive architecture (ADR-0011)
- If compiled vault doesn't measurably improve implementation quality → revisit dual-format (ADR-0001) and compilation approach (ADR-0004)
- If users consistently skip design and go straight to implementation → consider soft nudges, not enforcement (ADR-0009)
- If vault sizes stay small enough that token cost is negligible → revisit dual format vs Karpathy single format (ADR-0001)
- If Anthropic publishes tool-result-level formatting guidance → revisit compiled format structure (ADR-0005)
- If Claude Code adds a CLI for programmatic settings manipulation → revisit toggle's jq-based approach (ADR-0019)
- If demand emerges from users on other AI coding tools → revisit Claude Code only (ADR-0017)

## Design Principles

1. **The model is a dataset, not an engineer.** It has the knowledge of a thousand senior engineers accessed through statistical probability. The primitive's job is to shift that probability from "most common" to "most appropriate."
2. **Design tokens are investment tokens.** Time spent on design compresses implementation. Time spent implementing without design compounds into debugging, refactoring, and rewriting.
3. **The human is the judge.** The model provides evidence, challenges, and execution. The human provides taste, context, and the final call. When the model pushes back, that's the system working.
4. **Activate, don't constrain.** Mental models name the domain and present tensions. They don't tell the model how to think. Naming activates latent knowledge; prescribing steps destroys the model's reasoning capability.
5. **Zero cost until invoked.** Nothing registers at startup. Nothing competes for context. When a primitive loads, it owns the context entirely.
6. **The vault is the product.** The protocol is the engine. The vault is the thing with lasting value. Every future session is smarter than the last because the vault captures decisions, evidence, and reasoning.
7. **Three layers of defense.** Hooks enforce (zero tokens, non-bypassable). Primitive instructions guide (in-context, degrades). Session restart recovers (human decision). Each layer catches what the previous misses.
8. **Aggression is engineering quality.** The model doesn't accommodate weak reasoning — it escalates. Confident-but-wrong gets attacked hardest. Honestly-uncertain gets helped. This is code review, not conversation.

## Build Order

1. **Toggle script + enforcement hook** — `scripts/bocek` and `scripts/enforce-mode.sh`
   - Dependencies: none
   - Validates: hook registration, mode enforcement, jq manipulation
   - Smallest deliverable that proves the infrastructure works

2. **Install script** — `install.sh`
   - Dependencies: toggle script exists
   - Validates: clone, PATH setup, shell detection

3. **Design primitive (core only)** — `primitives/design.md`
   - Dependencies: toggle script (to set mode)
   - The 800-2,000 token core with reference table
   - Test with a real design session — does the adversarial behavior survive?

4. **Design primitive references** — `references/design/*.md`
   - Dependencies: core primitive works
   - Self-attack, concreteness, pattern analysis, examples with code blocks

5. **Vault write system** — vault format, index.md management, state.md
   - Dependencies: design primitive (produces vault entries)
   - Test: does the primitive write well-structured vault entries?

6. **Research primitive (core + references)** — `primitives/research.md` + `references/research/*.md`
   - Dependencies: vault write system
   - Test: clone-and-study pattern, source evaluation, vault output

7. **Mental models (v1 set)** — `mental-models/*.md`
   - Dependencies: design and research primitives (to test activation)
   - 6 domain activators: data-layer, api-design, state-management, distributed-systems, frontend, auth

8. **Implementation primitive (core + references)** — `primitives/implementation.md` + `references/implementation/*.md`
   - Dependencies: vault with decisions and contracts (from steps 3-6)
   - Test: does it follow vault constraints? Does lazy compilation work?

9. **Remaining primitives** — debugging, refactoring, review (cores + references)
   - Dependencies: implementation primitive (produces code to debug, refactor, review)
   - Can be built in parallel

10. **Website** — `website/`
    - Dependencies: all primitives exist (website references them)
    - Astro + Bun, deployed to Vercel
    - Philosophy-first content, 7 sections

## Ready to Build Checklist

- [ ] All 23 ADRs reviewed — no contradictions found
- [ ] All 10 design docs complete — no open questions
- [ ] Risk register acknowledged
- [ ] Build order sequenced with dependencies verified
- [ ] Domain name checked and registered (TBD)
- [ ] GitHub repo created

Open risks to watch during implementation:
- Primitive adversarial behavior may not survive long sessions — test with real design work early
- Compiled vault format needs prototyping — build step 5 before committing to the format
- Mental model examples need research sessions to populate — ship thin, iterate

**Implementation starts in a NEW conversation.** Do not continue the design session into implementation. Fresh context prevents design-phase context rot from leaking into coding decisions.

## Deferred Post-V1

- Multi-agent compatibility (portability beyond Claude Code)
- Team workflows (shared vaults, PR review of vault entries, state.md gitignore rules)
- Additional mental models (concurrency, observability, testing, infrastructure, data-pipeline)
- `bocek uninstall` command
- Vault compaction tooling (human-triggered cleanup and summarization)
