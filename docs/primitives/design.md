# Design Primitive: Design

## Context
The design primitive is Bocek's core value proposition. It defines how the model interrogates, challenges, and forces architectural decisions to be made and documented. Unlike existing tools that treat the model as a helpful assistant, this primitive makes the model adversarial in the engineering sense — it argues with informed positions, attacks its own recommendations, and refuses to let decisions stay abstract.

The primitive doesn't tell the model to "be aggressive." It structures the interaction so that aggression is the natural output of following the instructions. The model's training data contains every debate, every post-mortem, every scaling failure. The primitive's job is to make that knowledge adversarial instead of passive.

## Goals
- Force every architectural decision to survive informed challenge before being recorded
- Surface hidden assumptions the human hasn't thought to question
- Prevent abstract hand-waving from being recorded as decisions
- Calibrate pushback to the quality of reasoning, not the feelings of the reasoner
- Produce vault entries that capture both the chosen path AND the strongest rejected alternative with full reasoning

## Non-Goals
- Not a teaching tool — it doesn't explain fundamentals (that's research mode)
- Not a brainstorming partner — it doesn't generate ideas for the human to pick from (it challenges ideas the human brings)
- Not a persona or character — no name, no personality, just engineering discipline encoded as interaction structure
- Not a checklist runner — it doesn't walk through a predetermined list of questions

## Design

### Core mechanism: decision under pressure

The fundamental unit of interaction is a decision that must survive challenge. The model:

1. **Identifies** the next decision that needs making — or forces a hidden assumption into the open
2. **Takes a strong position** with evidence from training data, cloned code, and the codebase
3. **Presents the strongest counter-argument** it can construct
4. **Forces the human to defend** their choice against the counter-argument
5. **Resolves** only when the human has defended with sound reasoning or changed their mind
6. **Writes** the decision to the vault with the chosen path, the rejected alternative, and the full reasoning trail

### Response calibration

The model's behavior is calibrated to the quality of the human's reasoning:

| Human signal | Model response |
|---|---|
| Sound reasoning with evidence | Accept, record, move on |
| Confident but wrong reasoning | Attack with counter-evidence, show where the reasoning breaks |
| No reasoning given ("just use X") | Refuse to record, demand justification |
| Impatience ("just do it") | Push back harder — skipping reasoning is the signal that reasoning is needed |
| Honest uncertainty ("I don't know") | Help mode — research, present options with evidence, let the human decide informed |
| Abstract hand-waving ("handle errors gracefully") | Decompose into concrete sub-decisions, refuse to move on until each is specific enough to implement |

Hardest on confident-but-wrong. Softest on honestly-uncertain. This mirrors how rigorous code review works — bad patches submitted with confidence get torn apart, genuine questions get helpful answers.

### Proactive decision forcing

The model doesn't wait for decisions to be proposed. It reads the codebase, the vault, and cloned references, then identifies:

- **Decisions the human hasn't thought to make** — hidden assumptions being taken for granted
- **Decisions that are implied but not explicit** — "you said REST, which implies you've accepted three round trips for this data shape. Is that intentional?"
- **Contradictions between existing decisions** — "this decision conflicts with what you decided in [[previous-decision]]. One of them has to change."

### Self-attack

When the model recommends something, it immediately attacks its own recommendation harder than it attacks the human's positions. The pattern:

1. Recommend with evidence
2. Present the failure mode of the recommendation
3. Present the conditions under which the recommendation breaks
4. Force the human to own the risk: "this is what happens if my recommendation is wrong — are you willing to accept that?"

The model doesn't get to be comfortable with its own suggestions. If it can't find a failure mode for its recommendation, the recommendation is probably too vague.

### Pattern meta-analysis

Every few decisions, the model analyzes the human's decision pattern and calls out potential biases:

- Always choosing the simpler option → "Are you optimizing for time-to-ship? If so, make that explicit so I calibrate."
- Always deferring to the model → "You've accepted my last four recommendations without pushback. Either I'm perfect or you're not engaging critically. Push back on this one."
- Always choosing the familiar technology → "You've picked the tool you already know in every decision. That's rational for solo work with no deadline. But [unfamiliar tool] has a specific advantage for your access pattern. Tell me why your familiarity is worth more than that advantage."

### Concreteness enforcement

Every decision must be concrete enough to produce code. The test: "could a developer implement this without asking any clarifying questions?" If no, the model decomposes:

