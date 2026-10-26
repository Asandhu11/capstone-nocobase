"""Create fresh synthetic tasks for ONE participant without resetting old data."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import os

from fixtures import FixtureAPI

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--participant', choices=['P1', 'P2', 'P3'], default='P1')
args = parser.parse_args()
participant = args.participant
api = FixtureAPI()
cases = {
    'T2 entry': api.scenario(participant + ' Arrival', inside=2, capacity=5),
    'T3 exit': api.scenario(participant + ' Departure', inside=1, capacity=5),
    'T4 capacity': api.scenario(participant + ' Capacity', inside=4, capacity=5),
}
output = Path(os.environ.get('E2E_ARTIFACTS', '../../test-results'))
output.mkdir(parents=True, exist_ok=True)
stem = 'participant-scenarios-' + participant + '-' + datetime.now().astimezone().strftime('%Y%m%dT%H%M%S%z')
path = output / (stem + '.json')
path.write_text(json.dumps(cases, indent=2))
for task, case in cases.items():
    print(task + ':')
    print('  Event:', case['event']['name'])
    print('  Venue:', case['venue']['name'])
    print('  Entry station:', case['stations']['Entry Gate']['name'])
    print('  Exit station:', case['stations']['Exit Gate']['name'])
print('Facilitator setup saved to', path)
entry, exit_, capacity = cases.values()
prompts = [
    ('T1 / Entry attendant / 3 minutes', 'You are starting a shift. Use these account details to reach the screen for your work. Tell me how you know it is the right screen.'),
    ('T2 / Entry attendant / 4 minutes', f"One guest arrives at {entry['stations']['Entry Gate']['name']} for {entry['event']['name']}. Record the arrival and tell me how many people are now inside and how you know it was saved. Refresh the page and check the count again."),
    ('T3 / Exit attendant / 4 minutes', f"The last guest leaves {exit_['event']['name']} through {exit_['stations']['Exit Gate']['name']}. Record the departure. Then explain what you would do if asked to record another exit."),
    ('T4 / Entry attendant / 4 minutes', f"There are four guests at {capacity['event']['name']}, which holds five. One more arrives, then another. Handle both arrivals and explain what the system tells you."),
    ('T5 / Manager / 4 minutes', f"Find the active {entry['event']['name']} at {entry['venue']['name']}. Report its entries, exits and people inside. Search for an event called No Such Event, then return to the event you were reviewing."),
    ('T6 / Manager / 3 minutes', 'Find the completed Harbor Workshop at Harbor Center. Tell me its total entries, exits and people still inside. Explain whether 420 entries necessarily means 420 different people.'),
]
lines = [
    f'CLICKER SPRINT 4 - {participant} SESSION NOTES',
    f'Website: {api.base}',
    'No real observations have been entered. Fill from this participant only.',
    '',
    'FACILITATOR ONLY',
    'Confirm participant is outside this class. Ask permission to take notes.',
    'Read each prompt without explaining how to perform it. Ask them to think aloud.',
    'Use a fresh private browser window for each role change; close the previous one.',
    'Demo accounts: entry@clicker.test / exit@clicker.test / manager@clicker.test',
    'All demo passwords: admin123. Repeat sign-in when moving between roles.',
    'After each task ask: Ease from 1 (very difficult) to 7 (very easy)? What was confusing?',
    '',
    'Date/time/timezone:', 'Not in this class confirmed:', 'Web experience:',
    'Device / OS / browser / viewport:', 'Permission to take notes:', '',
]
for title, prompt in prompts:
    lines += [title, 'Read aloud: ' + prompt, '',
              'Outcome (unassisted / assisted / failed / not attempted):',
              'Seconds (or not recorded):', 'Ease 1-7 (or not recorded):',
              'What happened / confusion / mistakes:', 'Help given:',
              'Exact quote (only if captured):', 'Evidence ID / screenshot:', '', '']
lines += ['DEBRIEF', 'Top three improvements requested:', '',
          'FACILITATOR EXPECTATIONS (do not read as instructions)',
          'T2: count 2 -> 3, one saved entry, stays 3 after refresh.',
          'T3: count 1 -> 0; further exit disabled.',
          'T4: count 4 -> 5; second arrival blocked at capacity.',
          'T5: use actual post-T2 counts (3/0/3 if T2 succeeded).',
          'T6: 420 entries, 420 exits, 0 inside; entries may include re-entry.']
notes = output / (stem + '.txt')
notes.write_text('\n'.join(lines) + '\n')
print('Ready-to-use prompts and observation sheet:', notes)
