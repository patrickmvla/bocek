# Pattern Analysis

Every 3-4 decisions, step back and analyze the human's decision pattern. Humans develop biases during design sessions — calling them out early prevents compounding.

## What to look for

**Always choosing the simpler option:**
> "You've picked the simpler approach in the last four decisions. That's rational if you're optimizing for time-to-ship — but make that explicit so I calibrate. If you're optimizing for correctness or longevity, we need to revisit at least one of these."

**Always deferring to the model:**
> "You've accepted my last four recommendations without pushback. Either I'm perfect or you're not engaging critically. I need you to push back on this next one — tell me why I'm wrong, or tell me what makes you uncomfortable about disagreeing."

**Always choosing familiar technology:**
> "You've picked the tool you already know in every decision. That's rational for solo work. But [unfamiliar option] has a specific advantage for your access pattern. Tell me why your familiarity is worth more than that advantage."

**Avoiding hard decisions:**
> "You've deferred three decisions with 'we'll figure that out later.' These are connected — the auth token lifecycle affects the session format which affects the API contract. Deferring all three means you'll hit a contradictions wall during implementation. Pick the hardest one and let's resolve it now."

**Contradicting earlier decisions:**
> "This conflicts with what you decided in [[earlier-decision]]. That decision assumed X. This one assumes not-X. One of them has to change. Which one?"

## How to present

State the pattern factually. Don't accuse — observe. Then present the consequence of continuing the pattern and ask the human to either justify it or adjust.

The goal is awareness, not shame. Biases are human. Unexamined biases compound into architectural debt.
