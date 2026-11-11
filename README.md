# Clicker Sprint 5: Caddy proxy

**Developer:** Ayoola Morakinyo

**Branch:** `sprint5-Ayoola`

**Base:** team `main` at `e0f3c52`

## What Sprint 5 adds

Caddy (https://caddyserver.com, open source, Apache 2.0) is now the only way into Clicker.
NocoBase no longer publishes a port. Public routes are open from anywhere. Admin routes,
meaning anything that changes how NocoBase is configured, only answer requests that come
from the intranet, including staff working from home over the WireGuard VPN.

| Network | Subnet | Who is on it |
| --- | --- | --- |
| `public` (internet and DMZ) | 10.0.1.0/24 | proxy 10.0.1.10, VPN server 10.0.1.20, home computer 10.0.1.30 |
| `intranet` (no route out) | 10.0.2.0/24 | proxy 10.0.2.10, VPN server 10.0.2.20, office computer 10.0.2.40, NocoBase, PostgreSQL |

This computer plays the public internet: **http://localhost:13005** reaches the proxy's
public side.

### Public and admin routes

The rule lives in `proxy/Caddyfile`.

| Admin only (intranet or VPN) | Public |
| --- | --- |
| Settings screens: `/admin/settings/*`, `/admin/pm/*`, `/admin/plugins/*` | Sign-in, the attendant and manager screens, and every other page |
| API actions that change plugins, collections, fields, page layouts and page models, routes, roles and permissions, users, workflows, authenticators, backups, API keys, environment variables or system settings, plus `app:restart` | All reads that pages need (`pm:listEnabled`, `roles:check`, `uiSchemas:getJsonSchema` and others), sign-in, and the Clicker data actions (entries, exits, events, venues) |

Blocked requests get **403** with the header `X-Clicker-Proxy: blocked`. The rule ignores
upper case, doubled slashes and an encoded colon (`%3A`). Caddy decides "intranet" by the
address actually connected to it (`remote_ip`), so a forged `X-Forwarded-For` header does
not help an outside request.

### Working from home

The `vpn` service is a WireGuard server (linuxserver/wireguard). On first start it creates
a profile for one peer, `home`, in `storage/vpn/server/peer_home/`. The profile only routes
the intranet (10.0.2.0/24) through the tunnel. Everything else stays on the home network.

The `home` service is a work-from-home computer on the internet with that profile
installed. Its browser sends admin requests to the proxy's intranet address,
**http://10.0.2.10**. They travel through the tunnel and arrive from the VPN server
(10.0.2.20), so Caddy allows them. The same admin page on the public address,
http://10.0.1.10, is blocked.

To use a real laptop instead: publish the VPN port by adding
`ports: ["51820:51820/udp"]` to `vpn`, set `SERVERURL` to the office's public address,
import `storage/vpn/server/peer_home/peer_home.conf` into the WireGuard app, and browse to
http://10.0.2.10/admin/settings.

## Run and verify

1. Start Docker Desktop.
2. In this folder run `docker compose up -d --wait --wait-timeout 600`.
3. Run `./scripts/verify-proxy.sh`. It checks the site from three places: this computer
   (outside), the office computer (intranet), and the home computer (over the VPN). It also
   turns the VPN off and on again to show that the tunnel is what grants access. All checks
   are read-only. Expected last line: `32 passed, 0 failed`.
4. Optional, by hand:
   - Open http://localhost:13005, sign in as `entry@clicker.test` / `admin123`, and record
     an entry. The public screens work.
   - Open http://localhost:13005/admin/settings. The proxy answers 403.
   - Start the home browser: `docker compose --profile browser up -d home-browser`, open
     http://localhost:7900 (password `secret`), start Chrome there, and open
     http://10.0.2.10/admin/settings. The settings page loads, through the VPN.
5. Optional: `cd tests && npm ci && CLICKER_TEST_URL=http://localhost:13005 npm test`
   runs the attendant and manager screen tests through the proxy from outside. They write
   prefixed test records, so use a disposable copy.

| Host path | Contents |
| --- | --- |
| `./proxy/Caddyfile` | The proxy rule |
| `./storage/proxy/` | Caddy data and config |
| `./storage/vpn/server/` | VPN server keys and the generated `home` profile |
| `./storage/vpn/home/` | The home computer's installed VPN profile |
| `./vpn/home-peer.sh` | Installs the generated profile on the home computer at startup |

---

# Sprint 3 notes (unchanged below)

Sprint 3 Deliverable 1 adds separate NocoBase screens for entryway attendants,
exit attendants, and attendance managers. The original Sprint 2 collections and
administrator pages remain available.

## Start the website

1. Start Docker Desktop (or Docker Engine with Compose v2 on Linux).
2. Extract the ZIP. Keep all its directories together.
3. Open a terminal in the folder containing this README and `compose.yml`.
4. Run `docker compose up -d --wait --wait-timeout 600`.
5. Open **http://localhost:13005** (through the Sprint 5 proxy). The first startup may take several minutes.

No local Node.js, Python, PostgreSQL or NocoBase installation is needed to run
the submission. Start from the repository root, not the legacy `capstone/`
subdirectory. If the port is occupied, put `CLICKER_PORT=13006` in a `.env`
file next to Compose, start again, and open http://localhost:13006.

## Demo accounts

All accounts use the course-demo password **`admin123`**.

| Account | Email | Access |
| --- | --- | --- |
| Entryway attendant | `entry@clicker.test` | Entry screen and recording entries |
| Exit attendant | `exit@clicker.test` | Exit screen and recording exits |
| Attendance manager | `manager@clicker.test` | Read-only manager screen |
| Administrator | `admin@nocobase.com` | All screens and original administration pages |

Sign out before changing accounts, or use separate browser profiles. An
administrator may need to select the **Root** role to see all pages. These are
shared demo accounts; the web port is bound to the local computer only.

## Wireframes and matching screens

Open **`docs/wireframes/Sprint3_Ayoola_Wireframes.pdf`**. Its three pages were
created before implementing the GUIs and specify each role's layout, controls,
and feedback.
The assignment allows a tool like Visio rather than requiring a Visio file.

The GUIs are native NocoBase **JS blocks**, stored in the page model data. Their
reviewable JavaScript source files are in `ui/`.

### Entryway attendant

Sign in as `entry@clicker.test`. Choose **Harbor Community Night - Harbor
Center**, select **North Gate**, and click **+ Record one entry** once per person.
The event attendance and venue occupancy increase together. A success message
confirms the count. The screen also shows capacity, spaces remaining and recent
entries. Entry is rejected when the venue is full or closed.

### Exit attendant

Sign in as `exit@clicker.test`. Select the same event and **South Exit**, then
click **- Record one exit**. Attendance decreases, and an exit is rejected at
zero. Each screen requires an active event and an active station in the correct
venue and direction. **East Lobby** supports both directions for Eastside Open
Gym. The inactive Service Gate is not offered.

Both screens refresh every five seconds and provide manual refresh. Buttons
are disabled while saving. After an uncertain network response, **Retry last
entry/exit** reuses the request ID and cannot count twice. Keep the page open
until the uncertain count is resolved; a reload does not retain that retry.

### Manager attendance

Sign in as `manager@clicker.test`. Filter by venue, active/closed status or event
name. Summary totals reflect the filtered events. Each row shows its event,
venue, start time, status, entries, exits, people inside, and venue capacity.
Closed events retain historical totals. Entries include re-entry and are not a
count of unique people. Managers cannot edit attendance totals.

The deliverable supplies three example events. An administrator can configure
more events using NocoBase's collection/page configuration.

## Sample data

The active events carry forward the team's Sprint 2 opening balances: Harbor
Center has **412 of 500** occupants and Eastside Fieldhouse has **267 of 800**.
These opening balances are not newly generated click records. A closed **Harbor
Workshop** demonstrates history with 420 entries, 420 exits and zero inside.
All records represent fictional demo data.

New actions are stored in `entryRecords` and `exitRecords`. The original
`clickEvents` hardware-event prototype remains separate; it is not another
source of Sprint 3 attendance totals.

## Implementation

NocoBase provides authentication, roles, collections, API requests and native
page blocks. There is no separate website or external API service.

Each count inserts an immutable record and updates the event and venue in one
PostgreSQL transaction. Row locks serialize concurrent counts. Database checks
reject duplicate request IDs, invalid stations, closed events, entry beyond
capacity and exits below zero. Staff cannot directly edit totals or records.

NocoBase workflows were considered. A database trigger handles counting so
capacity validation and both total updates are atomic, even when different
attendants click at once. No manual workflow activation is needed.

## Persistence and submission contents

The ZIP contains **compose.yml, README.md, the complete storage bind mount,
wireframes, UI source, migrations and seed files**. The latter files are included
because Compose references them. The application and database were stopped
before the raw database files were copied into the archive.

| Host path | Container path | Contents |
| --- | --- | --- |
| `./storage` | `/app/nocobase/storage` | Runtime files and uploads |
| `./storage/db/postgres` | `/var/lib/postgresql/data` | Records, users, roles and page layouts |
| Individual `./scripts` and `./seed` files | Read-only startup mounts | Migrations, initial database and logo |

For a fresh Git clone without `storage/`, startup restores the team seed and
applies the Sprint 3 migration. Repeated startup preserves records and passwords.
Do not delete `storage/` to restart the site.

```bash
docker compose down
docker compose up -d --wait --wait-timeout 600
```

To make a logical backup:

```bash
docker compose exec -T postgres pg_dump -U nocobase -d nocobase --no-owner --no-acl > backup.sql
```

Keep backups outside Git. Stop services before copying raw storage directories.
The original ERD and network PNGs are the team's Sprint 2 references; the team
report and updated network diagram belong to Deliverable 3.

## Troubleshooting and verification

```bash
docker compose ps -a
docker compose logs --tail=80 postgres prototype-migrations app
```

Wait for the app health check before signing in. A maintenance page during
startup is normal. If an administrator changed a password, use that password;
startup does not reset it.

See `docs/sprint3-validation.md` for completed checks. The optional integration
test `python3 scripts/test-sprint3.py` writes prefixed test records. Run it against
a disposable copy, not an installation with real counts. To rebuild page
configuration after editing `ui/`, run `python3 scripts/build-sprint3.py`, stop
the app, and start Compose again. No source rebuild is needed to use the ZIP.
