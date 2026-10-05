# Sprint 3 validation

Tested October 1, 2026 with the team's pinned NocoBase 2.1.43 image and
PostgreSQL 16. Tests used an isolated Compose project and fictional data.

## Wireframes

Generated a three-page PDF before creating the GUIs. Rendered and visually
inspected all three final pages for legibility, clipping and alignment.
The entry and exit station labels match the supplied demonstration records.

## API and database checks

- All four demo accounts sign in successfully.
- Each staff role can access its own navigation page and expected collections.
- Native page model trees load with the JS block and its complete source.
- Manager events include their related venue records.
- Entry increases the event and venue counts; exit decreases them.
- A duplicate request does not change attendance twice.
- Closed events, wrong-direction stations, inactive stations and stations in a
  different venue reject counts.
- Exits at zero fail and leave attendance unchanged.
- Six concurrent entries and six concurrent exits lose no increments.
- When only one space remains, exactly one of six simultaneous entries succeeds.
- Manager writes, cross-role counting, direct staff edits to totals, and
  anonymous counting requests are rejected.

The test runner is `scripts/test-sprint3.py`. It writes test records, so use an
isolated installation. Test records were removed from the packaged demo, and
the supplied opening balances were restored.

## Screen component checks

`tests/ui.integration.cjs` runs the actual submitted screen source with React
hooks and the live NocoBase API. Ant Design controls are represented by test
hosts; this is not a browser rendering test.

- Counting is disabled until an event and station are selected.
- Harbor entry options include North Gate rather than the South Exit.
- Entry and exit buttons save counts and update their screen state.
- A simulated response loss after a committed entry is reconciled from its
  request ID without a duplicate increment.
- Manager venue, text and status filters work, including an empty result.
- Components unmount and clear their refresh timers.

To run these optional developer checks: `npm ci --prefix tests`, then
`node tests/ui.integration.cjs`. These dependencies are not needed to run the
website. A visual browser pass was not performed in this environment.

## Startup and persistence

The read-only `scripts/check-sprint3.py` verifies demo logins, stored page
source, event balances and venue relationships after startup. The package is
checked both from empty storage and from its extracted bind-mounted database.
The raw database archive is created only while PostgreSQL is cleanly stopped.

## Implementation references

- [NocoBase JS blocks](https://docs.nocobase.com/interface-builder/blocks/other-blocks/js-block)
- [NocoBase built-in React and Ant Design libraries](https://docs.nocobase.com/runjs/context/libs)
- [PostgreSQL explicit locking](https://www.postgresql.org/docs/16/explicit-locking.html)

## Remaining prototype limitations

The records are demonstration data, not measured attendance. Entry totals count
visits rather than unique individuals. An unresolved retry stays in memory only
while its page is open. Administrators remain trusted and can change data model
configuration. Hardware ingestion, unique-person tracking, production hosting
and the team's Deliverables 2 and 3 are outside this submission.
