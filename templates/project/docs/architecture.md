# Architecture — {{PROJECT_NAME}}

Keep this one screen if possible. Detail lives in ADRs; this is the map.

## Context

What sits around the system: users, external services, constraints.

## Components

```text
[client] -> [api] -> [db]
                 \-> [worker] -> [queue]
```

One line per box: what it is, what it owns.

## Data flow

The one or two flows that matter. Trace a request end to end.

## Key dependencies

What we lean on and what breaks if it's gone.

## Risks

What keeps you up at night about this design. Each entry should
eventually become an ADR or an experiment.
