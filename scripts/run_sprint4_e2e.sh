#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Starting Docker stack..."
docker compose up -d --wait --wait-timeout 600

docker compose --profile e2e-test up -d --wait selenium

export BASE_URL="http://host.docker.internal:13003"
export SELENIUM_URL="http://selenium:4444/wd/hub"

echo "Running Sprint 4 Selenium tests..."
python -m pytest -q ./e2e-test/test_sprint4_roles.py

echo "Sprint 4 Selenium tests finished."
