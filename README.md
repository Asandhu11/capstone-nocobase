# NocoBase via Docker Compose

This repository contains a `compose.yml` that starts a fully working [NocoBase](https://github.com/nocobase/nocobase) installation (a low-code / no-code application platform) using Docker Compose. It runs two containers:

1. **postgres** – the Postgres database that stores all of NocoBase's data
2. **app** – the NocoBase server and web UI

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

1. Download/clone this repository so that `compose.yml` and `README.md` are in the same folder on your computer.
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

## Stopping the app

- If you ran `docker compose up` in the foreground, press `Ctrl+C` in that terminal.
- If you ran it with `-d` (detached/background mode), stop it with:

  ```bash
  docker compose down
  ```

Your data is **not** deleted when you stop or run `docker compose down` — it's saved on your computer in a `storage/` folder that gets created next to `compose.yml` (this is set up via Docker "volumes" in `compose.yml`). To completely wipe the data and start fresh, stop the containers and then delete the `storage/` folder.

## How it works (quick overview)

- `compose.yml` defines two **services**: `postgres` (the database) and `app` (NocoBase itself).
- The `app` service is told how to reach the database through environment variables (`DB_HOST=postgres`, `DB_USER=nocobase`, etc.) — `postgres` here is just the service name Docker Compose uses as a hostname on the shared internal network defined at the bottom of the file.
- The `ports` line `'13000:80'` maps port 80 inside the `app` container (where NocoBase listens) to port 13000 on your computer, which is why you visit `http://localhost:13000` in your browser.
- The `volumes` lines make sure your database and uploaded files are stored in a `storage/` folder on your computer, not just inside the temporary container, so nothing is lost if you stop and restart.

## Troubleshooting

- **"port is already allocated" error**: something else on your computer is already using port 13000. Either stop that program, or change the left-hand side of the `ports` mapping in `compose.yml` (e.g. `'14000:80'`) and then visit `http://localhost:14000` instead.
- **Page won't load yet**: give it another minute — the very first startup runs a database migration and can take a bit longer than later restarts.
- **Need to reset everything**: run `docker compose down`, delete the `storage/` folder, then `docker compose up` again to start from a clean install.
