# Software design vocabulary

Foundational architecture vocabulary for system-design decisions. Adopted from `mattpocock/skills`'s `improve-codebase-architecture/LANGUAGE.md` per `[[software-design-vocabulary]]`. Use these terms exactly when reasoning about the software being designed — don't substitute *"component," "service," "API,"* or *"boundary."* Consistent language is the whole point.

**Scope note:** this vocabulary describes the software/system being DESIGNED by a bocek-using project, not bocek's own methodology layer. For bocek-internal terms (vault, primitive, feature folder, reference, mental model), see this repo's own structure and the related vault entries listed at the bottom.

## Terms

**Module**
Anything with an interface and an implementation. Deliberately scale-agnostic — applies equally to a function, class, package, or tier-spanning slice.
_Avoid_: unit, component, service.

**Interface**
Everything a caller must know to use the module correctly. Includes the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics.
_Avoid_: API, signature (too narrow — those refer only to the type-level surface).

**Implementation**
What's inside a module — its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth**
Leverage at the interface — the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface. A module is **shallow** when the interface is nearly as complex as the implementation.

**Seam** *(from Michael Feathers, *Working Effectively with Legacy Code*)*
A place where you can alter behaviour without editing in that place. The *location* at which a module's interface lives. Choosing where to put the seam is its own design decision, distinct from what goes behind it.
_Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter**
A concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).

**Leverage**
What callers get from depth. More capability per unit of interface they have to learn. One implementation pays back across N call sites and M tests.

**Locality**
What maintainers get from depth. Change, bugs, knowledge, and verification concentrate at one place rather than spreading across callers. Fix once, fixed everywhere.

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, the module wasn't hiding anything (it was a pass-through). If complexity reappears across N callers, the module was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout, *A Philosophy of Software Design*): rewards padding the implementation. Use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a class's public methods**: too narrow — interface here includes every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## bocek-side cross-references

Vault entries that touch these terms (currently empty — populate as bocek decisions adopt the vocabulary):

*(no cross-references yet)*

## Provenance

Vocabulary adopted from `github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/LANGUAGE.md` (observed 2026-05-14). The **Depth as leverage** refinement is matt's contribution over Ousterhout's original "depth as line-count-ratio" framing.

Original sources cited by matt and worth reading first-hand:
- Ousterhout, *A Philosophy of Software Design* (2018) — Module, Interface, Implementation, Depth (line-ratio framing rejected here).
- Michael Feathers, *Working Effectively with Legacy Code* (2004) — Seam.
- Eric Evans, *Domain-Driven Design* (2003) — Bounded context (the "boundary" usage this vocabulary avoids).
