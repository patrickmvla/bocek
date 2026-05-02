---
vault_version: 2
---

# Bocek Vault Index

This vault records bocek-the-project's own design decisions going forward (Path A onboarding, 2026-05-02). The 23 historical decisions in `docs/decisions/000N-*.md` remain as archive — see ADR-0003 specifically, which is superseded at the path layer by `[[mandatory-feature-folders]]` but otherwise stands.

## _shared

- [[mandatory-feature-folders]] — type: decision — vault entries must live in `vault/{feature}/{slug}.md` or `vault/_shared/{slug}.md`; flat writes are forbidden and code-enforced. Supersedes ADR-0003 at the path layer only.
