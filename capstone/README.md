# Alternate Compose entry point

This starts the same Clicker Occupancy Prototype as the repository root, on
<http://localhost:13000>. Keep this directory inside the repository so the
shared `../scripts/` and `../seed/` files are available.

```bash
docker compose up -d --wait --wait-timeout 600
```

Sign in with **admin@nocobase.com** / **admin123**. On first startup, the portable
export restores the three pages, eight collections, sample data, and View/Edit
forms automatically. The migration service exits with code 0 after completion.

This entry point preserves its existing Compose project name (`nocobase`) and
stores runtime data under `capstone/storage/`. The root entry point uses a
separate storage folder. Use one consistently to keep working on the same data.
Runtime data is ignored by Git and survives `docker compose down`.

See [the main README](../README.md) for actions, backups, upgrades, and
troubleshooting. Its commands apply here too; the default port is 13000.
