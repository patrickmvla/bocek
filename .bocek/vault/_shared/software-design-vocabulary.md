---
type: decision
features: [_shared]
related: ["[[mattpocock-skills-survey]]"]
created: 2026-05-14
confidence: high
---

# Adopt matt's architectural vocabulary as `mental-models/software-design.md`

## Decision

Create a new mental-model file at `mental-models/software-design.md` that adopts matt's `improve-codebase-architecture/LANGUAGE.md` vocabulary wholesale. Eight terms: **Module**, **Interface**, **Implementation**, **Depth**, **Seam**, **Adapter**, **Leverage**, **Locality**. Plus matt's explicit rejection of Ousterhout's depth-as-line-ratio framing in favor of depth-as-leverage. Plus matt's *Principles* and *Relationships* sections.

Bocek-specific refinements:
- Cross-reference any bocek decision/discovery that uses one of these terms via `→ see [[wikilink]]`. Currently no bocek entry uses this vocabulary, so the wikilinks start empty.
- No preflight auto-suggestion for v1. Mental-models are domain-keyed (frontend, auth, data-layer, etc.); software-design is foundational, not domain-keyed. The model loads it on demand for system-design questions; the design primitive's *Reference triage* can point at it explicitly.

The file follows the existing `mental-models/*.md` format (header + sections, no frontmatter — matches existing examples in `~/.bocek/mental-models/`).

## Reasoning

`[[mattpocock-skills-survey]]` finding F9 surfaced this during the deep-read pass: matt's `LANGUAGE.md` is an *original* refinement of Ousterhout's *A Philosophy of Software Design* — it explicitly rejects "depth = ratio of implementation-lines to interface-lines" because that framing *"rewards padding the implementation,"* and substitutes "depth = leverage at the interface." The vocabulary set (Module / Interface / Implementation / Depth / Seam / Adapter / Leverage / Locality) is production-cited within matt's repo (shipped, in use across multiple of his skills) and corrects a known weakness in the source it derives from.

Bocek has six domain mental-models (`api-design`, `auth`, `data-layer`, `distributed-systems`, `frontend`, `state-management`) and zero foundational software-design model. The gap is observable: any bocek-using project that asks a structural-design question (e.g. *"should this be a service or a function?"*) has no mental-model to load. Matt's vocabulary fills that gap with one file.

Wholesale adoption over refinement is the lowest-cost / highest-fidelity path. The vocabulary's quality is matt's contribution; bocek doesn't need to re-derive it.

## Engineering substance applied

- **Operability:** one new file in an existing directory pattern. No primitive changes, no script changes. Discoverable via `ls ~/.bocek/mental-models/`.
- **Discoverability:** future preflight enhancement could auto-suggest the model when a structural-design question is detected. Not in v1 scope; flagged in *Revisit when*.

## Production-grade gates

- **Idiomatic** — adopts matt's pattern (production-cited at his 81k-star repo, shipped). Bocek's existing mental-models directory already uses this shape. Idiomatic for both stacks.
- **Industry-standard** — Ousterhout's *A Philosophy of Software Design* (canonical source); Michael Feathers' *Working Effectively with Legacy Code* (origin of "seam"); matt's refinement (production refinement of canonical sources). Three independent sources support the vocabulary.
- **First-class** — uses the existing mental-models directory; no new mechanism.

## Rejected alternatives

### (a) Refine matt's vocabulary for bocek's context

**What:** Adopt matt's vocabulary but rewrite definitions to be bocek-specific (e.g. reframe Module as "vault entry" or similar).

**Wins when:** bocek's context introduces terms-of-art that conflict with matt's. None do — matt's vocabulary is at the layer below bocek's methodology layer.

**Why not here:** unnecessary effort. Matt's definitions stand for any software-design context; bocek's methodology layer doesn't override them.

### (b) Skip — bocek doesn't need this mental-model

**What:** Leave the foundational software-design slot empty. Trust that users' system-design questions are out-of-scope for bocek's mental-models.

**Wins when:** bocek's value-add is purely methodological (vault discipline, primitive structure) and never touches structural-design questions.

**Why not here:** bocek-using projects routinely face structural-design questions. The gap is observable in bokchoy's vault — many decisions touch interface-vs-implementation, but no shared vocabulary anchors them.

## Failure mode

**Vocabulary drift between this mental-model and bocek's own vault decisions.** Bocek's existing entries use ad-hoc terms (e.g. "feature folder", "vault entry") that overlap with matt's vocabulary but aren't unified with it. The mental-model says "Module"; bocek's vault entries say "feature" or "primitive" or "reference." Future readers may confuse the two layers.

Quantitative signal: a bocek user asks a system-design question that mixes bocek's methodology vocabulary and matt's software-design vocabulary; the model conflates them.

## Mitigations

1. **The mental-model file explicitly notes its scope:** *"This vocabulary describes the software/system being DESIGNED, not bocek's own methodology layer. For bocek-internal vocabulary (vault, primitive, feature, reference), see this repo's own structure."* Inline scope disambiguation.
2. **Future amendment:** if bocek's own vault entries start adopting matt's vocabulary (e.g. calling a primitive a "Module"), promote the term up; cross-reference both layers.

## Idiom citations

None — vocabulary file, not stack-specific.

## Revisit when

- A bocek user reports that the lack of preflight auto-suggestion for software-design questions costs them context-load time. At that point, design a detector heuristic (e.g. preflight greps the user's prompt for terms like "interface", "module", "refactor", "depth") and auto-suggests the model.
- A second foundational mental-model is needed (e.g. concurrency-models or distributed-systems-models). At that point the mental-models directory may need sub-categorization by "domain vs foundational"; revisit the structure.
- Bocek's vault entries start adopting matt's vocabulary explicitly. Promote the cross-references in the mental-model file's existing wikilinks-section.

## Implementation items queued

- **H1':** Create `mental-models/software-design.md` modeled on matt's `LANGUAGE.md`. Verbatim definitions for the 8 terms + Principles + Relationships + Rejected framings sections. Plus a bocek-scope-note paragraph at the top.
