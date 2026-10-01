// Exercise the real screen code with React hooks and the running NocoBase API.
// Ant Design controls are represented as test-renderer hosts, not a browser.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const React = require('react');
const TestRenderer = require('react-test-renderer');
const { act } = TestRenderer;
const base = process.env.CLICKER_TEST_URL || 'http://localhost:13003';
const tokens = {};
const calls = new Set();
let dropWriteResponse = false;
async function request(role, { url, params = {}, method = 'get', data }) {
  const u = new URL('/api/' + url, base);
  for (const [k,v] of Object.entries(params)) {
    if (Array.isArray(v)) for (const item of v) u.searchParams.append(k + '[]', item);
    else u.searchParams.set(k, typeof v === 'object' ? JSON.stringify(v) : v);
  }
  const response = await fetch(u, { method: method.toUpperCase(),
    headers: { 'Content-Type': 'application/json', 'X-Authenticator': 'basic',
      ...(tokens[role] ? { Authorization: 'Bearer ' + tokens[role], 'X-Role': 'clicker_' + role } : {}) },
    ...(data ? { body: JSON.stringify(data) } : {}) });
  const body = await response.json();
  if (!response.ok) { const error = new Error(body.errors?.[0]?.message || 'Request failed'); error.response = { data: body, status: response.status }; throw error; }
  if (dropWriteResponse && url.endsWith(':create')) { dropWriteResponse = false; throw new Error('Simulated response lost after commit'); }
  return { data: body };
}
async function drain() {
  do { await Promise.allSettled([...calls]); await new Promise(r => setImmediate(r)); } while (calls.size);
}
async function mount(role) {
  let renderer;
  const code = fs.readFileSync(path.join(__dirname, '..', 'ui', role === 'manager' ? 'manager.js' : 'attendant.js'), 'utf8').replace('__MODE__',role);
  const ctx = { libs: { React, antd: Object.fromEntries(['Button','Select','Alert','Table','Tag','Input'].map(x=>[x,x])) },
    api: { request: options => {
      const p = request(role, options); calls.add(p); p.then(()=>calls.delete(p),()=>calls.delete(p)); return p;
    } }, render: node => { renderer = TestRenderer.create(node); } };
  class TestDate extends Date { static now() { return 's3test-ui-' + Date.now(); } }
  await act(async () => { vm.runInNewContext(code, { ctx, Date: TestDate, setInterval:()=>1, clearInterval:()=>{}, console }); await drain(); });
  return renderer;
}
async function change(renderer,id,value) {
  await act(async()=> { renderer.root.findByProps({id}).props.onChange(value); await drain(); });
}
function countButton(renderer) {
  return renderer.root.findAllByType('Button').find(x=>x.props.type==='primary');
}
async function click(renderer) {
  assert.equal(countButton(renderer).props.disabled,false);
  await act(async()=> { await countButton(renderer).props.onClick(); await drain(); });
}
async function occupancy() {
  return Number((await request('manager',{url:'attendanceEvents:list',params:{filter:{id:390000000000001}}})).data.data[0].currentInside);
}
async function main() {
  for (const role of ['entry','exit','manager']) {
    const res = await request(role,{url:'auth:signIn',method:'post',data:{email:role+'@clicker.test',password:'admin123'}});
    tokens[role]=res.data.data.token;
  }
  const baseline=await occupancy();
  const entry=await mount('entry');
  assert.equal(countButton(entry).props.disabled,true);
  await change(entry,'entry-event',390000000000001);
  const stations=entry.root.findByProps({id:'entry-station'}).props.options;
  assert.equal(stations.length,1); assert.equal(stations[0].label,'North Gate');
  await change(entry,'entry-station',383436853477378);
  await click(entry); assert.equal(await occupancy(),baseline+1);
  console.log('PASS entry controls, station filtering, saved feedback and live count');
  dropWriteResponse=true;
  await click(entry); assert.equal(await occupancy(),baseline+2);
  assert.ok(entry.root.findAllByType('Alert').some(x=>x.props.type==='success'));
  console.log('PASS lost response after commit is reconciled without a duplicate count');
  const exit=await mount('exit');
  await change(exit,'exit-event',390000000000001);
  await change(exit,'exit-station',383436853477379);
  await click(exit); await click(exit); assert.equal(await occupancy(),baseline);
  console.log('PASS exit controls and matching event totals');
  const manager=await mount('manager');
  assert.ok(manager.root.findByType('Table').props.dataSource.length>=3);
  await change(manager,'attendance-venue',383436853477376);
  assert.equal(manager.root.findByType('Table').props.dataSource.length,2);
  await change(manager,'attendance-search',{target:{value:'Workshop'}});
  assert.equal(manager.root.findByType('Table').props.dataSource.length,1);
  await change(manager,'attendance-status','active');
  assert.equal(manager.root.findByType('Table').props.dataSource.length,0);
  console.log('PASS manager venue, search, status filters and empty state');
  await act(async()=>{entry.unmount();exit.unmount();manager.unmount();});
}
main().catch(error=>{console.error(error);process.exitCode=1;});