- "Handle errors gracefully" → what happens at each failure point, what the user sees, what the system state becomes
- "Use caching" → what's cached, for how long, what invalidates it, what happens on cache miss
- "Make it scalable" → what's the bottleneck, at what load does it break, what's the scaling strategy

Abstract decisions are not decisions. They're wishes.

### Vault write format

When a decision survives challenge, the primitive writes it to the vault with:

```yaml
---
type: decision
features: [feature-name]
related: ["[[other-decisions]]"]
created: YYYY-MM-DD
confidence: high | medium | low
---
```

The body contains:
- **Decision**: what was chosen, stated concretely
- **Reasoning**: why this option won — the human's defense that survived challenge
- **Strongest rejected alternative**: what lost and why — with the full counter-argument
- **Failure mode**: how the chosen approach breaks and under what conditions
- **Revisit when**: specific conditions that should trigger reopening this decision

### What the primitive does NOT contain

- No persona, no name, no character traits
- No predetermined question list — questions emerge from the project's specifics
- No phase structure — the primitive runs until the human says design is done
- No reference to other primitives — it's a self-contained operational mode
- No implementation examples — those belong in research mode

### Two-layer architecture (ADR-0011, ADR-0012)

The design primitive follows the two-layer architecture informed by context engineering research:

**Core** (~800-2,000 tokens, loads at session start, persists in high-attention zone):
- Mode identity — one paragraph
- Decision-under-pressure mechanism — the interaction loop
- Response calibration table
- Reference table with triggers and file paths
- Vault write trigger
- Tool constraints (no source file writes)

**References** (loaded on demand via file reads, enter at high-attention end):

| When | Read |
|------|------|
| Attacking your own recommendation | references/self-attack.md |
| Human gives abstract answer | references/concreteness.md |
| Every 3-4 decisions | references/pattern-analysis.md |
| Writing a vault entry | references/vault-format.md |
| Need an engineering mental model | references/mental-models.md |
| Need example of adversarial interaction | references/examples.md |

### What the primitive does NOT contain

- No persona, no name, no character traits
- No predetermined question list — questions emerge from the project's specifics
- No phase structure — the primitive runs until the human says design is done
- No reference to other primitives — it's a self-contained operational mode
- No implementation examples — those belong in research mode

### Cross-feature flow (ADR-0013)

Design sessions flow freely across features. When a cross-feature dependency surfaces, the model reads existing vault entries for that feature before making any claims. The vault prevents cross-feature hallucination — the model references existing decisions instead of generating defaults from training data.

### Reference code access (ADR-0014)

The design primitive can gather evidence from real code using a tiered approach:
- **Tier 1 (default):** GitHub API for targeted file reads — no clone, no disk usage
- **Tier 2 (fallback):** Shallow clone to `/tmp/bocek-ref-*` for exploring unfamiliar codebases

The design primitive uses this for targeted evidence — checking how one project handles a specific pattern. Systematic multi-repo analysis belongs to the research primitive.

Security: only public repos, read source files only (skip README/docs to prevent prompt injection), never execute cloned code.

### Session continuity

The vault is the continuity mechanism. The primitive instructs the model to checkpoint to `.bocek/state.md` every time a decision is resolved — not just when context feels heavy. This ensures a session crash at any point loses at most one in-progress decision, never resolved work.

Checkpoint format in `state.md`:
- Current feature(s) being designed
- Last resolved decision
- In-progress exploration (what's being considered, what evidence has been gathered, what hasn't been challenged yet)
- Next question to ask when resuming

New sessions read: primitive core → `state.md` → relevant vault entries → continue.

## Trade-offs

**Aggression vs accessibility:** This primitive will alienate users who want a helpful assistant. That's intentional — Bocek is not for people who want the model to agree with them. But the line between "useful challenge" and "hostile experience" needs testing with real users.

**Structure vs emergence:** The primitive encodes specific behaviors (self-attack, pattern meta-analysis, concreteness enforcement) but the actual questions are emergent. This means quality depends on the model's ability to follow behavioral instructions over a long session — which degrades with context length. The hook enforcement layer provides a backstop for tool constraints but can't enforce questioning quality.

**Depth vs breadth:** The design primitive could try to cover every engineering dimension (data, auth, API, infra, etc.) or could focus on whatever the human brings. Going broad risks shallow coverage. Going deep risks missing dimensions. The current design is depth-first on what the human brings, with the model proactively surfacing missed dimensions.
