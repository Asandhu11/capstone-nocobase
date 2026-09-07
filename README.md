# Occupancy & Access "Clicker" System — NocoBase Prototype

This repository contains a working prototype of a venue occupancy-tracking ("clicker") system, built as a no-code CRUD application on top of [NocoBase](https://github.com/nocobase/nocobase). It's started with a single `compose.yml` using Docker Compose, and it runs two containers:

1. **postgres** – the Postgres database that stores all of the application's data
2. **app** – the NocoBase server and web UI

The prototype implements the data model from the team's ERD: venues and their entrances/devices click people in and out, those clicks roll up into occupancy snapshots, venue-specific capacity thresholds trigger alerts, and everything is tied together with users, roles/permissions, VPN session tracking, and an audit log.

## Prerequisites

You need **Docker Desktop** (which includes Docker Compose) installed and running on your computer.

- Download it from <https://www.docker.com/products/docker-desktop/>
- Install it, then open the Docker Desktop application and make sure it says it's running before continuing.
- To confirm it's installed correctly, open a terminal (Terminal on Mac/Linux, PowerShell or Command Prompt on Windows) and run:

  ```bash
  docker --version
  docker compose version
  ```

  Both commands should print a version number rather than an error.

## How to run it

1. Download/clone this repository so that `compose.yml`, `README.md`, and the `storage/` folder are all in the same folder on your computer.
2. Open a terminal and navigate into that folder, e.g.:

   ```bash
   cd path/to/this-folder
   ```

3. Start everything with:

   ```bash
   docker compose up
   ```

   - The first time you run this, Docker will download (pull) the Postgres and NocoBase images from Docker Hub, which can take a few minutes depending on your internet connection. You'll see a lot of log output — that's normal.
   - If you'd rather run it in the background (so you get your terminal prompt back), use `docker compose up -d` instead. You can then view logs at any time with `docker compose logs -f`.

4. Wait for the NocoBase container to finish its first-time setup. You'll know it's ready when the logs stop scrolling and you see messages indicating the app has started (something like `app running at: http://0.0.0.0:80`). This can take a minute or two the first time.

5. Open a web browser on your computer and go to:

   ```text
   http://localhost:13000
   ```

## Logging in

NocoBase automatically creates a default administrator account the first time it starts. Log in with:

| Field    | Value                  |
| -------- | ---------------------- |
| Email    | `admin@nocobase.com`   |
| Password | `admin123`             |

**You should change this password** after your first login (Settings → your profile icon → Change password) — it's only meant as a starting point.

The prototype also comes seeded with a few sample application users you can look at (not log in as, since their passwords weren't set) — see the **Users** page described below.

## Using the website

Once you're logged in, you'll land on the admin dashboard. Across the top of the page is a dark navigation bar with three tabs — these are the three functional areas of the system, matching the three groupings in the team's ERD:

- **Occupancy Core** — venues, their entrances/devices, and the click/occupancy data those devices generate
- **Identity & Access** — the people and permissions side of the system: users, roles, and VPN session history
- **Alerts & Ops** — capacity alerts and the audit trail of actions taken in the system

Clicking one of these tabs changes the list of pages shown in the left-hand sidebar. Clicking a page name in the sidebar opens a table of that data.

Every page in this prototype works the same way, so once you're comfortable with one, you're comfortable with all of them:

- **Add new** (blue button, top right of the table) opens a form to create a new record.
- **View** (next to each row) opens a read-only look at that record, including any linked records (e.g. which Venue a Device belongs to).
- **Edit** (next to each row) opens the same form as "Add new," pre-filled, so you can change that record.
- Columns that show a **blue link** (like a linked Venue, Device, or User) are relationships — clicking them, or looking at the View popup, shows you the related record instead of just an ID number.

### Occupancy Core pages

| Page | What it represents |
| --- | --- |
| **Venues** | The physical locations being monitored — name, address, timezone, maximum capacity, current headcount, and a status (Open / Near Capacity / etc.) |
| **Entrances** | The physical entrances/exits at each venue |
| **Devices** | The physical clicker hardware at each venue (tablets, kiosks, cameras) — includes device type, whether it's currently active, and when it was last seen reporting in |
| **ClickEvent** | Every individual "click" recorded by a device — a timestamp, which device recorded it, whether it was an "In" or "Out" event, and (optionally) which user triggered it |
| **OccupancySnapshot** | Point-in-time headcount totals for a venue, calculated from click events |
| **VenueConfig** | Per-venue configuration — the occupancy percentage at which a venue should show a "warning" state, and the percentage at which it should be considered "locked" (at capacity) |

### Identity & Access pages

| Page | What it represents |
| --- | --- |
| **Users** | Everyone with access to the system, with their nickname, username, email, phone, and assigned role(s) |
| **Roles** | The named roles in the system (Admin, Root, Member, Venue Staff, Security Officer), each with a set of permissions attached |
| **Permissions** | The individual permissions that can be granted (e.g. `manage_venues`, `view_alerts`, `resolve_alerts`) |
| **RolePermission** | The join table connecting Roles to Permissions — this is what actually grants a permission to a role |
| **VPNSession** | A log of VPN session activity per user — start/end time and client IP address |

### Alerts & Ops pages

| Page | What it represents |
| --- | --- |
| **Alert** | Alerts raised by the system (e.g. a venue nearing capacity, a device going offline), including when it was triggered, who resolved it, and when |
| **AuditLog** | A record of actions taken in the system (e.g. resolving an alert, creating a venue), who did it, and structured details about the change |
| **NotificationSubscription** | Which users want to be notified, and how, when certain events occur |

### The team's ERD

For the full entity-relationship diagram this prototype was built from, see `erd-final-preview.png` in this repository.

## Stopping the app

- If you ran `docker compose up` in the foreground, press `Ctrl+C` in that terminal.
- If you ran it with `-d` (detached/background mode), stop it with:

  ```bash
  docker compose down
  ```

Your data is **not** deleted when you stop or run `docker compose down` — it's saved on your computer in a `storage/` folder that gets created next to `compose.yml` (this is set up via Docker "volumes" / bind mounts in `compose.yml`). To completely wipe the data and start fresh, stop the containers and then delete the `storage/` folder.

## How it works (quick overview)

- `compose.yml` defines two **services**: `postgres` (the database) and `app` (NocoBase itself).
- The `app` service is told how to reach the database through environment variables (`DB_HOST=postgres`, `DB_USER=nocobase`, etc.) — `postgres` here is just the service name Docker Compose uses as a hostname on the shared internal network defined at the bottom of the file.
- The `ports` line `'13000:80'` maps port 80 inside the `app` container (where NocoBase listens) to port 13000 on your computer, which is why you visit `http://localhost:13000` in your browser.
- **Bind mounts**: the `volumes` lines in `compose.yml` (`./storage/db/postgres:/var/lib/postgresql/data` and `./storage:/app/nocobase/storage`) are Docker Compose *bind mounts* — they map folders inside the containers directly onto a real `storage/` folder on your host computer, next to `compose.yml`. Because of this, every collection, page, and record you see in the app — and everything described above — is actually stored as ordinary files/database files on your computer, not just inside the temporary container. If you stop the containers, delete them, or even reinstall Docker, your data survives as long as the `storage/` folder is intact, and starting the containers back up against that same folder brings the exact same website back.

## Troubleshooting

- **"port is already allocated" error**: something else on your computer is already using port 13000. Either stop that program, or change the left-hand side of the `ports` mapping in `compose.yml` (e.g. `'14000:80'`) and then visit `http://localhost:14000` instead.
- **Page won't load yet**: give it another minute — the very first startup runs a database migration and can take a bit longer than later restarts.
- **A specific admin page shows "Render Failed"**: this means that page's layout got into a bad state (usually from an interrupted edit). Go to the gear icon (top right) → **Routes**, find that page in the list, and delete it, then recreate it following the same pattern described above (Add block → Table → pick the collection → configure columns/actions). This only affects how that page displays — the underlying data is untouched.
- **Need to reset everything**: run `docker compose down`, delete the `storage/` folder, then `docker compose up` again to start from a clean install.
