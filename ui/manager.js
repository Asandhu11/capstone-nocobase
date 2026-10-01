const React = ctx.libs.React, h = React.createElement;
const { useState, useEffect, useRef } = React;
const { Select, Input, Button, Table, Tag, Alert } = ctx.libs.antd;
function Screen() {
  const [events, setEvents] = useState([]), [venues, setVenues] = useState([]);
  const [venue, setVenue] = useState(), [status, setStatus] = useState(), [search, setSearch] = useState('');
  const [error, setError] = useState(''), [updated, setUpdated] = useState(''), [loading, setLoading] = useState(false);
  const alive = useRef(true), sequence = useRef(0);
  async function all(name, params = {}) {
    const rows = [];
    for (let page = 1; ; page++) {
      const response = await ctx.api.request({ url: name + ':list', params: { ...params, page, pageSize: 200 } });
      const batch = response.data.data || []; rows.push(...batch);
      if (batch.length < 200) return rows;
    }
  }
  async function refresh() {
    const seq = ++sequence.current;
    setLoading(true);
    try {
      const [es, vs] = await Promise.all([all('attendanceEvents', { appends: ['venue'], sort: ['-startsAt'] }), all('venues', { sort: ['name'] })]);
      if (alive.current && seq === sequence.current) { setEvents(es); setVenues(vs); setError(''); setUpdated(new Date().toLocaleTimeString()); }
    } catch (_) { if (alive.current && seq === sequence.current) setError('Could not refresh attendance. Displayed values may be out of date. Try Refresh attendance.'); }
    finally { if (alive.current && seq === sequence.current) setLoading(false); }
  }
  useEffect(() => { alive.current = true; refresh(); const timer = setInterval(refresh, 5000);
    return () => { alive.current = false; sequence.current++; clearInterval(timer); }; }, []);
  const rows = events.filter(e => (!venue || String(e.venueId) === String(venue)) && (!status || e.status === status) &&
    e.name.toLowerCase().includes(search.trim().toLowerCase()));
  const total = key => rows.reduce((sum, e) => sum + Number(e[key] || 0), 0).toLocaleString();
  const columns = [
    { title: 'Event / venue', dataIndex: 'name', render: (_, e) => h('div', null, h('strong', null, e.name), h('div', { style: { color: '#526278', fontSize: 14 } }, e.venue?.name || 'Unknown venue')) },
    { title: 'Starts', dataIndex: 'startsAt', render: x => x ? new Date(x).toLocaleString() : '-' },
    { title: 'Status', dataIndex: 'status', render: x => h(Tag, { color: x === 'active' ? 'blue' : 'default' }, x) },
    ...[['Entries', 'totalEntries'], ['Exits', 'totalExits'], ['Inside', 'currentInside']].map(([title, dataIndex]) => ({ title, dataIndex, align: 'right', sorter: (a,b) => Number(a[dataIndex]) - Number(b[dataIndex]), render: x => Number(x).toLocaleString() })),
    { title: 'Venue capacity', align: 'right', render: (_, e) => Number(e.venue?.maxCapacity || 0).toLocaleString() }
  ];
  const label = { display: 'block', fontSize: 14, fontWeight: 600, marginBottom: 8 };
  return h('section', { style: { maxWidth: 1400, margin: '0 auto', padding: 12, color: '#172b4d', fontSize: 16 } },
    h('h1', { style: { fontSize: 30, margin: '0 0 24px' } }, 'Manager attendance'),
    h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 20, marginBottom: 24 } },
      h('div', { style: { flex: '1 1 240px' } }, h('label', { style: label, htmlFor: 'attendance-venue' }, 'Venue'), h(Select, { id: 'attendance-venue', 'aria-label': 'Venue', size: 'large', style: { width: '100%' }, allowClear: true, placeholder: 'All venues', value: venue, onChange: setVenue, options: venues.map(v => ({ value: v.id, label: v.name })) })),
      h('div', { style: { flex: '1 1 200px' } }, h('label', { style: label, htmlFor: 'attendance-status' }, 'Event status'), h(Select, { id: 'attendance-status', 'aria-label': 'Event status', size: 'large', style: { width: '100%' }, allowClear: true, placeholder: 'All statuses', value: status, onChange: setStatus, options: ['active', 'closed'].map(x => ({ value: x, label: x === 'active' ? 'Active' : 'Closed' })) })),
      h('div', { style: { flex: '1 1 240px' } }, h('label', { style: label, htmlFor: 'attendance-search' }, 'Search events'), h(Input, { id: 'attendance-search', size: 'large', placeholder: 'Event name...', value: search, onChange: e => setSearch(e.target.value), allowClear: true }))),
    h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 20, marginBottom: 24 } },
      ...[['TOTAL ENTRIES','totalEntries'], ['TOTAL EXITS','totalExits'], ['CURRENTLY INSIDE','currentInside']].map(([title,key]) =>
        h('div', { key, style: { flex: '1 1 200px', padding: 24, border: '1px solid #d9e2ef', borderRadius: 10, background: '#f5f8fc' } }, h('div', { style: { fontSize: 14, fontWeight: 600 } }, title), h('div', { style: { fontSize: 40, fontWeight: 700 } }, total(key))))),
    error && h(Alert, { message: error, type: 'error', showIcon: true, style: { marginBottom: 20 } }),
    h(Table, { rowKey: 'id', columns, dataSource: rows, pagination: { pageSize: 10, showSizeChanger: false }, loading, scroll: { x: 900 }, locale: { emptyText: 'No events match these filters.' } }),
    h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 18, alignItems: 'center', marginTop: 16 } }, h(Button, { size: 'large', onClick: refresh, loading }, 'Refresh attendance'), h('span', { style: { fontSize: 14, color: '#526278' } }, updated ? 'Updated ' + updated + ' · refreshes every 5 seconds' : 'Loading attendance...')),
    h('p', { style: { fontSize: 14, color: '#526278' } }, 'Totals reflect the filtered events. Entries include re-entry, not unique individuals. Historical events retain their totals.')
  );
}
ctx.render(h(Screen));
