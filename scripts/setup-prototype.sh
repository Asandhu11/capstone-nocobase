#!/usr/bin/env bash
set -euo pipefail

# PostgreSQL restores the collections, data, and UI from seed/prototype.sql on
# first startup. Existing databases receive only the additive migrations.
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec docker compose --project-directory "$PROJECT_DIR" \
  -f "$PROJECT_DIR/compose.yml" up -d --wait --wait-timeout 600
