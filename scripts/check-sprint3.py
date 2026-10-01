"""Read-only checks for a restored or restarted Sprint 3 submission."""
import importlib.util
from pathlib import Path

spec=importlib.util.spec_from_file_location('integration',Path(__file__).with_name('test-sprint3.py'))
t=importlib.util.module_from_spec(spec);spec.loader.exec_module(t)
for role in ['entry','exit','manager']:
    status,body=t.request('auth:signIn',{'email':role+'@clicker.test','password':'admin123'})
    t.check(status==200,role+' restored sign-in',body)
    t.TOKENS[role]=body['data']['token']
    status,body=t.request('flowModels:findOne',role=role,params={'uid':'s3_'+role+'_tab'})
    block=body.get('data',{}).get('subModels',{}).get('grid',{}).get('subModels',{}).get('items',[{}])[0]
    t.check(status==200 and block.get('use')=='JSBlockModel',role+' native screen tree is complete',body)
    code=block['stepParams']['jsSettings']['runJs']['code']
    expected=(Path(__file__).resolve().parents[1]/'ui'/('manager.js' if role=='manager' else 'attendant.js')).read_text().replace('__MODE__',role)
    t.check(code==expected,role+' stored screen matches the submitted source')
events=t.read('manager','attendanceEvents',appends=['venue'])
t.check(len(events)==3,'three sample events restored')
for event in events:
    t.check(int(event['currentInside'])==int(event['totalEntries'])-int(event['totalExits']),event['name']+' counts balance')
    t.check(bool(event.get('venue')),event['name']+' venue relationship restored')
