# NocoBase with Docker Compose

This project uses Docker Compose to run NocoBase with a PostgreSQL database.
You don't need to install Node.js or PostgreSQL separately.

## Requirements

- Docker Desktop for Windows or macOS, or Docker Engine for Linux
- Docker Compose v2, which is included with Docker Desktop
- Port `13000` must be available on the computer

Make sure Docker is running before continuing. You can confirm that Docker
Compose is available with:

```bash
docker compose version
```

## Start NocoBase

Keep `compose.yml` and `README.md` together in the same project folder. Open a
terminal in that folder and run:

```bash
docker compose up -d
```

The `-d` option runs the containers in the background, so you can continue
using the terminal while NocoBase is running.

The first startup may take a few minutes because Docker needs to download the
images and NocoBase needs to set up its database. You can check the container
status with:

```bash
docker compose ps
```

The PostgreSQL service should show as healthy before you try to use NocoBase.

If you want to watch the application logs, run:

```bash
docker compose logs -f app
```

Once the application is ready, open this address in a browser:

<http://localhost:13000>

## Login

- Email: `admin@nocobase.local`
- Password: `admin123`

If you plan to keep or share this installation, change the password after you
sign in. These login settings only apply when the database is created for the
first time.

## Stop or restart NocoBase

To stop the containers without deleting the saved application data, run:

```bash
docker compose down
```

To start them again, run:

```bash
docker compose up -d
```

To restart the running containers, use:

```bash
docker compose restart
```

## Stored data

NocoBase and PostgreSQL save their data in a `storage/` folder, which Docker
creates automatically the first time the application starts. Running
`docker compose down` will not delete this data.

For a fresh installation, stop the containers and delete the `storage/` folder
before starting them again. Deleting this folder permanently removes all
application and database data, so make a backup first if you need to keep it.

## Troubleshooting

If port `13000` is already being used, update the port mapping in `compose.yml`.
For example, change `127.0.0.1:13000:80` to `127.0.0.1:13001:80`, then open
<http://localhost:13001>.

To view recent logs for both services, run:

```bash
docker compose logs --tail=100 app postgres
```
