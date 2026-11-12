# Clicker Sprint 5: HAProxy proxy server

**Developer:** Amninder Sandhu  |  **Branch:** `sprint5-Amninder`  |  **Proxy:** HAProxy 2.8 (`haproxy:2.8-alpine`)

Sprint 5 Deliverable 1 puts an open-source proxy server, **HAProxy**, in front of NocoBase.
Only the public routes (sign-in and the entry, exit and manager screens) can be used from
outside the intranet. Anything that could change NocoBase's configuration can only be reached
from inside the intranet, or from a work-from-home computer over a WireGuard VPN.

## How the network is laid out

```
 visitor / home laptop                       OFFICE INTRANET (10.77.2.0/24)
 (internet 10.77.1.0/24)
                                        +-----------------------------------------+
  browser --> localhost:13003 --+       |                                         |
                                |       |   +------------------+   +---------+    |
                                +--8080-+-> | HAProxy "proxy"  |-->| NocoBase|--> Postgres
                                        |   |  public face     |   |  (app)  |    |
  home Firefox --WireGuard tunnel-+     |   |  admin face 8081 |   +---------+    |
  (localhost:5800)  10.77.9.0/24  |     |   +------^-----------+                  |
                                  +-----+--> VPN gateway (vpn-server) ------------+
                                        +-----------------------------------------+
```

* **`proxy` (HAProxy)** is the only service published to your computer
  (`http://localhost:13003`). It has two faces:
  * **Public face**, port 8080: forwards only the public routes and answers every admin route
    with `403 Blocked by HAProxy`, no matter who asks.
  * **Admin face**, port 8081: listens only on the intranet address `10.77.2.10`, is never
    published to the host, and accepts only clients on the intranet (`10.77.2.0/24`).
* **`app` (NocoBase) and `postgres`** are on the intranet network only. They have no published
  ports, so the proxy is the only way in.
* **`vpn-server`** is a WireGuard gateway on the intranet. It listens for the tunnel on the
  internet network and hands tunnel traffic for port 8081 to HAProxy's admin face.
* **`wfh-vpn` + `wfh-browser`** are the "work from home" network: a laptop on the internet
  network that runs the other end of the WireGuard tunnel plus Firefox. Firefox sends its admin
  requests through the tunnel to the intranet proxy. You watch it in your own browser at
  `http://localhost:5800`.
* **`outsider`** (only started when asked) is an ordinary visitor on the internet with no VPN,
  used to prove the admin routes are blocked.

## Which routes are public and which are admin

The rules are in `proxy/haproxy.cfg`. Anything that changes data or configuration is refused unless it is one of the four calls listed below, and reading the plugin, user, and role lists is refused too.

| Route | From outside (public face) | Intranet or VPN (admin face) |
| --- | --- | --- |
| `/signin`, `/admin` and the Clicker pages (entry, exit, manager), static files, `/storage/uploads`, `/ws` | Allowed (GET) | Allowed |
| `GET /api/...` data reads the screens use (events, venues, entrances, records, page layout) | Allowed | Allowed |
| `POST /api/auth:signIn`, `auth:signOut`, `entryRecords:create`, `exitRecords:create` | Allowed | Allowed |
| `/admin/settings/...` (settings, plugin manager), `/signup` and the other sign-up pages | **Blocked** | Allowed |
| Any other `POST`, `PUT`, `PATCH` or `DELETE` under `/api/` (create or change collections, page layouts, roles, system settings, plugins) | **Blocked** | Allowed |
| `/api/users`, `/api/roles`, `/api/pm`, `/api/applicationPlugins`, `/api/app:` (except the few read calls every page load needs), `/api/authenticators` | **Blocked** | Allowed |
| Method-override headers, and unusual paths containing `/./`, `/../`, `%2f`, `%5c`, `%25` or `;` | **Blocked** | Allowed |

Paths are cleaned (`%2e` decoded, `//` merged, `..` removed) before the rules run, so tricks like
`/admin/../admin/settings` are still blocked.

## Run it

1. Start Docker Desktop (or Docker Engine with Compose v2).
2. Extract the ZIP and keep all its folders together (`compose.yml`, `proxy/`, `vpn/`, `scripts/`, `seed/`, `storage/`).
3. Open a terminal in the folder that holds `compose.yml`.
4. Run: `docker compose up -d --build --wait --wait-timeout 900`
   The first start builds the small VPN helper image, downloads the images, and restores the
   database, so it can take several minutes.
5. Open **http://localhost:13003** and sign in as `entry@clicker.test` / `admin123` to see the public site.

If port 13003 is busy, put `NOCOBASE_PORT=13004` in a `.env` file next to `compose.yml`.
The home browser uses port 5800; change the `5800:5800` line in `compose.yml` if it is busy.

## Verify it

**A. Public site works from outside.** At http://localhost:13003 sign in as the entry attendant
(`entry@clicker.test` / `admin123`), pick an event and station, and record one entry. It works.

**B. Admin routes are blocked from outside.** In the same browser, open
http://localhost:13003/admin/settings . You should see the plain-text message
`Blocked by HAProxy: admin screens are only available from the intranet or the VPN.`
Also try http://localhost:13003/signup (blocked, so strangers cannot create accounts).

