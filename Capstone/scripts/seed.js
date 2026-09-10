const baseUrl = process.env.NOCOBASE_URL || 'http://localhost:13000';
const account = process.env.NOCOBASE_ADMIN_EMAIL || 'admin@nocobase.com';
const password = process.env.NOCOBASE_ADMIN_PASSWORD || 'admin123';

const collections = [
  {
    name: 'venues', title: 'Venues',
    fields: [
      { name: 'venue_id', type: 'string', unique: true }, { name: 'name', type: 'string', required: true },
      { name: 'timezone', type: 'string' }, { name: 'max_capacity', type: 'integer' }, { name: 'current_count', type: 'integer', defaultValue: 0 },
    ],
    records: [
      { venue_id: 'VENUE-001', name: 'Main Conference Hall', timezone: 'America/New_York', max_capacity: 500, current_count: 175 },
      { venue_id: 'VENUE-002', name: 'East Wing Meeting Room', timezone: 'America/New_York', max_capacity: 50, current_count: 8 },
      { venue_id: 'VENUE-003', name: 'Auditorium', timezone: 'America/New_York', max_capacity: 1000, current_count: 0 },
    ],
  },
  {
    name: 'entrances', title: 'Entrances',
    fields: [
      { name: 'entrance_id', type: 'string', unique: true }, { name: 'venue_id', type: 'string' }, { name: 'name', type: 'string', required: true },
      { name: 'direction_type', type: 'string' }, { name: 'location', type: 'string' }, { name: 'status', type: 'string' },
    ],
    records: [
      { entrance_id: 'ENT-001', venue_id: 'VENUE-001', name: 'Front Door', direction_type: 'entry', location: 'North lobby', status: 'active' },
      { entrance_id: 'ENT-002', venue_id: 'VENUE-001', name: 'Emergency Exit', direction_type: 'exit', location: 'East wall', status: 'active' },
      { entrance_id: 'ENT-003', venue_id: 'VENUE-002', name: 'Main Entry', direction_type: 'bidirectional', location: 'Ground floor', status: 'active' },
    ],
  },
  {
    name: 'devices', title: 'Devices',
    fields: [
      { name: 'device_id', type: 'string', unique: true }, { name: 'entrance_id', type: 'string' }, { name: 'name', type: 'string', required: true },
      { name: 'device_type', type: 'string' }, { name: 'client_id', type: 'string' }, { name: 'serial', type: 'string' }, { name: 'credentials', type: 'text' },
    ],
    records: [
      { device_id: 'DEV-001', entrance_id: 'ENT-001', name: 'Front Door Camera', device_type: 'camera' },
      { device_id: 'DEV-002', entrance_id: 'ENT-002', name: 'Emergency Exit Motion Sensor', device_type: 'motion_sensor' },
      { device_id: 'DEV-003', entrance_id: 'ENT-003', name: 'Meeting Room Entry Camera', device_type: 'camera' },
    ],
  },
  {
    name: 'click_events', title: 'Click Events',
    fields: [
      { name: 'click_id', type: 'string', unique: true }, { name: 'device_id', type: 'string' }, { name: 'entrance_id', type: 'string' },
      { name: 'event_type', type: 'string' }, { name: 'direction', type: 'string' }, { name: 'timestamp', type: 'datetime' },
      { name: 'processed_flag', type: 'boolean', defaultValue: false }, { name: 'metadata', type: 'text' },
    ],
    records: [
      { click_id: 'CLICK-001', device_id: 'DEV-001', entrance_id: 'ENT-001', event_type: 'person_entered', direction: 'entry', timestamp: '2026-09-08T09:00:00Z', processed_flag: true },
      { click_id: 'CLICK-002', device_id: 'DEV-001', entrance_id: 'ENT-001', event_type: 'person_entered', direction: 'entry', timestamp: '2026-09-08T09:05:00Z', processed_flag: true },
      { click_id: 'CLICK-003', device_id: 'DEV-002', entrance_id: 'ENT-002', event_type: 'motion_detected', direction: 'exit', timestamp: '2026-09-08T09:10:00Z', processed_flag: false },
    ],
  },
  {
    name: 'occupancy_snapshots', title: 'Occupancy Snapshots',
    fields: [
      { name: 'snapshot_id', type: 'string', unique: true }, { name: 'venue_id', type: 'string' }, { name: 'count', type: 'integer' },
      { name: 'source', type: 'string' }, { name: 'created_at', type: 'datetime' },
    ],
    records: [
      { snapshot_id: 'SNAP-001', venue_id: 'VENUE-001', count: 125, source: 'device_count', created_at: '2026-09-08T09:00:00Z' },
      { snapshot_id: 'SNAP-002', venue_id: 'VENUE-001', count: 150, source: 'device_count', created_at: '2026-09-08T10:00:00Z' },
      { snapshot_id: 'SNAP-003', venue_id: 'VENUE-001', count: 175, source: 'device_count', created_at: '2026-09-08T11:00:00Z' },
      { snapshot_id: 'SNAP-004', venue_id: 'VENUE-002', count: 8, source: 'device_count', created_at: '2026-09-08T11:00:00Z' },
    ],
  },
  {
    name: 'alerts', title: 'Alerts',
    fields: [
      { name: 'alert_id', type: 'string', unique: true }, { name: 'venue_id', type: 'string' }, { name: 'created_by_user_id', type: 'string' },
      { name: 'alert_type', type: 'string' }, { name: 'triggered_at', type: 'datetime' }, { name: 'resolved_at', type: 'datetime' },
      { name: 'message', type: 'text' }, { name: 'metadata', type: 'text' },
    ],
    records: [
      { alert_id: 'ALERT-001', venue_id: 'VENUE-001', created_by_user_id: account, alert_type: 'capacity_exceeded', triggered_at: '2026-09-08T11:05:00Z', message: 'Main Conference Hall exceeded 90% capacity' },
      { alert_id: 'ALERT-002', venue_id: 'VENUE-002', created_by_user_id: account, alert_type: 'device_offline', triggered_at: '2026-09-08T11:10:00Z', message: 'Camera DEV-003 went offline' },
      { alert_id: 'ALERT-003', venue_id: 'VENUE-001', created_by_user_id: account, alert_type: 'anomaly', triggered_at: '2026-09-08T11:15:00Z', message: 'Unusual occupancy spike detected' },
    ],
  },
  {
    name: 'audit_logs', title: 'Audit Logs',
    fields: [
      { name: 'audit_id', type: 'string', unique: true }, { name: 'actor_user_id', type: 'string' }, { name: 'entity_type', type: 'string' },
      { name: 'entity_id', type: 'string' }, { name: 'details', type: 'text' }, { name: 'created_at', type: 'datetime' },
    ],
    records: [
      { audit_id: 'AUDIT-001', actor_user_id: account, entity_type: 'venue', entity_id: 'VENUE-001', details: 'Updated max_capacity from 400 to 500', created_at: '2026-09-08T11:20:00Z' },
      { audit_id: 'AUDIT-002', actor_user_id: account, entity_type: 'alert', entity_id: 'ALERT-001', details: 'Created capacity alert', created_at: '2026-09-08T11:21:00Z' },
    ],
  },
  {
    name: 'notification_subscriptions', title: 'Notification Subscriptions',
    fields: [
      { name: 'subscription_id', type: 'string', unique: true }, { name: 'user_id', type: 'string' }, { name: 'venue_id', type: 'string' },
      { name: 'channel_type', type: 'string' }, { name: 'target', type: 'string' }, { name: 'enabled', type: 'boolean' },
    ],
    records: [
      { subscription_id: 'SUB-001', user_id: account, venue_id: 'VENUE-001', channel_type: 'email', target: account, enabled: true },
      { subscription_id: 'SUB-002', user_id: account, channel_type: 'sms', target: '+1-555-0001', enabled: true },
      { subscription_id: 'SUB-003', user_id: account, venue_id: 'VENUE-002', channel_type: 'in_app', target: account, enabled: false },
    ],
  },
];

