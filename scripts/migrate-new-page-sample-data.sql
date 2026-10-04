-- Seed a small set of differentiated sample records for the new pages.
BEGIN;

DO $migration$
BEGIN
  -- Venue shown on Facility/Admin and Alerts pages.
  INSERT INTO "venues" (id, "createdAt", "updatedAt", name, address, timezone, "maxCapacity", "currentCount", status, "createdById", "updatedById")
  VALUES
    (383436853477490, NOW(), NOW(), 'Riverside Pavilion', '88 Riverfront Dr, Baltimore, MD', 'America/New_York', 320, 118, 'open', 1, 1)
  ON CONFLICT (id) DO NOTHING;

  -- New entrance and device for the facility management view.
  INSERT INTO "entrances" (id, "createdAt", "updatedAt", name, "directionType", location, active, "createdById", "updatedById", "venueId")
  VALUES
    (383436853477490, NOW(), NOW(), 'VIP Riverside Gate', 'entry', 'West concourse, Gate V', true, 1, 1, 383436853477490)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO "devices" (id, "createdAt", "updatedAt", "deviceName", "deviceType", "clientId", "lastSeenAt", "credentialsStatus", "isActive", "createdById", "updatedById", "entranceId")
  VALUES
    (383436855574590, NOW(), NOW(), 'Riverside VIP Scanner', 'tablet', 'dev-riverside-vip-01', NOW() - INTERVAL '2 minutes', 'expiring_soon', true, 1, 1, 383436853477490)
  ON CONFLICT (id) DO NOTHING;

  -- Three click events with distinct tokens for Visitor Event Entry.
  INSERT INTO "clickEvents" (id, "createdAt", "updatedAt", "eventType", delta, "occurredAt", "receivedAt", "idempotencyToken", processed, metadata, "createdById", "updatedById", "deviceId", "entranceId", "operatorId")
  VALUES
    (383436855574590, NOW(), NOW(), 'entry', 1, NOW() - INTERVAL '9 minutes', NOW() - INTERVAL '9 minutes', 'evt-riverside-3001', true, '{"source":"visitor-entry","lane":"vip"}'::json, 1, 1, 383436855574590, 383436853477490, 1),
    (383436855574591, NOW(), NOW(), 'exit', -1, NOW() - INTERVAL '6 minutes', NOW() - INTERVAL '6 minutes', 'evt-riverside-3002', true, '{"source":"visitor-entry","lane":"vip"}'::json, 1, 1, 383436855574590, 383436853477490, 1),
    (383436855574592, NOW(), NOW(), 'correction', 2, NOW() - INTERVAL '3 minutes', NOW() - INTERVAL '3 minutes', 'evt-riverside-3003', false, '{"source":"manual-correction","reason":"group late scan"}'::json, 1, 1, 383436855574590, 383436853477490, 1)
  ON CONFLICT (id) DO NOTHING;

  -- Alert and subscriptions for Alerts/Audit page.
  INSERT INTO "alerts" (id, "createdAt", "updatedAt", "alertType", status, "triggeredAt", message, metadata, "createdById", "updatedById", "venueId")
  VALUES
    (383436857671790, NOW(), NOW(), 'device_offline', 'acknowledged', NOW() - INTERVAL '4 minutes', 'Riverside VIP Scanner heartbeat delayed for 95 seconds.', '{"device":"Riverside VIP Scanner","severity":"medium"}'::json, 1, 1, 383436853477490)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO "notificationSubscriptions" (id, "createdAt", "updatedAt", channel, target, enabled, "createdById", "updatedById", "userId", "venueId")
  VALUES
    (383436857671790, NOW(), NOW(), 'email', 'ops-riverside@nocobase.demo', true, 1, 1, 1, 383436853477490),
    (383436857671791, NOW(), NOW(), 'slack', '#ops-riverside-live', true, 1, 1, 1, 383436853477490)
  ON CONFLICT (id) DO NOTHING;

  -- Audit entries that tie to the new alert/device activity.
  INSERT INTO "auditLogs" (id, "createdAt", "updatedAt", "actionType", "entityType", "entityId", details, "occurredAt", "createdById", "updatedById", "actorId")
  VALUES
    (383436857671790, NOW(), NOW(), 'alert_acknowledged', 'alerts', '383436857671790', '{"note":"acknowledged by venue manager","channel":"email"}'::json, NOW() - INTERVAL '2 minutes', 1, 1, 1),
    (383436857671791, NOW(), NOW(), 'device_status_reviewed', 'devices', '383436855574590', '{"status":"expiring_soon","followUp":"replace credential this shift"}'::json, NOW() - INTERVAL '1 minute', 1, 1, 1)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'New-page sample data migration applied.';
END;
$migration$;

COMMIT;
