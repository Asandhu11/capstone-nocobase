"""Integration checks against an isolated/local Sprint 3 demo (writes test records)."""
import concurrent.futures
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = os.environ.get('CLICKER_TEST_URL', 'http://localhost:13003').rstrip('/')+'/api/'
PREFIX='s3test-'+uuid.uuid4().hex+'-'
TOKENS={}

def request(route, data=None, role=None, params=None):
    headers={'Content-Type':'application/json','X-Authenticator':'basic'}
    if role:
        headers['Authorization']='Bearer '+TOKENS[role]
        headers['X-Role']='root' if role=='admin' else 'clicker_'+role
    if params:
        pairs=[]
        for k,v in params.items():
            if isinstance(v,list): pairs.extend((k+'[]',x) for x in v)
            else: pairs.append((k,json.dumps(v) if isinstance(v,dict) else v))
        route+='?'+urllib.parse.urlencode(pairs)
    req=urllib.request.Request(BASE+route,headers=headers,data=None if data is None else json.dumps(data).encode())
    try:
        with urllib.request.urlopen(req,timeout=60) as res:return res.status,json.load(res)
    except urllib.error.HTTPError as e:
        try:body=json.loads(e.read())
        except Exception:body={}
        return e.code,body

def check(condition,message,detail=None):
    if not condition:raise AssertionError(message+': '+str(detail))
    print('PASS',message,flush=True)

def read(role,table,**params):
    status,body=request(table+':list',role=role,params=params)
    check(status==200,role+' can read '+table,body)
    return body['data']

def event(id_):
    return read('manager','attendanceEvents',filter={'id':id_})[0]

def count(role,event_id,station_id,key):
    return request(('entryRecords' if role=='entry' else 'exitRecords')+':create',
       {'eventId':event_id,'entranceId':station_id,'requestKey':PREFIX+key},role)

def main():
    for role in ['admin','entry','exit','manager']:
        email='admin@nocobase.com' if role=='admin' else role+'@clicker.test'
        status,body=request('auth:signIn',{'email':email,'password':'admin123'})
        check(status==200 and body.get('data',{}).get('token'),role+' sign in',body)
        TOKENS[role]=body['data']['token']
    rows=read('manager','attendanceEvents',appends=['venue'])
    check(len(rows)>=3 and all(e.get('venue') for e in rows),'events have venue relationships')
    for role in ['entry','exit','manager']:
        status,body=request('desktopRoutes:listAccessible',role=role)
        check(status==200,role+' navigation is accessible',body)
        flat=str(body)
        check('s3_'+role+'_route' in flat,role+' has its screen',body)
        for other in {'entry','exit','manager'}-{role}:
            check('s3_'+other+'_route' not in flat,role+' cannot see '+other+' screen')
    ev=390000000000001; en=383436853477378; ex=383436853477379
    before=event(ev)
    status,body=count('entry',ev,en,'entry')
    check(status in (200,201),'record an entry',body)
    after=event(ev)
    check(int(after['currentInside'])==int(before['currentInside'])+1,'entry increments event occupancy')
    status,body=count('entry',ev,en,'entry')
    check(status>=400,'duplicate request is rejected',body)
    check(int(event(ev)['currentInside'])==int(after['currentInside']),'duplicate does not double count')
    status,body=count('exit',ev,ex,'exit')
    check(status in (200,201),'record an exit',body)
    check(int(event(ev)['currentInside'])==int(before['currentInside']),'exit decrements event occupancy')
    for role,station,label in [('entry',ex,'wrong direction'),('exit',383436853477380,'wrong venue'),('entry',383436853477381,'inactive station')]:
        status,body=count(role,ev,station,label)
        check(status>=400,'reject '+label,body)
    status,body=count('entry',390000000000003,en,'closed')
    check(status>=400,'reject closed event',body)
    for role,resource in [('manager','entryRecords'),('entry','exitRecords'),('exit','entryRecords')]:
        status,body=request(resource+':create',{'eventId':ev,'entranceId':en,'requestKey':PREFIX+'forbidden-'+role},role)
        check(status==403,role+' cannot write '+resource,body)
    for role in ['entry','exit','manager']:
        status,body=request('attendanceEvents:update',{'totalEntries':9999},role,{'filterByTk':ev})
        check(status==403,role+' cannot edit attendance totals',body)
    status,body=request('entryRecords:create',{'eventId':ev,'entranceId':en,'requestKey':PREFIX+'anonymous'})
    check(status in (401,403),'anonymous counts denied',body)
    # Concurrent requests must not lose increments. Pair with exits to restore occupancy.
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        results=list(pool.map(lambda n:count('entry',ev,en,'parallel-entry-'+str(n)),range(6)))
    check(all(s in (200,201) for s,_ in results),'six simultaneous entries succeed',results)
    check(int(event(ev)['currentInside'])==int(before['currentInside'])+6,'no concurrent increments lost')
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        results=list(pool.map(lambda n:count('exit',ev,ex,'parallel-exit-'+str(n)),range(6)))
    check(all(s in (200,201) for s,_ in results),'six simultaneous exits succeed',results)
    check(int(event(ev)['currentInside'])==int(before['currentInside']),'paired concurrent counts balance')
    # A brand-new empty event rejects exits without changing the venue.
    status,body=request('attendanceEvents:create',{'name':PREFIX+'empty','venueId':383436853477376,
        'status':'active','totalEntries':0,'totalExits':0,'currentInside':0},'admin')
    check(status in (200,201),'create isolated empty test event',body)
    empty_id=body['data']['id']
    try:
        status,body=count('exit',empty_id,ex,'zero')
        check(status>=400,'reject exit at zero',body)
        check(int(event(empty_id)['currentInside'])==0,'rejected exit leaves zero unchanged')
    finally:
        request('attendanceEvents:destroy',{},'admin',{'filterByTk':empty_id})
    venue=read('admin','venues',filter={'id':383436853477376})[0]
    original_capacity=venue['maxCapacity']
    try:
        request('venues:update',{'maxCapacity':int(venue['currentCount'])+1},'admin',{'filterByTk':venue['id']})
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            results=list(pool.map(lambda n:count('entry',ev,en,'last-space-'+str(n)),range(6)))
        check(sum(s in (200,201) for s,_ in results)==1,'only one concurrent entry takes the final space',results)
        check(int(event(ev)['currentInside'])==int(before['currentInside'])+1,'capacity race preserves exact occupancy')
        status,body=count('exit',ev,ex,'last-space-exit')
        check(status in (200,201),'exit frees capacity',body)
    finally:
        request('venues:update',{'maxCapacity':original_capacity},'admin',{'filterByTk':venue['id']})
    print('TEST_PREFIX='+PREFIX,flush=True)

if __name__=='__main__': main()
