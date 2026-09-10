#!/bin/sh
set -eu

# Git omits empty directories from the included PostgreSQL snapshot. Restore
# only that directory structure; leave new database initialization to Postgres.
if [ -f "$PGDATA/PG_VERSION" ]; then
  for directory in pg_commit_ts pg_dynshmem pg_logical/mappings \
    pg_logical/snapshots pg_notify pg_replslot pg_serial pg_snapshots \
    pg_stat_tmp pg_tblspc pg_twophase pg_wal/archive_status; do
    mkdir -p "$PGDATA/$directory"
  done
fi

exec docker-entrypoint.sh "$@"
