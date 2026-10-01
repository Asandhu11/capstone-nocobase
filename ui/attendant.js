// Installed as a native NocoBase JSBlockModel. MODE is supplied by the migration builder.
const MODE = '__MODE__';
const React = ctx.libs.React;
const h = React.createElement;
const { Button, Select, Alert, Table, Tag } = ctx.libs.antd;
const { useEffect, useRef, useState } = React;
const resource = MODE === 'entry' ? 'entryRecords' : 'exitRecords';
const number = value => Number(value || 0).toLocaleString();
async function list(name, params = {}) {
  const rows = [];
  for (let page = 1; ; page++) {
    const response = await ctx.api.request({ url: name + ':list', params: { pageSize: 200, ...params, page } });
    const batch = response.data.data || [];
    rows.push(...batch);
    if (params.pageSize || batch.length < 200) return rows;
  }
}
function Screen() {
  const [events, setEvents] = useState([]), [stations, setStations] = useState([]);
  const [eventId, setEventId] = useState(), [stationId, setStationId] = useState();
  const [records, setRecords] = useState([]), [busy, setBusy] = useState(false);
  const [error, setError] = useState(''), [saved, setSaved] = useState('');
  const [updated, setUpdated] = useState(''), [ready, setReady] = useState(false);
  const pending = useRef(null), lock = useRef(false), sequence = useRef(0), alive = useRef(true);
  const event = events.find(x => String(x.id) === String(eventId));
  const venue = event?.venue;
  const choices = stations.filter(x => x.active && String(x.venueId) === String(event?.venueId) &&
    (x.directionType === 'both' || x.directionType === (MODE === 'entry' ? 'in' : 'out')));
  async function refresh() {
    const current = ++sequence.current;
    try {
      const [es, ss, rr] = await Promise.all([
        list('attendanceEvents', { filter: { status: 'active' }, appends: ['venue'], sort: ['name'] }),
        list('entrances', { filter: { active: true }, sort: ['name'] }),
        list(resource, { sort: ['-createdAt'], pageSize: 8, appends: ['event', 'entrance'],
          ...(eventId ? { filter: { eventId } } : {}) })
      ]);
      if (!alive.current || current !== sequence.current) return;
      setEvents(es); setStations(ss); setRecords(rr); setError(''); setReady(true);
      setUpdated(new Date().toLocaleTimeString());
    } catch (e) {
      if (alive.current && current === sequence.current) {
        setReady(false); setError('Attendance could not be refreshed. Check your connection and select Refresh attendance.');
      }
    }
  }
  useEffect(() => { alive.current = true; refresh(); const timer = setInterval(refresh, 5000);
    return () => { alive.current = false; sequence.current++; clearInterval(timer); }; }, [eventId]);
  async function record() {
    if (lock.current) return;
    lock.current = true; setBusy(true); setSaved(''); setError('');
    if (!pending.current) pending.current = {
      eventId, entranceId: stationId,
      requestKey: MODE + '-' + Date.now() + '-' + Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2)
    };
    let successful = false;
    try {
      await ctx.api.request({ url: resource + ':create', method: 'post', data: pending.current });
      successful = true;
    } catch (e) {
      // A timeout may occur after commit. Look up the same request before retrying.
      try { successful = (await list(resource, { filter: { requestKey: pending.current.requestKey } })).length > 0; } catch (_) {}
      if (!successful) {
        const message = e.response?.data?.errors?.[0]?.message || e.message || 'Request failed';
        const rejected = /capacity|zero|active event|station|closed|permission|forbidden/i.test(message);
        if (rejected) pending.current = null;
        setError(rejected ? message : 'We could not confirm this count. Retry the last count; it will not be recorded twice.');
      }
    }
    if (successful) {
      pending.current = null; setSaved('One ' + MODE + ' saved at ' + new Date().toLocaleTimeString() + '.');
      await refresh();
    }
    lock.current = false; setBusy(false);
  }
  const atLimit = MODE === 'entry' ? Number(venue?.currentCount) >= Number(venue?.maxCapacity) : Number(event?.currentInside) <= 0;
  const disabled = !pending.current && (!ready || !event || !stationId || !choices.some(s => String(s.id) === String(stationId)) || atLimit || (MODE === 'entry' && venue?.status !== 'open'));
  const columns = [
    { title: 'Time', dataIndex: 'createdAt', render: x => new Date(x).toLocaleTimeString() },
    { title: 'Event', render: (_, x) => x.event?.name || 'Event' },
    { title: 'Station', render: (_, x) => x.entrance?.name || 'Station' },
    { title: 'Recorded', render: () => h(Tag, { color: MODE === 'entry' ? 'blue' : 'orange' }, '1 ' + MODE) }
  ];
  const labelStyle = { display: 'block', marginBottom: 8, fontWeight: 600, fontSize: 14 };
  return h('section', { style: { maxWidth: 1180, margin: '0 auto', padding: 12, color: '#172b4d', fontSize: 16 } },
    h('h1', { style: { fontSize: 30, margin: '0 0 24px' } }, MODE === 'entry' ? 'Entryway attendant' : 'Exit attendant'),
    h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 20, marginBottom: 24 } },
      h('div', { style: { flex: '2 1 300px' } }, h('label', { htmlFor: MODE + '-event', style: labelStyle }, 'Event'),
        h(Select, { id: MODE + '-event', 'aria-label': 'Event', size: 'large', style: { width: '100%' },
          placeholder: 'Select an active event', value: eventId, disabled: busy || !!pending.current,
          showSearch: true, optionFilterProp: 'label', options: events.map(e => ({ value: e.id, label: e.name + ' - ' + (e.venue?.name || '') })),
          onChange: x => { setEventId(x); setStationId(undefined); setSaved(''); } })),
      h('div', { style: { flex: '1 1 240px' } }, h('label', { htmlFor: MODE + '-station', style: labelStyle }, MODE === 'entry' ? 'Entrance station' : 'Exit station'),
        h(Select, { id: MODE + '-station', 'aria-label': 'Station', size: 'large', style: { width: '100%' },
          placeholder: 'Select a station', value: stationId, disabled: !event || busy || !!pending.current,
          options: choices.map(s => ({ value: s.id, label: s.name })), onChange: setStationId }))),
    h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 24, marginBottom: 20 } },
      h('div', { style: { flex: '2 1 300px', padding: 28, border: '1px solid #d9e2ef', borderRadius: 10, background: '#f5f8fc' } },
        h('div', { style: { fontSize: 14, fontWeight: 600 } }, 'PEOPLE INSIDE THIS EVENT'),
        h('div', { style: { fontSize: 76, fontWeight: 700, lineHeight: 1.3 } }, event ? number(event.currentInside) : '--'),
        h('div', null, venue ? number(venue.currentCount) + ' in venue / ' + number(venue.maxCapacity) + ' capacity' : 'Select an event to view attendance'),
        venue && h('div', { style: { marginTop: 14, fontWeight: 600 } }, number(Math.max(0, Number(venue.maxCapacity) - Number(venue.currentCount))) + ' spaces remaining at the venue')),
      h('div', { style: { flex: '1 1 260px', display: 'flex', flexDirection: 'column', gap: 14 } },
        h(Button, { type: 'primary', size: 'large', loading: busy, disabled, onClick: record,
          style: { height: 116, whiteSpace: 'normal', fontSize: 24, fontWeight: 600, background: disabled ? undefined : MODE === 'entry' ? '#1756a9' : '#9a4615' } },
          pending.current ? 'Retry last ' + MODE : (MODE === 'entry' ? '+ Record one entry' : '- Record one exit')),
        h('div', null, 'One click records one person.'),
        h(Button, { size: 'large', onClick: refresh, disabled: busy }, 'Refresh attendance'),
        h('span', { style: { fontSize: 14, color: '#526278' } }, updated ? 'Updated ' + updated + ' · refreshes every 5 seconds' : 'Loading attendance...'))),
    h('div', { 'aria-live': 'polite', style: { marginBottom: 20 } },
      error && h(Alert, { type: 'error', showIcon: true, message: error, style: { marginBottom: 10 } }),
      saved && h(Alert, { type: 'success', showIcon: true, message: saved }),
      event && atLimit && !pending.current && h(Alert, { type: 'warning', showIcon: true, message: MODE === 'entry' ? 'Venue is at capacity. Wait for an exit before recording another entry.' : 'This event is empty. An exit cannot reduce attendance below zero.' }),
      ready && !events.length && h(Alert, { type: 'info', message: 'There are no active events. Ask the administrator to open an event.' }),
      event && !choices.length && h(Alert, { type: 'warning', message: 'No active station is available for this event and direction.' })),
    h('h2', { style: { fontSize: 20 } }, 'Recent ' + (MODE === 'entry' ? 'entries' : 'exits')),
    h(Table, { rowKey: 'id', columns, dataSource: records, pagination: false, scroll: { x: 560 }, locale: { emptyText: 'No counts recorded yet.' }, size: 'middle' })
  );
}
ctx.render(h(Screen));
