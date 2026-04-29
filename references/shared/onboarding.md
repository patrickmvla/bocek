# Onboarding Bocek to a Project

The preflight classifies the project as one of three states. Each has a different protocol.

## State 1: Greenfield

**Signals:** no vault entries, fewer than 10 source files. Just scaffolding or a fresh repo.

**Protocol:** the first decision is **project shape** — the meta-decision that bounds every other decision. Without it, design output mode-collapses to whatever's most popular in training data, decoupled from your actual constraints.

### Project-shape question set

Capture answers to all of these before the first feature-specific decision. Vault as `_shared/project-shape.md` per the *Path convention*.

1. **What's being built.** One-line description. Owns what; does NOT own what (explicit boundary with adjacent systems).
2. **Scale.**
   - Current load (users, requests/sec, data volume).
   - 6-month target (extrapolation from current trend; medium confidence).
   - 24-month aspirational (depends on business assumptions; low confidence — name them).
3. **Team.**
   - Size, expertise distribution, experience with this domain.
   - Ownership window — how long is this team expected to own this system?
4. **Constraints.**
   - Latency targets (p50, p99 — concrete numbers).
   - Regulatory regime (PCI, HIPAA, SOC2, GDPR — name the ones in scope).
   - Budget (infrastructure, headcount, third-party services).
   - Operational (on-call rotation, page-able incidents per week tolerable, runbook expectations).
5. **Explicit non-goals.** What this system is *not* doing — features deliberately cut from scope, scaling axes deliberately not pursued, integration points deliberately not built. Non-goals are as load-bearing as goals; document them with named reasons.
6. **Success criteria.** How does the team know v1 is done? Concrete, measurable: latency holds, drift below threshold, page rate below threshold, scale assumption verified.

### Bootstrap shortcut

Run `bocek bootstrap` from the project root for an interactive interview that captures these answers and writes the `project-shape.md` entry. Faster than typing it freehand.

### After project-shape is vaulted

Every subsequent decision inherits the project-shape constraints. When a proposal violates one — a decision that requires multi-region against a single-region non-goal, or expands regulatory scope — the proposal must either be rejected or `project-shape.md` must be updated *first* with the named change. Don't let project-shape rot silently while decisions accumulate that contradict it.

---

## State 2: Brownfield with vault

**Signals:** existing source code + at least one vault entry.

**Protocol:** continue. Read `vault/index.md`, check `state.md`, pick up where the previous session left off. Nothing special. The vault is your context.

If `project-shape.md` doesn't exist in the vault but other entries do, the project was either bootstrapped before that convention or migrated in mid-project. Optionally: design a project-shape entry now to capture the implicit constraints. Useful when onboarding new team members.

---

## State 3: Brownfield without vault

**Signals:** existing source code (10+ files), 0 vault entries.

**Protocol:** stop and pick a path before designing forward. Decisions are encoded in the code, in commits, and in the heads of senior engineers — but not vaulted. Designing without a vault here is the worst of both worlds: you'll either ignore existing constraints (proposals conflict with code) or paper over them silently.

### Two paths — the human picks

**Path A: Forward-vault only.** Decide that going forward, all decisions get vaulted. The past is undocumented and accepted. Cheap, immediate. Good when:
- The codebase is small enough that re-deriving constraints from code as you encounter them is fast.
- The team's collective memory still covers most of the load-bearing decisions.
- You're under time pressure and need to start designing the next thing now.

**Path B: Reverse archaeology.** Switch to `/research` mode and selectively reverse-engineer the load-bearing decisions from code + git history + interviews with the human. Higher upfront effort, but creates a working vault. Good when:
- The codebase is large or complex.
- Senior engineers have left and decisions are no longer in heads.
- You're about to make a major change and need to know what you're working against.

When in doubt, default to Path A. Pragmatic beats perfect; an empty vault that grows organically is more useful than an aspirational reverse-archaeology that never finishes.

### Reverse archaeology recipe (Path B)

Follow the *Reading production code* protocol from `/research`, applied to your *own* project:

1. **Identify the 5–10 load-bearing decisions.** Not every detail. Look for: the data model shape (what's the central entity? what's its identity?), the deployment topology (single region? multi-tenant?), the auth / session / identity model, the public API contracts (what do clients depend on?), the third-party integrations (which vendors are load-bearing?), the consistency guarantees (what does the system promise about ordering, idempotency, durability?).
2. **For each decision:**
   - Read the code that implements it (entry point + 3–5 relevant files).
   - Read `git log --all --diff-filter=A -- path/` for the introducing commit and its message.
   - Interview the human about the *why* — what was rejected, what conditions held when this was chosen, what's been considered and stuck since.
3. **Vault each as a decision entry.** Set frontmatter `provenance: archaeology` to mark it as reconstructed (not born-here). Confidence will often be `medium` — you're inferring rationale, not capturing it fresh.
4. **Cap the budget.** 5–10 entries, not 50. Archaeology is high-effort; perfectionism kills the project. Capture what's recoverable; mark the gaps as known unknowns.
5. **Hand off to `/design`.** With the load-bearing decisions vaulted, design forward. New decisions will reference the archaeology entries as constraints they inherit.

### After archaeology

Project-shape can come last, derived from the archaeology entries — by the time you've reverse-engineered the load-bearing decisions, the project's actual constraints are clear. Or skip project-shape entirely if the archaeology entries cover the meta-context implicitly. Pragmatic.

---

## State transitions

A project moves through states naturally:
- Greenfield → brownfield-with-vault (after bootstrap + first feature design)
- Brownfield-without-vault → brownfield-with-vault (after Path A's first vaulted decision, or after Path B's archaeology session)

The preflight re-classifies on every activation; the protocol updates automatically as the vault grows.
