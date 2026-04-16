# Bocek

A knowledge-grounded engineering methodology engine for AI-assisted development.

Bocek loads mode-specific primitives into Claude Code on demand, enforces design-before-implementation discipline via hooks, and persists all decisions in a dual-format vault that lives in the project repo.

For engineers who want to use the model as a reasoning amplifier instead of a code generator.

## What it does

- **Six primitives** — design, research, implementation, debugging, refactoring, review. Each is an independent mode that shapes how the model operates.
- **Hook enforcement** — a bash script that runs outside the context window, blocking source file writes in reasoning modes (design, research, review). Zero tokens, non-bypassable.
- **Dual-format vault** — human-readable (Obsidian-style knowledge graph) + compiled (structured markdown optimized for LLM consumption). Decisions, research, and contracts persist across sessions.
- **Mental models** — domain activators that shift the model's probability distribution by naming tensions and surfacing hard-won insights. Not checklists.
- **Zero startup cost** — nothing registers with Claude Code until invoked. No context tax until you choose to load a primitive.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/patrickmvla/bocek/main/install.sh | bash
```

Requires: git, curl, jq.

## Usage

```bash
# Navigate to your project
cd your-project

# Activate Bocek hooks
bocek on

# Start Claude Code and load a primitive
# "Read ~/.bocek/primitives/design.md and follow it"
```

### Commands

| Command | What it does |
|---------|-------------|
| `bocek on` | Register enforcement hooks in this project |
| `bocek off` | Remove hooks from this project |
| `bocek status` | Show hook, mode, vault, and primitive status |
| `bocek update` | Pull latest primitives and scripts |

### Modes

| Mode | Purpose | Source writes |
|------|---------|-------------|
| **design** | Force every decision to survive informed challenge | Blocked |
| **research** | Gather evidence from code, web, and academic sources | Blocked |
| **implementation** | Write code constrained by vault decisions | Allowed |
| **debugging** | Evidence-first diagnosis, vault-aware fixes | Allowed |
| **refactoring** | Change structure without changing behavior | Allowed |
| **review** | Detect drift between code and vault | Blocked |

## How it works

1. **Load a primitive** — tell Claude to read `~/.bocek/primitives/design.md` (or any mode)
2. **The primitive sets the mode** — writes `design` to `.bocek/mode`
3. **The hook enforces constraints** — blocks source file writes in reasoning modes, allows vault writes
4. **Work produces vault entries** — decisions, research, contracts saved to `.bocek/vault/`
5. **Implementation reads the vault** — compiled context constrains what code gets written
6. **The vault travels with the code** — committed to the repo, available to every future session

## Vault

The vault lives at `.bocek/vault/` in your project. It's committed to git (except `.compiled/` and `mode`).

```
.bocek/
  vault/
    index.md                  ← entry point, auto-maintained
    .compiled/                ← gitignored, per-feature compiled files
    checkout/
      optimistic-locking.md   ← decision
      stripe-research.md      ← research
      api-contract.md         ← contract
  mode                        ← current mode (gitignored)
  state.md                    ← session continuity
```

## Design philosophy

The model is a dataset, not an engineer. It has the knowledge of a thousand senior engineers accessed through statistical probability. The primitive's job is to shift that probability from "most common" to "most appropriate."

Design tokens are investment tokens. Implementation tokens without design are waste tokens.

The human is the judge. The model provides evidence, challenges, and execution. The human provides taste, context, and the final call.

## License

MIT
