# ADR-0014: Tiered Approach to Reference Code Access

## Status
Accepted

## Context
Bocek's design and research primitives need to read production codebases to ground decisions in real code rather than training data. The approach must balance speed, disk usage, security, and the model's need to explore unfamiliar codebases.

Three mechanisms exist: GitHub API (no clone), shallow clone, and sparse checkout with partial clone. Each has different tradeoffs. Additionally, prompt injection via cloned repositories is a documented security threat — malicious README files or comments can contain instructions that override agent behavior.

## Decision
Reference code access uses a tiered approach:

**Tier 1 — GitHub API (default):** For reading specific known files. No clone, no disk usage, fastest. Uses `gh api repos/owner/repo/contents/path --jq '.content' | base64 -d` or `gh api repos/owner/repo/git/trees/branch --jq '.tree[].path'` for directory listing. Use this when the model knows what it's looking for.

**Tier 2 — Shallow clone (fallback):** For exploring unfamiliar codebases. `git clone --depth 1 https://github.com/owner/repo.git /tmp/bocek-ref-{repo-name}`. Use when the model needs to browse structure, read multiple related files, or doesn't know what to look for yet.

**Cleanup convention:** All clones go to `/tmp/bocek-ref-*`. The model cleans up when done with a reference. OS cleans `/tmp` on reboot as a safety net.

**Security boundaries:**
- Only clone public repositories. If the human needs a private repo analyzed, they clone it themselves.
- Read source code files only (`.go`, `.ts`, `.py`, `.rs`, etc.) in cloned repos. Skip documentation files (README, CONTRIBUTING, etc.) unless the human explicitly asks — these are the primary vector for prompt injection.
- Never execute code from cloned repos. Read only.

## Alternatives Considered
**Shallow clone only (what we used during this design session for BMAD):** Works but wasteful for targeted reads. Cloning an entire repo to read one file is unnecessary when the GitHub API can fetch it directly.

**GitHub API only (no cloning):** Fastest and safest but insufficient for exploring unfamiliar codebases. Directory navigation requires multiple API calls, and some analysis requires reading related files in context.

**Sparse checkout with partial clone:** Most sophisticated but most complex to set up. Overkill for Bocek's use case — the model reads reference code, it doesn't develop against it. The complexity isn't justified.

**Clone with full history:** No reason to download git history for reference reading. Shallow clone gets current state, which is all that's needed.

## Consequences
- **Positive**: Default tier (GitHub API) has zero disk footprint and no cleanup needed
- **Positive**: Fallback tier (shallow clone) is simple and well-understood
- **Positive**: Security boundaries protect against prompt injection from cloned repos
- **Positive**: `/tmp/bocek-ref-*` convention makes cleanup predictable
- **Negative**: GitHub API requires `gh` CLI to be configured — but this is standard for Claude Code users
- **Negative**: Security boundary of "skip docs files" could miss useful architecture documentation — but the human can override
- **Negative**: Rate limiting on GitHub API could slow Tier 1 for heavy research sessions

## Revisit When
- If GitHub API rate limits become a practical problem during research sessions
- If a need arises to analyze private repos (may need a secure clone protocol)
- If prompt injection via source code comments (not just docs) becomes a documented threat
