# 10 — System Design

## Concept

System design is deciding **where state lives and how it moves** under
constraints you wrote down honestly. The method matters more than any
architecture:

1. **Requirements as numbers.** "Fast" is not a requirement; "p95 < 300ms
   at 50 req/s" is. Guess if you must — a written guess can be corrected.
2. **Envelope math before boxes.** 100k users × 20 events/day ≈ 23 events/s
   average, maybe 10× peak. That number decides whether you need a queue
   at all — most designs die right here, in a good way.
3. **Draw the data flow**, one arrow per movement of state. Every arrow is
   a failure mode: what happens when it's slow, duplicated, or lost?
4. **Choose boring.** Postgres until proven otherwise. Novelty must earn
   its place in writing.
5. **Record it as an ADR** (`devflow adr new "..."`) — options, pros/cons,
   decision, revisit-trigger. The ADR *is* the design work; diagrams decay,
   decisions compound.

## Real-world example

"We need Kafka for our notification system."

Envelope: 5k users, ~2 notifications/day each → 0.1 events/second.
A Postgres table with a `status` column and a worker polling every second
handles 1000× that. The ADR records Kafka as Option B with the honest
trigger: "revisit above ~500 events/s sustained". Six months of ops pain
avoided by one multiplication.

## Exercises

1. Take a system you use daily (e.g. a URL shortener) and design it on one
   page: numbers, data flow, failure modes, boring choices.
2. Find a past project and write, retroactively, the ADR for its biggest
   architectural choice — including the options you didn't consider then.
3. For your current project: list every arrow in the data flow and answer
   "what happens if this arrow delivers twice?" (idempotency audit).
4. Estimate your production DB's size in one year from real growth numbers.
   Check your guess against `SELECT pg_database_size(...)` in a month.

## Common mistakes

- Designing for imagined scale: you are probably not Google, and the
  complexity tax is due *now* while the scale may never arrive.
- Skipping the numbers because they're "obvious" — they never are.
- Treating the diagram as the deliverable. The decisions (and their
  revisit-triggers) are the deliverable; that's why ADRs live in git.
- Confusing "I can't defend this choice" with "the choice is wrong" —
  write the ADR and find out which.

## Further reading

- Designing Data-Intensive Applications (Kleppmann) — chapters 1–3
- "Choose Boring Technology" (Dan McKinley) — the essay behind principle #1
