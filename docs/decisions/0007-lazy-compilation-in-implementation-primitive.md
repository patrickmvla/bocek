# ADR-0007: Lazy Compilation Triggered by Implementation Primitive

## Status
Accepted

## Context
The compiled vault files (`.bocek/vault/.compiled/`) need to stay current with the human-format source files. Three triggers were considered: manual command, primitive-driven (on demand), and hook-driven (automatic on write).

## Decision
Compilation is triggered by the implementation primitive at load time. When the primitive needs vault context for a feature, it checks whether `.compiled/{feature}.md` is stale relative to source files, and recompiles if needed. No separate command, no hook, no eager compilation.

## Alternatives Considered
**Manual command (`bocek compile`):** Simple but easy to forget. Stale compiled files are a silent failure — the model would implement against outdated constraints without warning.

**Hook-driven (recompile on vault write):** Automatic but adds complexity to the hook layer. Also wasteful — compiled files have no consumer during design or research modes. Recompiling after every vault write burns cycles for no audience.

## Consequences
- **Positive**: Guaranteed fresh at the only moment it matters — when the model is about to implement
- **Positive**: Zero human responsibility — no command to remember
- **Positive**: No extra hooks — keeps the hook layer simple (mode enforcement only)
- **Positive**: Lazy evaluation — no wasted work during design/research phases
- **Negative**: First implementation load after heavy design work may have a noticeable compilation pause
- **Negative**: Compilation logic lives inside the primitive, coupling the primitive to vault format knowledge

## Revisit When
- If compilation becomes slow enough to disrupt the implementation flow
- If other consumers of compiled files emerge (CI/CD, external tools, team workflows)
