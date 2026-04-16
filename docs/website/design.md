# Website: Design

## Context
The website (`bocek.dev`) is the human's primitive. The model has its primitives on disk — markdown files that shape how it reasons. The human has theirs at `bocek.dev` — content that shapes how they think about engineering with LLMs.

The human arrives with the market's mental model: "AI writes code, I supervise." The website breaks that and replaces it with: "I make decisions grounded in evidence, the model provides the evidence and challenges my reasoning."

This is deprogramming, not documentation.

## Goals
- Upgrade the human's mental model of AI-assisted engineering before they touch the tool
- Make the value of grounded decisions visceral — show what happens without them
- Teach engineering thinking, not Bocek features — the tool is secondary to the methodology
- Make the human feel capable, not dependent — they are the judge, not the observer

## Non-Goals
- Not a feature comparison site — no "Bocek vs X" tables
- Not a marketing site — no testimonials, no "trusted by" logos, no hype
- Not an API reference — commands and file formats live in the repo README
- Not comprehensive documentation — the primitives themselves are the documentation for the model

## Design

### The principle: content is about engineering, not about Bocek

A human who understands why Bocek exists will figure out the commands. A human who follows commands without understanding will use Bocek like every other tool — badly. The website's job is to upgrade the human. Everything else follows.

### Content structure

**1. The Problem**

Not "AI tools are bad." Instead: here's exactly how mediocre software gets made and why you're probably doing it right now.

- The model gets "build me a checkout API" and generates route handlers from training data defaults. No one asked about inventory locking strategy. No one checked how Stripe actually handles idempotency. No one documented why REST instead of GraphQL.
- Six months later, the inventory system deadlocks under load. The developer asks the model to fix it. The model doesn't know the locking strategy was a deliberate decision (because it wasn't). It "fixes" the deadlock by removing the lock. Now inventory goes negative.
- This is compounding. Every ungrounded decision makes the next decision worse because the model has less ground truth to reason from.

Show real failure cascades. Make the reader uncomfortable recognizing their own workflow.

**2. The Shift**

The single most important mental model change:

The LLM is a prediction engine with an enormous dataset and zero judgment. It uses next-best-token prediction to produce the most statistically likely output. The majority of its training data is mediocre code. Therefore the default output is mediocre by definition.

But the model KNOWS about every pattern, every architecture, every post-mortem, every scaling failure. It has the knowledge of a thousand senior engineers — accessed through the lens of statistical probability.

When you treat it as an executor ("build me X"), you get the average of all the X's in its training data. When you treat it as an evidence source ("show me how production systems handle X, then challenge my approach"), you get the best of its training data filtered through your judgment.

The model becomes your weapon, not your crutch. Your decisions get better because they're informed by evidence you could never gather alone. The model doesn't make you lazier — it makes you more dangerous.

**3. What Changes**

The workflow after the shift:

- You design before you implement. Not because a tool forces you, but because you understand that design tokens are investment tokens and implementation tokens without design are waste tokens.
- Every decision has evidence behind it. Not "I think REST is right" but "Stripe uses REST for their public API because their consumers need cacheable, stateless requests — and our consumers have the same pattern."
- The vault captures everything. Not as documentation overhead, but as ammunition for every future session. New session reads the vault and continues from where you left off — with full context, not a blank slate.
- Sessions are disposable. Knowledge is permanent. You restart when context degrades. The vault means nothing is lost.
- The model pushes back. When it challenges your decision, that's not friction — that's the system working. When you override it, your reason gets recorded. Six months from now, someone reads that reason and understands why.

**4. The Human's Role**

You are the judge. This is not metaphorical.

- You provide taste — the model doesn't know what "good" means for your project. You do.
- You provide context — the model doesn't know your team, your deadline, your users. You do.
- You provide the final call — the model presents evidence, challenges, alternatives. You decide.
- You own the outcome — when the model pushes back and you override it, you're accepting the risk. The vault records it. You can't blame the AI later.

