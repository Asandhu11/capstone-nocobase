# Clicker Occupancy Prototype

A NocoBase course prototype for venues, entrances, devices, click events,
occupancy snapshots, alerts, notification subscriptions, and audit records.
It has three pages and eight collections. It does not yet provide a separate
page for every collection in the team's 14-collection ERD.

## Start from a fresh clone

Install and start Docker Desktop (or Docker Engine with Compose v2 on Linux).
No local PostgreSQL, Node.js, curl, or jq installation is required.

From the repository root, run:

```bash
docker compose up -d --wait --wait-timeout 600
```

The first run can take several minutes to download the images. Compose waits
until the database export has finished restoring, the migrations have run,
and the application API is ready.

Open <http://localhost:13001> and sign in:

| Field | Value |
| --- | --- |
| Email | `admin@nocobase.com` |
| Password | `admin123` |

These are shared course-demo credentials. Existing installations keep any
password their administrator has already changed.

`./scripts/setup-prototype.sh` runs the same startup command if you prefer a
helper script. No additional manual seeding or folder creation is required.
The alternate `capstone/compose.yml` starts the same seed on port 13000 and
keeps its own runtime data under `capstone/storage/`; use one location consistently.

## What you can do

| Page | Tables and actions |
| --- | --- |
| Occupancy Dashboard | Venues: Add new, View, Edit. Alerts: View, Edit. |
| Device Monitor | Devices: View, Edit. |
| Event Log | Click events: View, Edit. |

Select **View** beside a record for its details, or **Edit** to change its
fields and select **Submit**. For example, staff can acknowledge or resolve an
alert, update a device's credential status, or change a venue's capacity.
The existing venue **Add new** form remains available.

The sample data includes Harbor Center at 412 of 500 occupants and Eastside
Fieldhouse at 267 of 800. Device credentials demonstrate valid, expiring, and
revoked states. Click events include a unique idempotency token and a processed
flag; automated hardware ingestion and occupancy reconciliation are future work.

## Collections

| Collection | Purpose |
| --- | --- |
| Venues | Capacity, occupancy, address, time zone, status |
| Entrances | Direction and location within a venue |
| Devices | Hardware, credentials, activity, last check-in |
| Click events | Entry, exit, and correction events |
| Occupancy snapshots | Saved counts for reporting |
| Alerts | Capacity, offline-device, and count-mismatch warnings |
| Notification subscriptions | Alert destinations for users and venues |
| Audit log | Administrative and operational records |

The collections retain their relationships: venues have entrances, entrances
have devices, and devices have click events. Alerts and snapshots belong to
venues, and selected records connect to NocoBase users.

`erd-final-preview.png` and `network-final-preview.png` contain the team's
reference diagrams. The UI Editor in NocoBase lets administrators extend the
configured pages; those changes are stored in the database.

## Reproducible setup and persistence

- `seed/prototype.sql` is a portable PostgreSQL export containing the demo
  records, administrator, collections, relationships, and configured UI.
- `seed/assets/` contains the logo referenced by the export.
- PostgreSQL restores the export only when its data directory is empty.
- `prototype-migrations` updates the original admin email and adds the View/Edit
  forms to existing copies of this prototype. It exits with code 0 on success.
  Repeating startup does not duplicate the actions or replace your records.
- The NocoBase image is pinned to the version tested with the exported UI.

Runtime files are excluded from Git. Docker creates the bind-mounted folders:

| Host folder | Container path | Contents |
| --- | --- | --- |
| `./storage` | `/app/nocobase/storage` | Uploads, logs, application runtime files |
| `./storage/db/postgres` | `/var/lib/postgresql/data` | Records, collections, user accounts, page layouts |

Stopping or recreating containers keeps these folders and your changes:

```bash
docker compose down
docker compose up -d --wait --wait-timeout 600
```

Do not delete `storage/` to restart the app. A deliberately empty storage
folder restores the original demo instead of your latest edits.

## Update an older checkout

Back up your existing site first, then pull this branch and run the startup
command again. The migrations preserve existing records and passwords, rename
the original `admin@nocobase.local` account to `admin@nocobase.com`, and add the
new table actions. The PostgreSQL wrapper repairs the empty folders omitted by
older commits that tracked raw database files.

For a backup that does not require stopping PostgreSQL:

```bash
docker compose exec -T postgres pg_dump -U nocobase -d nocobase --no-owner --no-acl > backup.sql
```

Also save your uploaded files and Compose configuration. Keep personal backups
outside Git. For a complete copy of the raw `storage/` folder, stop the services
first so the database files are consistent. When updating an old Git checkout,
keep the backup outside the repository because the update removes formerly
tracked runtime files.

## Troubleshooting

Inspect service status and recent logs:

```bash
docker compose ps -a
docker compose logs --tail=100 postgres prototype-migrations app
```

If port 13001 is busy, set `NOCOBASE_PORT` in a local `.env` file, for example:

```dotenv
NOCOBASE_PORT=13002
```

Start Compose again and open that port. Fixed container names are not used,
so separate checkouts can run with distinct Compose project names and ports.

If the site is blank, check that you started from the repository root and that
PostgreSQL restored `/docker-entrypoint-initdb.d/01-prototype.sql` successfully.
An existing unrelated or previously blank database is intentionally preserved;
the initial export is not reapplied over it. Back up that installation and use
a separate fresh checkout to load the supplied demo.

If login fails, use the email above, check the migration logs, and use your own
password if you changed it earlier. `INIT_ROOT_*` settings do not reset existing
passwords.
