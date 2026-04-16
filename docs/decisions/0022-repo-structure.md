# ADR-0022: Repository Structure

## Status
Accepted

## Context
The repository serves multiple purposes: it's what gets cloned to `~/.bocek/` during install (primitives, references, mental models, scripts), it contains the website source, and it contains the design documentation. The structure must be clear enough that the install script can copy the right files to the right places.

## Decision

```
bocek/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── install.sh
│
├── primitives/
│   ├── design.md
│   ├── research.md
│   ├── implementation.md
│   ├── debugging.md
│   ├── refactoring.md
│   └── review.md
│
├── references/
│   ├── shared/
│   │   ├── vault-format.md
│   │   └── session-continuity.md
│   ├── design/
│   │   ├── self-attack.md
│   │   ├── concreteness.md
│   │   ├── pattern-analysis.md
│   │   └── examples.md
│   ├── research/
│   │   ├── research-format.md
│   │   ├── source-evaluation.md
│   │   ├── code-reading.md
│   │   ├── web-research.md
│   │   ├── academic-integration.md
│   │   └── cross-referencing.md
│   ├── implementation/
│   │   ├── contract-following.md
│   │   ├── verification.md
│   │   ├── gap-flagging.md
│   │   ├── code-quality.md
│   │   └── integration-verification.md
│   ├── debugging/
│   │   ├── trace-protocol.md
│   │   ├── root-cause-classification.md
│   │   ├── constraint-preserving-fix.md
│   │   ├── design-gap-report.md
│   │   └── discovery-format.md
│   ├── refactoring/
│   │   ├── behavior-mapping.md
│   │   ├── refactoring-plan.md
│   │   ├── incremental-execution.md
│   │   ├── unknown-code-protocol.md
│   │   ├── contract-change-flag.md
│   │   └── behavior-verification.md
│   └── review/
│       ├── vault-compliance.md
│       ├── finding-classification.md
│       ├── undocumented-behavior.md
│       ├── review-output.md
│       └── severity-assessment.md
│
├── mental-models/
│   ├── data-layer.md
│   ├── api-design.md
│   ├── state-management.md
│   ├── distributed-systems.md
│   ├── frontend.md
│   └── auth.md
│
├── scripts/
│   ├── bocek
│   └── enforce-mode.sh
│
├── website/
│   ├── package.json
│   ├── bun.lock
│   ├── astro.config.mjs
│   ├── src/
│   │   ├── pages/
│   │   ├── layouts/
│   │   ├── content/
│   │   └── styles/
│   └── public/
│
└── docs/
    ├── overview.md
    ├── vault/design.md
    ├── primitives/
    │   ├── design.md
    │   ├── research.md
    │   ├── implementation.md
    │   ├── debugging.md
    │   ├── refactoring.md
    │   └── review.md
    ├── context-engineering/design.md
    ├── mental-models/design.md
    ├── hooks/design.md
    ├── toggle/design.md
    ├── toggle/install.md
    ├── website/design.md
    └── decisions/
        ├── 0001-dual-format-vault.md
        └── ... through 0022
```

### Install mapping

The install script clones the entire repo to a temporary location, then copies specific directories to `~/.bocek/`:

| Repo path | Install destination | Purpose |
|-----------|-------------------|---------|
| `primitives/` | `~/.bocek/primitives/` | Core primitive files |
| `references/` | `~/.bocek/references/` | On-demand reference files |
| `mental-models/` | `~/.bocek/mental-models/` | Domain activators |
| `scripts/bocek` | `~/.bocek/bin/bocek` | Toggle script |
| `scripts/enforce-mode.sh` | `~/.bocek/scripts/enforce-mode.sh` | Hook enforcement |

The `website/` and `docs/` directories stay in the repo — they don't get installed to `~/.bocek/`.

### Primitive path references

Each primitive's reference table points to `~/.bocek/references/{primitive}/` — the installed location, not the repo path. For example, the design primitive's core says:

```
| When | Read |
|------|------|
| Attacking your own recommendation | ~/.bocek/references/design/self-attack.md |
```

Mental models are referenced as `~/.bocek/mental-models/{domain}.md`.

## Alternatives Considered
**Flat references directory:** All 30+ reference files in one folder. Rejected because it's hard to navigate and unclear which references belong to which primitive.

**References inside each primitive's directory:** `primitives/design/references/self-attack.md`. Rejected because shared references would need symlinks or duplication. A separate `references/` directory with a `shared/` subdirectory is cleaner.

**Monorepo with website in a separate repo:** Would separate concerns but add complexity to versioning — primitives and website should evolve together.

## Consequences
- **Positive**: Clear separation between installable content (primitives, references, mental models, scripts) and non-installable content (docs, website)
- **Positive**: Nested references are navigable and scoped to each primitive
- **Positive**: Install script has a clean mapping from repo paths to install destinations
- **Negative**: Shared references need explicit placement in `references/shared/` — but there are only ~2 shared files
