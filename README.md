# Clicker Sprint 4

**Developer:** Ayoola Morakinyo
**Branch:** `sprint4-Ayoola`
**Base:** team `main`, `e0f3c52` (merged Sprint 3)

Sprint 4 adds Selenium end-to-end testing and a six-task usability plan for the
existing Clicker entry, exit and manager screens. Individual user sessions and
the team discussion are being completed separately by Ayoola.

Current validation: a fresh isolated installation passed all eight tests on
October 25. The final ZIP must also pass a complete run after extraction; its
SHA256 checksum and verification report are supplied alongside the archive.
See [validation](docs/sprint4/validation.md) for the evidence and earlier failures.

## Start the website

Install and start Docker Desktop, or Docker Engine with Compose v2. Extract the
submission and open a terminal in the directory containing this README and
`compose.yml`, then run:

```sh
docker compose up -d --wait --wait-timeout 600
```

Open **http://localhost:13004**. Use the repository root, not the old `capstone/`
subdirectory. First startup restores the seed, applies migrations, and starts
NocoBase; allow several minutes. If port 13004 is occupied, put
`NOCOBASE_PORT=13005` in a `.env` file beside Compose and use that port instead.

All demo passwords are **`admin123`**:

| Role | Email | Screen |
| --- | --- | --- |
| Entry attendant | `entry@clicker.test` | Entryway attendant |
| Exit attendant | `exit@clicker.test` | Exit attendant |
| Attendance manager | `manager@clicker.test` | Manager attendance |
| Administrator | `admin@nocobase.com` | All pages and configuration |

Use a new private browser window when changing roles during a participant
session. This branch tests the merged team implementation; the separate local
Sprint 3 session-lifecycle fixes were not silently brought into this branch.

Entry/exit attendants select an active event and a compatible station, then
record one person. The manager filters attendance by venue, status and event
name. The fictional Harbor Community Night starts at 412/500, Eastside Open
Gym at 267/800, and the closed Harbor Workshop at 420 entries, 420 exits and
zero inside. Entries can include repeat visits by the same person.

## Run the Selenium tests

The Compose **e2e** profile adds a real Chromium browser in the `selenium`
service and a Python/pytest runner in `e2e`. No host Python, browser driver or
Node.js installation is required for these tests. Initial setup downloads a
large browser image; allow time and disk space for it.

**Recommended: a fresh isolated test installation for each run.** On macOS,
Linux, WSL or Git Bash:

```sh
sh scripts/run-e2e.sh
```

This creates separate bind mounts under `.test-runs/<run-id>/`, uses port
13144, waits for app and browser health, runs all tests, saves results and
container logs, and takes down only its own containers. Existing demo data is
not changed. Set `E2E_PORT=13145` if the default test port is occupied.
The command exits nonzero for failed tests or startup failure.

**Portable direct commands** (also work in PowerShell) against this folder's
local demo:

```sh
docker compose --profile e2e up -d --wait --wait-timeout 600 app selenium
docker compose --profile e2e run --rm --build e2e
```

Direct runs create new synthetic venues, events and stations in this demo and
record attendance in those new scenarios. They do not reset the existing
Harbor or Eastside counts. Prefer the isolated command for repeated runs.

Run one task while diagnosing a failure:

```sh
docker compose --profile e2e run --rm e2e pytest -v -k t4 -p no:cacheprovider --junitxml=/artifacts/results.xml
```

Results appear in `test-results/` for direct runs, or the printed
`.test-runs/<run-id>/results/` directory for isolated runs:

- `results.xml`: JUnit report with pass/fail details.
- Failure `.png`, `.html` and `.json`: screenshot, rendered page and test error.
- `compose.log`: service logs retained by the isolated runner.

The suite performs **eight checks for six tasks**: T1 is parameterized for the
three staff accounts. It uses normal browser clicks/typing and explicit waits.
Fixture API calls create fictional preconditions and independently verify
saved counts; they do not perform the UI actions being assessed.

| Task | Coverage |
| --- | --- |
| T1 | Sign in to the assigned role's screen, for all 3 accounts |
| T2 | Select event/station, record one entry, verify counts and persistence |
| T3 | Record one exit, stop at zero, retain the result after reload |
| T4 | Fill the final space, explain full capacity, block further entry |
| T5 | Filter manager attendance, verify totals, recover from no results |
| T6 | Review a closed event's historical totals without changing them |

See [the usability plan](docs/sprint4/usability-plan.md) for participant prompts
and measurable success criteria. See [validation](docs/sprint4/validation.md)
for what has actually been executed; the presence of test code is not evidence
that it passed.

## Conduct the three individual user tests

Recruit at least three people outside the class. Follow
[the usability plan](docs/sprint4/usability-plan.md) and record every issue in
its **Observations** section. Before each participant, create fresh scenarios:

