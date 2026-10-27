# Sprint 4 validation

## Current fresh-install result - October 25, 2026

**8 passed, 0 failed, 0 errors, 0 skipped in 164.36 seconds.**
The full suite ran once without retries or omitted scenarios against fresh,
isolated bind mounts. Environment: Python 3.12.13, pytest 9.1.1, Selenium 4.51.0
and Chromium 155.0.8059.39 on Linux in Docker.

Source: `scripts/run-e2e.sh`, run `20261025-212503-49557`. The report and service
logs are included under `test-results/` in the submission ZIP. Participant
sessions run on a different installation and are not modified by these tests.

- T1: all three staff accounts reach their assigned screens.
- T2: required event/station selection, compatible stations, one saved entry,
  event/venue totals, recent record and persistence after reload.
- T3: one saved exit, zero-count warning, blocked further exit and persistence.
- T4: last available space, full-capacity warning and blocked further entry.
- T5: venue/status/name filters, exact row/summary totals, empty results and
  recovery.
- T6: closed Harbor Workshop totals (420 / 420 / 0), no counting controls and
  unchanged history after refresh.

These are real browser tests. API calls create fictional preconditions and
independently verify saved data. Assessed user actions use ordinary browser
controls. Eight tests represent six tasks because T1 covers three staff roles.

## Packaging and exact-archive verification

The packager accepts a stopped isolated installation, preserving the website
used by participants. It checks every running container for overlapping bind
mounts, checks PostgreSQL 16 data and shutdown state, requires a full passing
JUnit report, includes empty directories, refuses an existing ZIP and creates
a SHA256 checksum. Attempting to package the live participant installation on
October 25 was correctly rejected before any archive was created.

The final archive is verified with `scripts/verify-sprint4-zip.sh`. This extracts
the ZIP, points PostgreSQL at the extracted storage, starts a fresh Selenium
service and runs the complete suite. Verification output is separate from the
report shipped inside the archive. The accompanying submission check and
`verification.json` identify the exact ZIP hash and its extraction result;
consult these for the final archive outcome.

## Earlier evidence and limitations

The October 22 original installation passed all eight tests in 130.86 seconds.
Its draft archive initialized services but failed browser navigation/loading
on T5 and T6; T6 also lost its Selenium session. A targeted rerun passed T5 but
still timed out on T6. These failures occurred before history assertions.
The earlier draft is retained locally with its failure evidence. Its timeout
cause was not conclusively established. The October 25 fresh installation did
not reproduce those failures. Do not describe this as proof of a particular
product defect or participant observation.

Earlier diagnostic attempts also exposed maintenance-page health checks, a
bare internal hostname upgraded to HTTPS, and hidden Ant Design select inputs.
The submitted configuration waits for a plugin-list JSON response, uses the
`clicker.test` network alias, recognizes a busy healthy Selenium node and
interacts with visible selectors. Those corrections predate the current run.

## Assignment evidence

The expanded Sprint 4 rubric and instructor-linked issue guide/template were
reviewed directly on October 25; see [requirements.md](requirements.md).
Participant sessions, their analysis, the actual team transcript and selection
of 8-10 GitHub issues require real evidence supplied by Ayoola and the team.
Prepared worksheets and automated results do not establish those outcomes.
