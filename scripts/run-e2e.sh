#!/bin/sh
# Run against new bind mounts every time; never reuse the participant/demo data.
set -eu
cd "$(dirname "$0")/.."
run_id="$(date +%Y%m%d-%H%M%S)-$$"
project="clicker-s4-$run_id"
run_dir="$PWD/.test-runs/$run_id"
mkdir -p "$run_dir/storage" "$run_dir/results"
export CLICKER_STORAGE="$run_dir/storage"
export E2E_RESULTS="$run_dir/results"
export NOCOBASE_PORT="${E2E_PORT:-13144}"
cleanup() {
  status=$?
  trap - EXIT
  docker compose -p "$project" --profile e2e logs --no-color > "$run_dir/results/compose.log" 2>&1 || true
  docker compose -p "$project" --profile e2e down || true
  echo "Evidence and stopped test data: $run_dir"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
docker compose -p "$project" --profile e2e up -d --wait --wait-timeout 600 app selenium
docker compose -p "$project" --profile e2e run --rm --build e2e "$@"
