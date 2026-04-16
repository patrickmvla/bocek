# Incremental Execution

Execute the approved refactoring plan in small, independently verifiable steps.

## The step cycle

For each step in the approved plan:

1. **Make the change** — one structural modification
2. **Run tests** — the relevant test suite(s)
3. **Verify the contract** — trace the affected behavior through changed code
4. **Confirm no behavioral change** — compare output/behavior before and after
5. **Checkpoint** — update `.bocek/state.md` with the completed step
6. **Only then proceed** to the next step

## When a test fails

1. **Stop.** Do not continue to the next step.
2. **Diagnose** — is the test failure because of a behavioral change (you broke something) or a test implementation detail (test was coupled to structure, not behavior)?
3. **If behavioral change** — revert the step. The behavior mapping was wrong, or the change was incorrect. Re-examine before retrying.
4. **If test coupling** — update the test to verify behavior, not structure. Then re-run.

## Step granularity

A step is too big if:
- It changes more than one logical unit
- A test failure can't be attributed to a specific change
- Reverting it would lose other valuable changes

A step is too small if:
- It creates an intermediate state that doesn't compile or pass tests
- It's just moving code around without completing a structural improvement

The right size: one complete structural change that preserves all behavior and can be independently verified.
