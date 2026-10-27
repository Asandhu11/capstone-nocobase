#!/bin/sh
# Verify the exact archive using only its extracted files and data.
set -eu
cd "$(dirname "$0")/.."
archive="$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "${1:-dist/Sprint4_Ayoola_Deliverable1.zip}")"
run_id="$(date +%Y%m%d-%H%M%S)-$$"
project="clicker-s4-zip-$run_id"
run_dir="$PWD/.test-runs/zip-$run_id"
mkdir -p "$run_dir/verification-results"
python3 - "$archive" "$run_dir/extracted" <<'PY'
from pathlib import Path
import sys
import zipfile
archive, output = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(archive) as bundle:
    for member in bundle.infolist():
        path = (output / member.filename).resolve()
        if output.resolve() not in path.parents:
            raise SystemExit('Unsafe archive path: ' + member.filename)
    bundle.extractall(output)
print('Extracted:', output)
PY
cd "$run_dir/extracted"
export CLICKER_STORAGE="$run_dir/extracted/storage"
export E2E_RESULTS="$run_dir/verification-results"
export NOCOBASE_PORT="${E2E_PORT:-13145}"
cleanup() {
  status=$?
  trap - EXIT
  docker compose -p "$project" --profile e2e logs --no-color > "$E2E_RESULTS/compose.log" 2>&1 || true
  docker compose -p "$project" --profile e2e down || true
  python3 - "$archive" "$run_dir" "$status" <<'PY' || status=1
import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
archive, run, status = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])
report = run / 'verification-results/results.xml'
counts = {'tests': 0, 'failures': 0, 'errors': 0, 'skipped': 0}
if report.exists():
    xml = ET.parse(report).getroot()
    for key, tag in [('tests','testcase'),('failures','failure'),('errors','error'),('skipped','skipped')]:
        counts[key] = len(list(xml.iter(tag)))
passed = status == 0 and counts['tests'] >= 8 and all(counts[k] == 0 for k in ['failures','errors','skipped'])
summary = {'archive': str(archive), 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
           'passed': passed, 'exit_code': status, **counts,
           'extracted_storage': str(run / 'extracted/storage'), 'results': str(report)}
(run / 'verification.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary, indent=2))
if not passed:
    raise SystemExit(1)
PY
  echo "Archive verification evidence: $run_dir"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
docker compose -p "$project" config > "$E2E_RESULTS/compose-resolved.yml"
docker compose -p "$project" --profile e2e up -d --wait --wait-timeout 600 app selenium
docker compose -p "$project" --profile e2e run --rm --build e2e