When the human shows weak technical reasoning, the model doesn't accommodate — it escalates. This is Linus reviewing kernel patches. He doesn't care about your feelings. He cares about the code, the logic, and whether your reasoning holds. Bocek's design primitive does the same — not because it has a persona, but because the structure forces it.

The human who uses Bocek gets smarter through the interaction. Not lazier. Every session produces decisions the human can defend, research the human can reference, and code the human understands. That's the product — not the code, the human.

**5. Getting Started**

Now — with the philosophy internalized — the commands make sense:

```bash
curl -fsSL bocek.dev/install | bash
```

Navigate to your project. Activate. Load a primitive. Start designing. The model challenges you. You defend or adapt. Decisions go to the vault. When you're ready, switch to implementation. The model writes code constrained by your decisions. Nothing is improvised.

Minimal instructions here. The philosophy pages did the heavy lifting. The human knows WHY each step exists.

**6. The Modes**

Not "here's what each mode does" but "here's when you need each mode and what it demands from you."

- **Design** demands that you defend every decision. It will attack your reasoning. It will attack its own recommendations. It won't let you hide behind abstractions.
- **Research** demands that you direct the investigation or let the model find the gaps. It clones real code, reads real docs, and produces evidence with citations — not summaries.
- **Implementation** demands that your design is complete. It reads the vault. It follows the contracts. When a decision is missing, it stops and tells you. It won't improvise.
- **Debugging** demands error evidence. No vibes. Bring the stack trace. It reads the vault to understand what's designed vs what's broken.
- **Refactoring** demands patience. It reads every line before touching anything. It won't change code it doesn't understand. It asks you about the code you can't explain either.
- **Review** demands honesty. It compares your code to your vault decisions. It finds where you drifted. It doesn't care if the drift was convenient.

Each mode demands something from the human. That's by design.

**7. The Vault**

Not file format documentation. Instead:

Here's a project after 3 months without a vault: the developer asks the model to add a feature. The model doesn't know the auth system uses JWT with 15-minute expiry. It generates session-based auth. Now the project has two auth systems. Nobody knows why.

Here's the same project after 3 months with a vault: the developer loads the implementation primitive. The model reads the compiled vault. It knows auth uses JWT. It knows the API contract. It knows optimistic locking was chosen because write volume is low. It implements the feature within those constraints. Every line traces to a decision.

The vault is the difference between a codebase that makes sense and one that doesn't. It's not overhead — it's the thing that makes every future session smarter than the last.

### Technical implementation

- **Astro** — static site, markdown-native, minimal JS
- **No analytics beyond basic page views** — we don't track users
- **No signup, no email capture** — the tool is the product, not the mailing list
- **Dark theme by default** — this is for engineers, not marketing
- **Fast** — every page loads instantly, no layout shift, no hero animations

### What the website does NOT have

- No feature comparison tables
- No pricing page (Bocek is free and open source)
- No testimonials or social proof
- No "getting started" video (text is faster and searchable)
- No blog (the vault and the primitives evolve — the website teaches timeless principles)
- No changelog (that lives in the repo)
- No community/Discord link (the GitHub repo is the community)

## Trade-offs

**Philosophy-heavy vs quick-start:** A developer who just wants to try the tool has to read through philosophy before they find the install command. This is intentional — a developer who skips the philosophy will misuse the tool. But it means higher bounce rate from people who want instant gratification. Accepted — those users aren't the target audience.

**No marketing vs discoverability:** Without comparison tables, SEO-optimized feature lists, and social proof, the site won't rank for "AI coding tools." Accepted — Bocek grows through engineers who've used it and tell other engineers. The product sells itself to people who understand the problem.

**Text-only vs interactive demos:** Interactive demos would be more engaging. Rejected for v1 — the website's job is to change thinking, not demonstrate features. Text forces the reader to engage with the ideas rather than passively watching a demo.

## References
- ADR-0020: Install follows Bun's pattern (install command referenced in Getting Started)
- Your design document: "The website is the human's primitive"