const pageDefinitions = [
  { title: 'Core Occupancy', pageUid: 'capstone-core-occupancy', menuUid: 'capstone-menu-core', tabUid: 'capstone-tab-core', tabName: 'capstone-tab-name-core', collections: ['venues', 'entrances', 'devices'] },
  { title: 'Access Control', pageUid: 'capstone-access-control', menuUid: 'capstone-menu-access', tabUid: 'capstone-tab-access', tabName: 'capstone-tab-name-access', collections: ['users', 'roles'] },
  { title: 'Events & Monitoring', pageUid: 'capstone-events-monitoring', menuUid: 'capstone-menu-events', tabUid: 'capstone-tab-events', tabName: 'capstone-tab-name-events', collections: ['click_events', 'occupancy_snapshots', 'alerts', 'audit_logs', 'notification_subscriptions'] },
];

function tableBlock(collection) {
  const definition = collections.find(item => item.name === collection);
  const columns = {};
  for (const field of definition?.fields || []) {
    columns[`column_${field.name}`] = {
      type: 'void',
      title: field.name,
      'x-component': 'TableV2.Column',
      properties: {
        [field.name]: {
          type: 'string',
          'x-component': 'CollectionField',
          'x-collection-field': `${collection}.${field.name}`,
        },
      },
    };
  }
  return {
    type: 'void',
    'x-decorator': 'TableBlockProvider',
    'x-use-decorator-props': 'useTableBlockDecoratorProps',
    'x-acl-action': `${collection}:list`,
    'x-decorator-props': {
      collection,
      dataSource: 'main',
      action: 'list',
      params: { pageSize: 20 },
      rowKey: 'id',
      showIndex: true,
      dragSort: false,
    },
    'x-toolbar': 'BlockSchemaToolbar',
    'x-settings': 'blockSettings:table',
    'x-component': 'CardItem',
    'x-component-props': { title: definition?.title || collection },
    properties: {
      actions: {
        type: 'void',
        'x-component': 'ActionBar',
        'x-initializer': 'table:configureActions',
        properties: {
          addNew: {
            type: 'void',
            title: '{{t("Add new")}}',
            'x-component': 'Action',
            'x-action': 'create',
            'x-align': 'right',
            'x-decorator': 'ACLActionProvider',
            'x-acl-action-props': { skipScopeCheck: true },
          },
        },
      },
      table: {
        type: 'array',
        'x-component': 'TableV2',
        'x-use-component-props': 'useTableBlockProps',
        'x-initializer': 'table:configureColumns',
        'x-component-props': { rowKey: 'id' },
        properties: columns,
      },
    },
  };
}

