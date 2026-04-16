# ADR-0020: Install Script Follows Bun's Pattern with Tool-Owned Directory

## Status
Accepted

## Context
The install script needs to place Bocek's files on the user's machine and ensure the `bocek` command is in PATH. Research into how production CLI tools handle this:

| Tool | Binary location | PATH strategy |
|------|----------------|---------------|
| Bun | `~/.bun/bin/` | Auto-modifies shell profiles |
| Rust/Cargo | `~/.cargo/bin/` | Auto-modifies shell profiles |
| Deno | `~/.deno/bin/` | Prints manual instructions |
| Claude Code | `~/.claude/bin/` | Native installer handles |

Every major tool uses a tool-owned directory, not `~/.local/bin/` or `/usr/local/bin/`. This avoids collisions and makes uninstallation clean.

Bun's install script is the gold standard for `curl | bash` installers: platform detection, shell detection via `basename "$SHELL"`, idempotent PATH modification, graceful fallback to manual instructions when config isn't writable.

## Decision
Follow Bun's installation pattern:

**Directory structure:**
```
~/.bocek/
  bin/bocek              ← toggle script
  scripts/enforce-mode.sh ← hook enforcement
  primitives/            ← cloned from repo (design.md, research.md, etc.)
    references/          ← mental models, examples, format templates
```

**PATH modification:**
- Detect shell via `basename "$SHELL"`
- Check if `~/.bocek/bin` is already in PATH (`command -v bocek`)
- If not, auto-append `export PATH="$HOME/.bocek/bin:$PATH"` to:
  - `~/.zshrc` for zsh
  - `~/.bashrc` for bash
  - `~/.config/fish/config.fish` for fish
- If config not writable, print manual instructions
- Never duplicate — check before appending

**Everything under `~/.bocek/`** — one directory, clean uninstall, no collisions.

## Alternatives Considered
**`~/.local/bin/bocek`:** XDG standard location. Rejected because every major CLI tool (Bun, Rust, Deno, Claude Code) uses a tool-owned directory instead. XDG is a shared namespace — uninstallation requires knowing which files belong to which tool.

**`/usr/local/bin/bocek`:** Requires sudo. Rejected — no install script should require elevated privileges for a user-space tool.

**Manual PATH setup (Deno approach):** Simpler script but worse user experience. Rejected — Bun proved that auto-modification with graceful fallback is the better pattern.

## Consequences
- **Positive**: Clean uninstall — `rm -rf ~/.bocek` removes everything
- **Positive**: No collisions with other tools
- **Positive**: Follows the pattern users expect from modern CLI tools
- **Positive**: Shell profile modification is idempotent and graceful
- **Negative**: Modifying shell profiles is invasive — but every major tool does it, and users expect it
- **Negative**: User must open a new terminal after install (or `source` their config)

## References
- Bun install script: https://bun.sh/install
- Rust/Cargo install: https://rust-lang.github.io/rustup/installation/
- Claude Code install: https://code.claude.com/docs/en/setup