**C. Automatic outside check.** Run:

```bash
docker compose --profile verify run --rm outsider
```

This is a visitor on the internet with no VPN. It checks that the public routes work, that 14 admin or
configuration requests are refused with HAProxy's 403, and that the admin face, the intranet address
and NocoBase itself cannot be reached at all. It ends with `Result: 22 passed, 0 failed`.

**D. Admin works from home over the VPN.** Open **http://localhost:5800**. This is the home
computer's Firefox. It opens `http://10.77.9.1:8081/` by itself, which is the VPN gateway's
address inside the tunnel. Sign in as `admin@nocobase.com` / `admin123`, then open the NocoBase
settings menu (Settings, Plugin manager, Collections). It works there but not from step B.

**E. Automatic VPN check.** Run:

```bash
docker compose exec wfh-vpn sh /verify-proxy.sh vpn
```

It confirms the tunnel has a handshake, the admin routes work through the VPN, the intranet address
cannot be reached without the tunnel, and the home laptop is still blocked from admin routes on the
public face. It ends with `Result: 26 passed, 0 failed`.

**F. Prove the VPN is what lets admin in.** Stop the gateway and refresh the home browser; the admin
page no longer loads. Start it again and it works.

```bash
docker compose stop vpn-server
docker compose start vpn-server
```

**G. Watch HAProxy decide.** Every request is logged. Blocked ones show status 403:

```bash
docker compose logs proxy | grep " 403 "
```

Stop everything with `docker compose down`. Do not delete `storage/` to restart the site.

## Files added in Sprint 5

| Path | What it is |
| --- | --- |
| `compose.yml` | Adds `proxy`, `vpn-server`, `wfh-vpn`, `wfh-browser`, `outsider`, the `internet` and `intranet` networks, and removes NocoBase's direct port |
| `proxy/haproxy.cfg` | HAProxy configuration (public face, admin face, all the route rules) |
| `vpn/Dockerfile`, `vpn/entrypoint.sh` | Helper image and the script that brings up each end of the WireGuard tunnel |
| `vpn/server/wg0.conf`, `vpn/home/wg0.conf` | WireGuard settings for the gateway and the home computer |
| `scripts/verify-proxy.sh` | The automatic checks used in steps C and E |

The WireGuard keys in `vpn/` are demo keys made for this project only. They protect nothing real.
Do not reuse them anywhere.

## Troubleshooting

* **`wg0` fails with "Protocol not supported" or "Unknown device type"** — the Docker host's Linux
  kernel has no WireGuard. Docker Desktop on Windows needs a recent WSL kernel (`wsl --update`, then
  restart Docker Desktop). On Linux, `sudo modprobe wireguard`.
* **`docker compose logs vpn-server wfh-vpn`** shows the tunnel messages. `wg show` inside either
  container shows the handshake time.
* **A normal screen shows a "Blocked by HAProxy" message** — find the request with the log command
  in step G. The rule that caused it is in `proxy/haproxy.cfg`.
* **The home browser window is blank** — wait for `wfh-browser` to finish starting
  (`docker compose ps`), then reload http://localhost:5800.
* **"Pool overlaps with other one"** — another Docker network already uses `10.77.0.0/16`. Change the
  `10.77.x.x` addresses consistently in `compose.yml`, `proxy/haproxy.cfg` and `vpn/`.

---

# Earlier work: Clicker Sprint 3

**Developer:** Ayoola Morakinyo

**Branch:** `sprint3-Ayoola`

**Base:** team `main` at `7f7bd2b74c7a75226137a9ac9c072961f2807956`

Sprint 3 Deliverable 1 adds separate NocoBase screens for entryway attendants,
exit attendants, and attendance managers. The original Sprint 2 collections and
administrator pages remain available.

## Start the website

1. Start Docker Desktop (or Docker Engine with Compose v2 on Linux).
2. Extract the ZIP. Keep all its directories together.
3. Open a terminal in the folder containing this README and `compose.yml`.
4. Run `docker compose up -d --wait --wait-timeout 600`.
5. Open **http://localhost:13003**. The first startup may take several minutes. Since Sprint 5 the site is served through HAProxy; see the top of this README.

No local Node.js, Python, PostgreSQL or NocoBase installation is needed to run
the submission. Start from the repository root, not the legacy `capstone/`
subdirectory. If the port is occupied, put `NOCOBASE_PORT=13004` in a `.env`
file next to Compose, start again, and open http://localhost:13004.

## Demo accounts

All accounts use the course-demo password **`admin123`**.

| Account | Email | Access |
| --- | --- | --- |
| Entryway attendant | `entry@clicker.test` | Entry screen and recording entries |
| Exit attendant | `exit@clicker.test` | Exit screen and recording exits |
| Attendance manager | `manager@clicker.test` | Read-only manager screen |
| Administrator | `admin@nocobase.com` | All screens and original administration pages (settings pages only from the intranet or over the VPN since Sprint 5) |

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
| `./proxy`, `./vpn` | Read-only mounts in `proxy`, `vpn-server`, `wfh-vpn` | HAProxy rules and WireGuard settings (Sprint 5) |
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
