# Sprint 2 fix validation

Validated on 2026-09-10 using the NocoBase image pinned in `compose.yml` and
PostgreSQL 16, with isolated Compose projects. The supplied seed contains only
the original demo records; test edits were made in a separate restored copy.

## Fresh installation

- Started Compose with no `storage/` directory and waited for healthy services.
- PostgreSQL imported `seed/prototype.sql`; startup migrations exited with code 0.
- Signed in through both the browser and API using
  `admin@nocobase.com` / `admin123`.
- Opened Occupancy Dashboard, Device Monitor, and Event Log.
- Confirmed the initial collection counts: venues 2, entrances 4, devices 4,
  click events 5, occupancy snapshots 4, alerts 3, subscriptions 2, audit logs 3.

## Browser actions

- Created a test venue with **Add new**, opened its **View** details, and used
  the row **Edit** action to change its capacity from 120 to 150.
- Viewed a near-capacity alert and edited its status from Open to Acknowledged.
- Viewed East Lobby Tablet and edited its credentials from Expiring to Valid.
- Viewed event `evt-esf-2002` and edited its Processed flag to unchecked.
- Verified the saved values through the API/database. Other fields, including
  timestamps of the original events, JSON metadata, and relationship IDs,
  retained their values (apart from normal update-audit fields).

## Existing-install migration

- Started a copy of the original database with its old `.local` admin email
  and 95 flow models using the compatibility PostgreSQL wrapper.
- Ran the migrations twice: the email became `admin@nocobase.com`, the UI
  contained 275 models, and the second run added no duplicate actions.
- Compared all eight domain collections before and after: their records were
  exactly unchanged.

## Container recreation

- Ran `docker compose down` followed by `docker compose up -d --wait` on the
  edited test installation, keeping its bind-mounted storage.
- Confirmed the added venue and all edits survived, the UI actions were not
  duplicated, and login still worked.

## Repository checks

- Both Compose entry points pass `docker compose config --quiet`.
- Both shell scripts pass their shell's syntax check.
- No runtime `storage/` files are tracked. The seed excludes login tokens,
  one-time passwords, token blacklists, and OIDC state.
- `git diff --check` passes.
