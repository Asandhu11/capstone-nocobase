#!/bin/sh
set -eu

# Older checkouts tracked raw PostgreSQL files and omitted empty directories.
# Repair those installs; leave fresh initialization and SQL restore to Postgres.
if [ -f "$PGDATA/PG_VERSION" ]; then
  for directory in pg_commit_ts pg_dynshmem pg_logical/mappings \
    pg_logical/snapshots pg_notify pg_replslot pg_serial pg_snapshots \
    pg_stat_tmp pg_tblspc pg_twophase pg_wal/archive_status; do
    mkdir -p "$PGDATA/$directory"
  done
fi

exec docker-entrypoint.sh "$@"
