"""Package stopped Clicker data, preserving every empty bind-mount directory.

Use --storage and --results to package an isolated validated installation
without stopping the separate participant website. Never overwrites a ZIP.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--storage', type=Path, default=Path(os.environ.get('CLICKER_STORAGE', root / 'storage')))
parser.add_argument('--results', type=Path, default=root / 'test-results')
parser.add_argument('--output', type=Path, default=root / 'dist/Sprint4_Ayoola_Deliverable1.zip')
args = parser.parse_args()
storage = args.storage.resolve()
results = args.results.resolve()
archive = args.output.resolve()

# Check the selected bind mount across ALL running containers. Checking only
# this folder's Compose project misses isolated runs and custom projects.
running = subprocess.check_output(['docker', 'ps', '-q'], text=True).split()
if running:
    containers = json.loads(subprocess.check_output(['docker', 'inspect', *running], text=True))
    for container in containers:
        for mount in container.get('Mounts', []):
            if mount.get('Type') != 'bind':
                continue
            source = Path(mount['Source']).resolve()
            if source == storage or source in storage.parents or storage in source.parents:
                raise SystemExit(f"Stop {container['Name'].lstrip('/')} before packaging its bind mount: {storage}")
database = storage / 'db/postgres'
for required in ['PG_VERSION', 'global/pg_control', 'base', 'pg_wal']:
    if not (database / required).exists():
        raise SystemExit(f'Database is incomplete: {database / required} is missing.')
if (database / 'PG_VERSION').read_text().strip() != '16':
    raise SystemExit('The selected database does not match the PostgreSQL 16 service.')
if (database / 'postmaster.pid').exists():
    raise SystemExit('Database shutdown is not confirmed: postmaster.pid still exists.')
if archive.exists():
    raise SystemExit(f'{archive} already exists. Rename it before creating a new package.')
if not (results / 'results.xml').is_file():
    raise SystemExit(f'A Selenium report is required: {results / "results.xml"}')
report = ET.parse(results / 'results.xml').getroot()
cases = list(report.iter('testcase'))
if len(cases) < 8 or any(list(report.iter(tag)) for tag in ['failure', 'error', 'skipped']):
    raise SystemExit('Package a full passing Selenium run: at least 8 tests, no failures, errors or skips.')

paths = [(root / name, Path(name)) for name in [
    'compose.yml', 'README.md', '.gitattributes', '.gitignore', 'scripts',
    'seed', 'ui', 'tests', 'docs',
]] + [(storage, Path('storage')), (results, Path('test-results'))]
skip = {'node_modules', '__pycache__', '.pytest_cache', '.DS_Store', '.env', '.git'}
archive.parent.mkdir(parents=True, exist_ok=True)
descriptor, temporary = tempfile.mkstemp(prefix=archive.name + '.', suffix='.partial', dir=archive.parent)
os.close(descriptor)
partial = Path(temporary)
manifest = []
try:
    with zipfile.ZipFile(partial, 'w', zipfile.ZIP_DEFLATED) as bundle:
        for base, destination in paths:
            candidates = [base] + (sorted(base.rglob('*')) if base.is_dir() else [])
            for path in candidates:
                rel = destination / path.relative_to(base)
                if any(part in skip or part.startswith('._') for part in rel.parts):
                    continue
                if path.is_symlink():
                    raise SystemExit(f'Inspect symlink before packaging: {path}')
                name = rel.as_posix() + ('/' if path.is_dir() else '')
                bundle.write(path, name)
                manifest.append(name)
        bundle.writestr('submission-manifest.json', json.dumps({
            'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip(),
            'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
            'working_tree_changes': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=root, text=True).strip()),
            'note': 'Includes current source and cleanly stopped bind mounts. Participant data is kept separately.',
            'paths': manifest,
        }, indent=2))
    with zipfile.ZipFile(partial) as bundle:
        bad = bundle.testzip()
        if bad:
            raise SystemExit(f'Archive integrity failure: {bad}')
    # link() fails if another process created the destination in the meantime.
    os.link(partial, archive)
finally:
    if partial.exists():
        partial.unlink()
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix('.sha256').write_text(f'{digest}  {archive.name}\n')
print(archive)
print('SHA256:', digest)
print('Next: extract this exact ZIP to a new directory and run the full Selenium suite there.')
