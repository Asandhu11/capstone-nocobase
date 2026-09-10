# Clicker Occupancy Prototype

This project is a NocoBase prototype for monitoring building occupancy. It
keeps track of venues, entrances, clicker devices, entry and exit events,
occupancy snapshots, alerts, notification subscriptions, and audit records.

The project runs entirely through Docker Compose. You do not need to install
NocoBase, PostgreSQL, Node.js, or any programming tools.

## What is included

- `compose.yml` starts the NocoBase web application and its PostgreSQL database.
- `storage/` contains the configured website, database, page layouts, and sample
  data.
- `scripts/setup-prototype.sh` can rebuild the prototype collections and sample
  data after a fresh database is created.
- The `admin-email` startup service updates the included administrator account
  to `admin@nocobase.com` while preserving its password and existing data.
- Database startup restores the empty PostgreSQL folders omitted by Git, so
  a fresh clone can start the included database without manual folder creation.
- `erd-final-preview.png` shows the team data model used for this prototype.
- `network-final-preview.png` shows the team's proposed network design.

Keep `compose.yml` and the `storage/` folder together. Moving one without the
other will make Docker start a blank site instead of this prototype.

## Before you begin

You need Docker Desktop on Windows or macOS. Linux users can use Docker Engine
with the Docker Compose plugin.

1. Download Docker Desktop from <https://www.docker.com/products/docker-desktop/>.
2. Install it.
3. Open Docker Desktop and wait until it says the Docker engine is running.
4. Open a terminal. On Windows, use PowerShell. On macOS, use Terminal.
5. Check the installation by entering these two commands:

   ```bash
   docker --version
   docker compose version
   ```

Both commands should print a version number. If either command reports that it
cannot connect to Docker, open Docker Desktop and wait for it to finish
starting.

## Start the website

1. Extract the submitted ZIP file into a normal folder. Do not run it from
   inside the ZIP preview.
2. Open a terminal in the extracted folder. You should be in the folder that
   contains `compose.yml`, `README.md`, and `storage/`.
3. If the terminal opened somewhere else, change directories. Replace the
   example path below with the actual path to the extracted folder:

   ```bash
   cd /path/to/capstone-deliverable1-nocobase
   ```

4. Start the services:

   ```bash
   docker compose up -d
   ```

   The first run can take several minutes while Docker downloads the NocoBase
   and PostgreSQL images.

5. Check their status:

   ```bash
   docker compose ps
   ```

   `nocobase-postgres` should say `healthy`, and `nocobase-app` should say
   `Up`.
   The `admin-email` setup service exits with code `0` after completing its
   check; this is expected.

6. Open this address in a web browser:

   <http://localhost:13001>

7. NocoBase may show a loading screen for 30 to 60 seconds after the containers
   first start. Wait for the sign-in page before continuing.

## Sign in

Use the included administrator account:

| Field | Value |
| --- | --- |
| Email | `admin@nocobase.com` |
| Password | `admin123` |

This is a course-project password. Change it before using the system for real
people or real operational data.

## Use the prototype

After signing in, the top navigation contains three pages.

### Occupancy Dashboard

This is the starting page for venue staff.

- The first table shows each venue's current occupancy, maximum capacity,
  operating status, and address.
- The second table shows open, acknowledged, and resolved alerts with the
  affected venue.
- Select **Add new** above the venue table to create another venue. Enter a
  venue name and maximum capacity, complete any other useful fields, and select
  **Submit**.

The sample data includes Harbor Center at 412 of 500 occupants and Eastside
Fieldhouse at 267 of 800 occupants.

### Device Monitor

Select **Device Monitor** to check the clicker equipment assigned to each
entrance. The table shows the device name, type, client ID, last check-in time,
credential status, active status, entrance, and physical location.

The sample data intentionally includes one device with expiring credentials
and one inactive device with revoked credentials. These records make it easy to
test how the system highlights operational problems.

### Event Log

Select **Event Log** to review raw clicker activity. Each row shows whether the
event was an entry, exit, or correction; the occupancy change; when it occurred
and arrived; its idempotency token; processing status; device; and entrance.

Positive changes add occupants, negative changes remove occupants, and a
correction records a manual reconciliation. The unique idempotency token keeps
the same click from being processed twice.

