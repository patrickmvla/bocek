# Bocek

A knowledge-grounded engineering methodology engine for AI-assisted development.

Bocek loads mode-specific primitives into Claude Code on demand, enforces design-before-implementation discipline via hooks, and persists all decisions in a dual-format vault that lives in the project repo.

For engineers who want to use the model as a reasoning amplifier instead of a code generator.

## What it does

- **Six primitives** — design, research, implementation, debugging, refactoring, review. Each is an independent mode that shapes how the model operates.
- **Hook enforcement** — a bash script that runs outside the context window, blocking source file writes in reasoning modes (design, research, review). Zero tokens, non-bypassable.
- **Dual-format vault** — human-readable (Obsidian-style knowledge graph) + compiled (structured markdown optimized for LLM consumption). Decisions, research, and contracts persist across sessions.
- **Mental models** — domain activators that shift the model's probability distribution by naming tensions and surfacing hard-won insights. Not checklists.
- **Idioms** — ecosystem-specific quality bars (TypeScript, Go, Rust, Python, …). Concrete answers to *"what's idiomatic for this stack?"* — auto-suggested by the preflight when it detects the matching language signal.
- **Zero startup cost** — nothing registers with Claude Code until invoked. No context tax until you choose to load a primitive.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/patrickmvla/bocek/main/install.sh | bash
```

Requires: git, curl, jq.

### Upgrading from an earlier install

If you installed Bocek before slash commands landed, your `~/.bocek/` will have primitive files nested at `~/.bocek/primitives/primitives/` — the paths primitives reference are broken.

Re-run the install command above. The installer detects the old layout, relocates the checkout to `~/.bocek/.repo`, and symlinks `primitives/`, `references/`, and `mental-models/` into place. `bocek update` does **not** perform this migration — you must re-run the `curl` command once.

## Usage

```bash
# Navigate to your project
cd your-project

# Activate Bocek hooks + install slash commands
bocek on

# Start Claude Code, then switch modes with a slash command:
#   /design  /research  /implementation  /debugging  /refactoring  /review
```

`bocek on` installs six project-scoped slash commands at `.claude/commands/` and registers a `SessionStart` hook that tells Claude the current mode and available commands. The previous workflow — pasting `Read ~/.bocek/primitives/design.md and follow it` — still works as a fallback.

### Commands

| Command | What it does |
|---------|-------------|
| `bocek on` | Register enforcement hooks in this project |
| `bocek off` | Remove hooks from this project |
| `bocek status` | Show hook, mode, vault, and primitive status |
| `bocek update` | Pull latest primitives and scripts |
| `bocek bootstrap` | Greenfield onboarding — interactive interview that captures *project shape* (what / scale / team / constraints / non-goals / success criteria) and writes the meta-decision every other decision inherits from |
| `bocek vault organize` | Migrate loose vault entries (those written directly to `vault/` instead of `vault/{feature}/`) into their correct feature folders, derived from each entry's `features:` frontmatter |

### Onboarding

Bocek classifies the project into one of three states on every preflight:

- **Greenfield** (no vault, minimal code) — run `bocek bootstrap` for an interactive project-shape interview, then `/design` for the first feature.
- **Brownfield with vault** — `/design`, `/research`, etc. work as documented; the vault is your context.
- **Brownfield without vault** — the preflight prompts you to choose: forward-vault only (vault from now on, accept the past is undocumented) or reverse archaeology (research mode reads code + git log to extract the load-bearing decisions). See `~/.bocek/references/shared/onboarding.md`.

Existing project with loose vault entries from earlier sessions? Run `bocek vault organize` to migrate them into the correct `{feature}/` folders.

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

1. **Run a slash command** — e.g. `/design` in Claude Code. The command body invokes `~/.bocek/scripts/preflight.sh design`.
2. **Preflight orients the model** — sets `.bocek/mode`, prints prior mode + vault state + recent checkouts + project signals (greps `package.json`/`go.mod`/`Cargo.toml`/`pyproject.toml`/etc.) + suggested mental models + eager references for the mode. The model reads this before forming any response.
3. **The primitive loads** — reads the eager references the preflight named, scans `.bocek/vault/index.md` and `.bocek/state.md`, then acknowledges the orientation in one line before operating.
4. **The hook enforces constraints** — `enforce-mode.sh` runs outside the context window, blocking source file writes in reasoning modes, allowing vault writes.
5. **Work produces vault entries** — decisions, research, contracts saved to `.bocek/vault/`.
6. **Modes hand off explicitly** — every primitive has a `Handoff` section naming valid successors and the contract each requires (e.g. `/design` → `/implementation` only when the vault entry contains chosen path + rejected alternative + implementable contract). The model proposes the switch; the human runs the slash command.
7. **Implementation reads the vault** — compiled context constrains what code gets written.
8. **The vault travels with the code** — committed to the repo, available to every future session.

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