function pageSchema(page) {
  const rows = {};
  page.collections.forEach((collection, index) => {
    rows[`row_${index + 1}`] = {
      type: 'void',
      'x-component': 'Grid.Row',
      properties: {
        [`col_${index + 1}`]: {
          type: 'void',
          'x-component': 'Grid.Col',
          properties: { [`block_${collection}`]: tableBlock(collection) },
        },
      },
    };
  });
  return {
    type: 'void',
    'x-component': 'Page',
    'x-uid': page.pageUid,
    properties: {
      [page.tabName]: {
        type: 'void',
        'x-component': 'Grid',
        'x-initializer': 'page:addBlock',
        'x-uid': page.tabUid,
        properties: rows,
      },
    },
  };
}

async function api(path, options = {}) {
  const response = await fetch(`${baseUrl}/api/${path}`, {
    ...options,
    headers: { 'content-type': 'application/json', ...(options.headers || {}) },
  });
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!response.ok) throw new Error(`${options.method || 'GET'} ${path} failed (${response.status}): ${text}`);
  return { body, headers: response.headers };
}

async function main() {
  let login;
  let lastError;
  for (let attempt = 1; attempt <= 120; attempt += 1) {
    try {
      login = await api('auth:signIn', { method: 'POST', body: JSON.stringify({ account, password }) });
      break;
    } catch (error) {
      lastError = error;
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }
  if (!login) throw lastError;
  const cookies = login.headers.getSetCookie();
  if (!cookies.length) throw new Error('NocoBase login succeeded without a session cookie');
  const auth = {
    Cookie: cookies.map(cookie => cookie.split(';')[0]).join('; '),
    Authorization: `Bearer ${login.body.data.token}`,
  };
  const existing = (await api('collections:list?pageSize=200', { headers: auth })).body.data || [];
  for (const collection of collections) {
    if (!existing.some(item => item.name === collection.name)) {
      await api('collections:create', { method: 'POST', headers: auth, body: JSON.stringify(collection) });
    }
    const records = (await api(`${collection.name}:list?pageSize=1`, { headers: auth })).body.data || [];
    if (records.length === 0) {
      for (const record of collection.records) {
        await api(`${collection.name}:create`, { method: 'POST', headers: auth, body: JSON.stringify(record) });
      }
    }
  }

  const routes = (await api('desktopRoutes:list?pageSize=200', { headers: auth })).body.data || [];
  for (const page of pageDefinitions) {
    if (routes.some(route => route.title === page.title)) continue;
    await api('desktopRoutes:create', {
      method: 'POST',
      headers: auth,
      body: JSON.stringify({
        type: 'page',
        title: page.title,
        schemaUid: page.pageUid,
        menuSchemaUid: page.menuUid,
        enableTabs: false,
        hideInMenu: false,
        children: [{ type: 'tabs', schemaUid: page.tabUid, tabSchemaName: page.tabName, hidden: true }],
      }),
    });
    await api('uiSchemas:insert', {
      method: 'POST',
      headers: auth,
      body: JSON.stringify(pageSchema(page)),
    });
  }
  console.log('NocoBase prototype collections and sample data are ready.');
  console.log('NocoBase prototype pages and editable collection tables are ready.');
}

main().catch(error => { console.error(error); process.exit(1); });