```sh
docker compose --profile e2e run --rm --build e2e python prepare_usability.py --participant P1
```

Use `--participant P2` and `--participant P3` for the other sessions. The
command creates independent scenarios, prints the event, venue and station
names, and writes both JSON setup data and a ready-to-use text observation
sheet to `test-results/`. Substitute these names in the task prompts. Keep observation notes anonymous and document actual behavior,
assistance and quotations. No participant observations are prefilled.

Use [the discussion preparation](docs/sprint4/team-discussion.md) after all
team members finish Deliverables 1 and 2. Start and verify Teams transcription,
compare findings, select 8–10 pressing items, and create their GitHub issues.
[Earlier feedback](docs/sprint4/feedback-and-next-steps.md) explains why startup
portability and meaningful recorded discussion are priorities.

## Data and packaging

| Host path | Container destination | Purpose |
| --- | --- | --- |
| `storage/` | `/app/nocobase/storage` | NocoBase runtime data and uploads |
| `storage/db/postgres/` | `/var/lib/postgresql/data` | Database records, users, roles and page models |
| `scripts/` and `seed/` files | Read-only startup file mounts | Migrations, seed database, logo |
| `tests/e2e/` | `/tests` | Selenium test source and fixture setup |
| `test-results/` | `/artifacts` | Test reports and failure evidence |

The browser itself needs no persistent bind-mounted data. Runtime directories
are ignored by Git but **must be included in the requested submission ZIP**.
The package script includes empty directories, which a partial database copy
can lose. Never delete `storage/` just to restart the application.

After testing, stop the services cleanly and package using host Python 3:

```sh
docker compose --profile e2e down
python3 scripts/package-sprint4.py
```

Output: `dist/Sprint4_Ayoola_Deliverable1.zip`. The packager refuses a running
bind mount in any running container, an incomplete database, or a missing
Selenium report. It includes Compose, README, bind mounts, startup files, test
source and supporting documentation, and writes a SHA256 checksum. It will not overwrite an
existing ZIP. Keep `.env` files, personal contact details and unrelated files
out of the submission.

To package a stopped isolated test run while keeping the participant website
running, use its printed paths:

```sh
python3 scripts/package-sprint4.py --storage .test-runs/<run-id>/storage --results .test-runs/<run-id>/results
```

Only the selected test storage must be stopped. Participant observations remain
in the separate participant installation and are not copied into this archive.

**Verify the exact ZIP before uploading:**

```sh
sh scripts/verify-sprint4-zip.sh dist/Sprint4_Ayoola_Deliverable1.zip
```

This extracts to a new directory, uses only the packaged bind mounts, creates
a fresh Selenium service, and writes a new report under
`.test-runs/zip-<run-id>/verification-results/`. It does not reuse the report
included in the ZIP or alter participant data. The printed `verification.json`
records the exact archive hash and outcome. Set `E2E_PORT=13146` if necessary.

Alternatively, extract it to a new directory,
create a `.env` there containing `NOCOBASE_PORT=13145`, and run:

```sh
docker compose -p clicker-s4-zip-check --profile e2e up -d --wait --wait-timeout 600 app selenium
docker compose -p clicker-s4-zip-check --profile e2e run --rm --build e2e
docker compose -p clicker-s4-zip-check --profile e2e down
```

Confirm startup, role sign-ins and all tests. The separate directory ensures
this checks the packaged bind mounts rather than reusing your working data.
The original ZIP remains unchanged by extraction testing. Upload the completed
usability plan separately for Deliverable 2 after actual sessions. The final
archive checksum and extraction verification are recorded alongside the ZIP.
The [verified requirements](docs/sprint4/requirements.md) cover the rubric and
remaining human evidence; [issue-template.md](docs/sprint4/issue-template.md)
follows the instructor-linked guidance.

## Troubleshooting and references

```sh
docker compose ps -a
docker compose logs --tail=80 postgres prototype-migrations app
docker compose --profile e2e logs --tail=80 selenium
```

If PostgreSQL reports “directory exists but is not empty,” preserve that folder
and inspect whether the extracted database is complete, including `PG_VERSION`
and its empty subdirectories. Validate a new extraction of the package; do not
remove a database containing observations. For a Git clone, a genuinely empty
storage directory initializes from `seed/prototype.sql`.

The implementation inherited from Sprint 3 is in `ui/` and
`scripts/migrate-sprint3.sql`; prior checks are in
[the Sprint 3 validation notes](docs/sprint3-validation.md).

- [Official Docker Selenium setup](https://github.com/SeleniumHQ/docker-selenium)
- [Selenium explicit waits](https://www.selenium.dev/documentation/webdriver/waits/)