## Change a page or table

NocoBase is a no-code system, so an administrator can change the interface in
the browser.

1. Select the paintbrush-shaped **UI Editor** button in the upper-right corner.
2. Use **Fields** on a table to show or hide columns.
3. Use **Actions** to add controls such as **Add new**, refresh, import, or
   export.
4. Use **Add block** to place another table, form, list, calendar, or chart on a
   page.
5. Select the **UI Editor** button again to return to normal viewing mode.

These changes are saved automatically in the PostgreSQL database inside the
bind-mounted `storage/` folder.

## Data model

The prototype implements the main collections from the team ERD:

| Collection | Purpose |
| --- | --- |
| Venues | Capacity, current occupancy, address, time zone, and status |
| Entrances | Entry/exit direction and location within a venue |
| Devices | Clicker hardware, credentials, activity, and last check-in |
| Click events | Entry, exit, and correction events from devices |
| Occupancy snapshots | Saved counts for reporting and reconciliation |
| Alerts | Capacity, offline-device, and count-mismatch warnings |
| Notification subscriptions | Alert destinations for users and venues |
| Audit log | Administrative and operational change history |

The collections are connected with NocoBase relationship fields. For example,
a venue has many entrances, an entrance has many devices, and a device has many
click events. Alerts and snapshots belong to venues, while selected records
also connect to NocoBase users.

## How the bind mounts work

A Docker container normally has its own temporary filesystem. A bind mount
maps a real folder on the host computer into a container. Files written at the
container path are therefore written into the project folder on the host.

This project uses two bind mounts:

| Host folder | Container path | Stored information |
| --- | --- | --- |
| `./storage` | `/app/nocobase/storage` | NocoBase settings, uploads, logs, keys, and application files |
| `./storage/db/postgres` | `/var/lib/postgresql/data` | PostgreSQL tables containing the collections, records, relationships, and UI layouts |

Because both mounts use paths beginning with `./`, Docker resolves them from
the folder containing `compose.yml`. Running `docker compose down` removes the
containers but does not delete these host folders, so the website returns with
the same data the next time it starts.

## Stop and restart the website

Stop the containers without deleting the site:

```bash
docker compose down
```

Start them again later:

```bash
docker compose up -d
```

Restart the running services:

```bash
docker compose restart
```

## Back up the website

1. Stop the containers with `docker compose down` so PostgreSQL finishes all
   writes cleanly.
2. Copy `compose.yml`, `README.md`, and the complete `storage/` folder.
3. Compress those copied items into a ZIP file.

Do not make a database backup while PostgreSQL is still running. The copied
files could be inconsistent.

## Rebuild after an intentional reset

Deleting `storage/` permanently removes the configured pages and all records.
Make a backup before resetting it.

If this repository is cloned without the submitted `storage/` directory, start
the empty site, wait for it to finish installing, and then run:

```bash
./scripts/setup-prototype.sh
```

The script requires `curl` and `jq`. It recreates the eight prototype
collections, their relationships, and sample records. Page layouts still come
from the submitted `storage/` directory.

## Troubleshooting

### The browser cannot open the site

Run:

```bash
docker compose ps
docker compose logs --tail=100 app postgres
```

If Docker says it cannot connect to the daemon, start Docker Desktop. If the
containers are still starting, wait another minute and refresh the browser.

### Port 13001 is already in use

Another program is using the website port. In `compose.yml`, change:

```yaml
- '127.0.0.1:13001:80'
```

to a free port, for example:

```yaml
- '127.0.0.1:13002:80'
```

Then run `docker compose up -d` again and open
<http://localhost:13002>.

### The site looks empty

Confirm that `storage/db/postgres/` exists next to `compose.yml`. An empty or
missing `storage/` folder makes NocoBase install a new blank database.

### The login does not work

Use `admin@nocobase.com` and `admin123`. If you have an older checkout, pull the
latest changes and run `docker compose up -d` from the repository root. The
`admin-email` service renames the original `admin@nocobase.local` administrator
before the application starts, preserving its password, permissions, and data.

The `INIT_ROOT_*` values only create the administrator during the first install.
Neither these settings nor the email migration reset a password that you have
already changed. To check the migration, run `docker compose logs admin-email`.
