# Portable demo seed

`prototype.sql` was exported from Ayoola's configured Sprint 2 prototype after
adding native View/Edit record actions and their default popup forms through
NocoBase's `flowSurfaces:addRecordAction` API. It includes the three pages,
eight domain collections, their relationships and demo records, and the shared
course administrator (`admin@nocobase.com` / `admin123`).

Login tokens, token blacklists, one-time passwords, and OIDC state are excluded.
The only uploaded asset is the included NocoBase logo. This is demo data.

The official PostgreSQL image imports the SQL on an empty data directory.
Existing installations receive `scripts/migrate-table-actions.sql`, which adds
the same model/template IDs without replacing existing rows. The migration
checks for the four original prototype table IDs before applying and uses
`ON CONFLICT DO NOTHING`, so it can also run after a fresh import.

To intentionally refresh this seed from a configured demo installation, export
with PostgreSQL 16 (do not export real users' or operational data):

```bash
docker compose exec -T postgres pg_dump -U nocobase -d nocobase \
  --no-owner --no-acl \
  --exclude-table-data='public."issuedTokens"' \
  --exclude-table-data='public."tokenBlacklist"' \
  --exclude-table-data='public."oidcStates"' \
  --exclude-table-data='public."otpRecords"' > seed/prototype.sql
```

Keep referenced upload assets and the tested NocoBase image in sync with the
export. Validate it in a separate checkout with empty storage before committing.
Runtime PostgreSQL files must remain ignored by Git.
