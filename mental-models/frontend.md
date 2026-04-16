# Frontend

You are reasoning about what runs in the browser and how it gets there.

## The tensions that define this domain
- **Server rendering vs client interactivity** — server-rendered HTML is fast to first paint but requires a round trip for every interaction. Client-rendered UI is interactive but ships JavaScript that must be downloaded, parsed, and executed before anything appears.
- **Bundle size vs developer convenience** — every import adds bytes users must download. Convenient libraries that do everything ship code for features you don't use. Tree-shaking helps but doesn't eliminate the cost of large dependency trees.
- **Hydration correctness vs performance** — server-rendered HTML must match client-rendered output exactly or hydration fails visibly. Ensuring this match constrains what you can do differently on server vs client.
- **Interaction latency vs data freshness** — optimistic updates feel instant but show potentially wrong state. Waiting for server confirmation is correct but feels slow. The user's perception of speed matters more than actual speed.

## What gets missed
- Serialization cost at the server/client boundary is invisible until it isn't. A server component that passes a large object to a client component serializes that object into the HTML payload. This is a wire cost, not a render cost.
- Layout shift is a user trust signal, not just a performance metric. Content that moves after appearing makes users click the wrong thing. Skeleton screens that don't match final layout are worse than no skeleton.
- Accessibility is an architecture decision, not a styling pass. Modal focus traps, keyboard navigation, screen reader announcements — these require structural decisions at component design time, not after visual design is done.
- Third-party scripts are a performance and security liability. Every external script is a dependency you don't control, can't tree-shake, and might block rendering or leak data.

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
