## Current state
- **Mode:** design
- **Feature:** _shared (vault path conventions)
- **Last resolved:** [[mandatory-feature-folders]]
- **In progress:** alignment work pending — (1) mark ADR-0003 status as Superseded with reference to the new entry, (2) move Path convention to the top of `references/shared/vault-format.md`, (3) prime each primitive's "On activation" section with a one-line path-convention reminder, (4) tighten `scripts/enforce-mode.sh` to block flat-vault writes structurally.
- **Next:** switch to /implementation to land items 1-4. Item 4 is the load-bearing one — without it the decision is doctrine without enforcement, which is the exact failure this entry corrects.

## Session history
- 2026-05-02 — Diagnosed `scripts/preflight.sh` path-doubling and stale-mode bugs. Fix landed: walk-up `find_project_root` with cruft-skip heuristic + read-back verification on mode write. Repo source and install copy synced.
- 2026-05-02 — Discovered doctrinal contradiction between ADR-0003 (feature folders optional) and vault-format.md / primitives / preflight (feature folders mandatory). Classified as design gap, not implementation bug.
- 2026-05-02 — Onboarded bocek-the-project to its own vault (Path A: forward-vault only). First vault entry: [[mandatory-feature-folders]], superseding ADR-0003 at the path layer.
