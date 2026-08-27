#!/usr/bin/env bash

set -euo pipefail

base_url="${NOCOBASE_URL:-http://127.0.0.1:13001}"
admin_email="${NOCOBASE_ADMIN_EMAIL:-admin@nocobase.local}"
admin_password="${NOCOBASE_ADMIN_PASSWORD:-admin123}"

auth_payload=$(jq -nc \
  --arg account "$admin_email" \
  --arg password "$admin_password" \
  '{account: $account, password: $password}')

auth_response=$(curl -sS --fail-with-body \
  -X POST "$base_url/api/auth:signIn" \
  -H 'Content-Type: application/json' \
  --data "$auth_payload")

token=$(jq -r '.data.token // empty' <<<"$auth_response")
admin_id=$(jq -r '.data.user.id // empty' <<<"$auth_response")

if [[ -z "$token" ]]; then
  printf 'Could not sign in to NocoBase at %s.\n' "$base_url" >&2
  exit 1
fi

api_post() {
  local endpoint=$1
  local payload=$2
  local response

  response=$(curl -sS --fail-with-body \
    -X POST "$base_url/api/$endpoint" \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    --data "$payload")

  if jq -e '.errors and (.errors | length > 0)' >/dev/null <<<"$response"; then
    jq '.errors' <<<"$response" >&2
    return 1
  fi

  printf '%s' "$response"
}

apply_collection() {
  local payload=$1
  local title
  title=$(jq -r '.title' <<<"$payload")
  api_post 'collections:apply' "$payload" >/dev/null
  printf 'Configured %s\n' "$title"
}

apply_field() {
  local payload=$1
  local collection_name
  local field_name
  local existing_field

  collection_name=$(jq -r '.collectionName' <<<"$payload")
  field_name=$(jq -r '.name' <<<"$payload")
  existing_field=$(curl -sS --fail-with-body \
    "$base_url/api/collections/$collection_name/fields:get?filterByTk=$field_name" \
    -H "Authorization: Bearer $token" | jq -r '.data.name // empty')

  if [[ "$existing_field" == "$field_name" ]]; then
    return 0
  fi

  api_post 'fields:apply' "$payload" >/dev/null
}

create_record() {
  local collection=$1
  local payload=$2
  api_post "$collection:create" "$payload" | jq -r '.data.id'
}

apply_collection '{
  "name": "venues",
  "title": "Venues",
  "description": "Buildings monitored by the occupancy system.",
  "template": "general",
  "settings": {"titleField": "name"},
  "fields": [
    {"name": "name", "title": "Venue name", "interface": "input", "validators": ["required"]},
    {"name": "address", "title": "Address", "interface": "input"},
    {"name": "timezone", "title": "Time zone", "interface": "input", "defaultValue": "America/New_York"},
    {"name": "maxCapacity", "title": "Maximum capacity", "interface": "integer", "validators": ["required"]},
    {"name": "currentCount", "title": "Current occupancy", "interface": "integer", "defaultValue": 0},
    {"name": "status", "title": "Status", "interface": "select", "defaultValue": "open", "enum": [
      {"label": "Open", "value": "open", "color": "green"},
      {"label": "Closed", "value": "closed", "color": "default"},
      {"label": "Emergency", "value": "emergency", "color": "red"}
    ]}
  ]
}'

apply_collection '{
  "name": "entrances",
  "title": "Entrances",
  "description": "Monitored entrances and exits at each venue.",
  "template": "general",
  "settings": {"titleField": "name"},
  "fields": [
    {"name": "name", "title": "Entrance name", "interface": "input", "validators": ["required"]},
    {"name": "directionType", "title": "Direction", "interface": "select", "enum": [
      {"label": "Entrance", "value": "in", "color": "green"},
      {"label": "Exit", "value": "out", "color": "blue"},
      {"label": "Both", "value": "both", "color": "purple"}
    ]},
    {"name": "location", "title": "Location", "interface": "input"},
    {"name": "active", "title": "Active", "interface": "checkbox", "defaultValue": true}
  ]
}'

apply_collection '{
  "name": "devices",
  "title": "Devices",
  "description": "Clicker devices assigned to venue entrances.",
  "template": "general",
  "settings": {"titleField": "deviceName"},
  "fields": [
    {"name": "deviceName", "title": "Device name", "interface": "input", "validators": ["required"]},
    {"name": "deviceType", "title": "Device type", "interface": "select", "enum": [
      {"label": "Tablet", "value": "tablet", "color": "blue"},
      {"label": "Kiosk", "value": "kiosk", "color": "purple"},
      {"label": "Handheld", "value": "handheld", "color": "gold"}
    ]},
    {"name": "clientId", "title": "Client ID", "interface": "input", "settings": {"unique": true}},
    {"name": "lastSeenAt", "title": "Last seen", "interface": "datetime"},
    {"name": "credentialsStatus", "title": "Credentials", "interface": "select", "defaultValue": "valid", "enum": [
      {"label": "Valid", "value": "valid", "color": "green"},
      {"label": "Expiring", "value": "expiring", "color": "gold"},
      {"label": "Revoked", "value": "revoked", "color": "red"}
    ]},
    {"name": "isActive", "title": "Active", "interface": "checkbox", "defaultValue": true}
  ]
}'

apply_collection '{
  "name": "clickEvents",
  "title": "Click events",
  "description": "Raw entry and exit events received from clicker devices.",
  "template": "general",
  "fields": [
    {"name": "eventType", "title": "Event type", "interface": "select", "enum": [
      {"label": "Entry", "value": "entry", "color": "green"},
      {"label": "Exit", "value": "exit", "color": "blue"},
      {"label": "Correction", "value": "correction", "color": "gold"}
    ]},
    {"name": "delta", "title": "Occupancy change", "interface": "integer", "validators": ["required"]},
    {"name": "occurredAt", "title": "Occurred at", "interface": "datetime", "validators": ["required"]},
    {"name": "receivedAt", "title": "Received at", "interface": "datetime"},
    {"name": "idempotencyToken", "title": "Idempotency token", "interface": "input", "settings": {"unique": true}},
    {"name": "processed", "title": "Processed", "interface": "checkbox", "defaultValue": true},
    {"name": "metadata", "title": "Metadata", "interface": "json"}
  ]
}'

apply_collection '{
  "name": "occupancySnapshots",
  "title": "Occupancy snapshots",
  "description": "Saved occupancy totals used for trend reporting.",
  "template": "general",
  "fields": [
    {"name": "count", "title": "Occupancy", "interface": "integer", "validators": ["required"]},
    {"name": "source", "title": "Source", "interface": "select", "enum": [
      {"label": "Click event", "value": "click_event", "color": "blue"},
      {"label": "Manual", "value": "manual", "color": "gold"},
      {"label": "Reconciliation", "value": "reconciliation", "color": "purple"}
    ]},
    {"name": "recordedAt", "title": "Recorded at", "interface": "datetime", "validators": ["required"]}
  ]
}'

apply_collection '{
  "name": "alerts",
  "title": "Alerts",
  "description": "Capacity, device, and data-quality warnings for operators.",
  "template": "general",
  "fields": [
    {"name": "alertType", "title": "Alert type", "interface": "select", "enum": [
      {"label": "Near capacity", "value": "near_capacity", "color": "gold"},
      {"label": "At capacity", "value": "at_capacity", "color": "red"},
      {"label": "Device offline", "value": "device_offline", "color": "volcano"},
      {"label": "Count mismatch", "value": "count_mismatch", "color": "purple"}
    ]},
    {"name": "status", "title": "Status", "interface": "select", "defaultValue": "open", "enum": [
      {"label": "Open", "value": "open", "color": "red"},
      {"label": "Acknowledged", "value": "acknowledged", "color": "gold"},
      {"label": "Resolved", "value": "resolved", "color": "green"}
    ]},
    {"name": "triggeredAt", "title": "Triggered at", "interface": "datetime", "validators": ["required"]},
    {"name": "resolvedAt", "title": "Resolved at", "interface": "datetime"},
    {"name": "message", "title": "Message", "interface": "textarea"},
    {"name": "metadata", "title": "Metadata", "interface": "json"}
  ]
}'

apply_collection '{
  "name": "notificationSubscriptions",
  "title": "Notification subscriptions",
  "description": "Where operators receive venue alerts.",
  "template": "general",
  "fields": [
    {"name": "channel", "title": "Channel", "interface": "select", "enum": [
      {"label": "Email", "value": "email", "color": "blue"},
      {"label": "SMS", "value": "sms", "color": "green"},
      {"label": "Teams", "value": "teams", "color": "purple"}
    ]},
    {"name": "target", "title": "Destination", "interface": "input", "validators": ["required"]},
    {"name": "enabled", "title": "Enabled", "interface": "checkbox", "defaultValue": true}
  ]
}'

apply_collection '{
  "name": "auditLogs",
  "title": "Audit log",
  "description": "Administrative and operational actions recorded for review.",
  "template": "general",
  "fields": [
    {"name": "actionType", "title": "Action", "interface": "select", "enum": [
      {"label": "Create", "value": "create", "color": "green"},
      {"label": "Update", "value": "update", "color": "blue"},
      {"label": "Resolve", "value": "resolve", "color": "purple"},
      {"label": "Manual correction", "value": "manual_correction", "color": "gold"}
    ]},
    {"name": "entityType", "title": "Entity type", "interface": "input"},
    {"name": "entityId", "title": "Entity ID", "interface": "input"},
    {"name": "details", "title": "Details", "interface": "json"},
    {"name": "occurredAt", "title": "Occurred at", "interface": "datetime", "validators": ["required"]}
  ]
}'

apply_field '{"collectionName":"entrances","name":"venue","title":"Venue","interface":"m2o","target":"venues","reverseName":"entrances","reverseTitle":"Entrances","reverseInterface":"o2m"}'
apply_field '{"collectionName":"devices","name":"entrance","title":"Entrance","interface":"m2o","target":"entrances","reverseName":"devices","reverseTitle":"Devices","reverseInterface":"o2m"}'
apply_field '{"collectionName":"clickEvents","name":"device","title":"Device","interface":"m2o","target":"devices","reverseName":"clickEvents","reverseTitle":"Click events","reverseInterface":"o2m"}'
apply_field '{"collectionName":"clickEvents","name":"entrance","title":"Entrance","interface":"m2o","target":"entrances","reverseName":"entranceEvents","reverseTitle":"Click events","reverseInterface":"o2m"}'
apply_field '{"collectionName":"clickEvents","name":"operator","title":"Operator","interface":"m2o","target":"users","reverseName":"recordedClickEvents","reverseTitle":"Recorded click events","reverseInterface":"o2m"}'
apply_field '{"collectionName":"occupancySnapshots","name":"venue","title":"Venue","interface":"m2o","target":"venues","reverseName":"occupancySnapshots","reverseTitle":"Occupancy snapshots","reverseInterface":"o2m"}'
apply_field '{"collectionName":"alerts","name":"venue","title":"Venue","interface":"m2o","target":"venues","reverseName":"alerts","reverseTitle":"Alerts","reverseInterface":"o2m"}'
apply_field '{"collectionName":"alerts","name":"resolvedBy","title":"Resolved by","interface":"m2o","target":"users","reverseName":"resolvedAlerts","reverseTitle":"Resolved alerts","reverseInterface":"o2m"}'
apply_field '{"collectionName":"notificationSubscriptions","name":"user","title":"User","interface":"m2o","target":"users","reverseName":"notificationSubscriptions","reverseTitle":"Notification subscriptions","reverseInterface":"o2m"}'
apply_field '{"collectionName":"notificationSubscriptions","name":"venue","title":"Venue","interface":"m2o","target":"venues","reverseName":"notificationSubscriptions","reverseTitle":"Notification subscriptions","reverseInterface":"o2m"}'
apply_field '{"collectionName":"auditLogs","name":"actor","title":"Actor","interface":"m2o","target":"users","reverseName":"auditLogs","reverseTitle":"Audit log entries","reverseInterface":"o2m"}'

printf 'Configured collection relationships\n'

venue_count=$(curl -sS --fail-with-body \
  "$base_url/api/venues:list?pageSize=1" \
  -H "Authorization: Bearer $token" | jq -r '.meta.count // 0')

if [[ "$venue_count" != "0" ]]; then
  printf 'Sample data already exists; nothing was added.\n'
  exit 0
fi

harbor_id=$(create_record venues '{"name":"Harbor Center","address":"120 Harbor Avenue, Baltimore, MD","timezone":"America/New_York","maxCapacity":500,"currentCount":412,"status":"open"}')
fieldhouse_id=$(create_record venues '{"name":"Eastside Fieldhouse","address":"44 Green Street, Baltimore, MD","timezone":"America/New_York","maxCapacity":800,"currentCount":267,"status":"open"}')

north_gate_id=$(create_record entrances "{\"venueId\":\"$harbor_id\",\"name\":\"North Gate\",\"directionType\":\"in\",\"location\":\"Main plaza\",\"active\":true}")
south_exit_id=$(create_record entrances "{\"venueId\":\"$harbor_id\",\"name\":\"South Exit\",\"directionType\":\"out\",\"location\":\"Parking deck\",\"active\":true}")
east_lobby_id=$(create_record entrances "{\"venueId\":\"$fieldhouse_id\",\"name\":\"East Lobby\",\"directionType\":\"both\",\"location\":\"Green Street\",\"active\":true}")
service_gate_id=$(create_record entrances "{\"venueId\":\"$fieldhouse_id\",\"name\":\"Service Gate\",\"directionType\":\"both\",\"location\":\"Loading area\",\"active\":false}")

north_device_id=$(create_record devices "{\"entranceId\":\"$north_gate_id\",\"deviceName\":\"North Gate Tablet\",\"deviceType\":\"tablet\",\"clientId\":\"HBC-NORTH-01\",\"lastSeenAt\":\"2026-08-27T15:42:00-04:00\",\"credentialsStatus\":\"valid\",\"isActive\":true}")
south_device_id=$(create_record devices "{\"entranceId\":\"$south_exit_id\",\"deviceName\":\"South Exit Kiosk\",\"deviceType\":\"kiosk\",\"clientId\":\"HBC-SOUTH-01\",\"lastSeenAt\":\"2026-08-27T15:40:00-04:00\",\"credentialsStatus\":\"valid\",\"isActive\":true}")
east_device_id=$(create_record devices "{\"entranceId\":\"$east_lobby_id\",\"deviceName\":\"East Lobby Tablet\",\"deviceType\":\"tablet\",\"clientId\":\"ESF-EAST-01\",\"lastSeenAt\":\"2026-08-27T15:41:00-04:00\",\"credentialsStatus\":\"expiring\",\"isActive\":true}")
service_device_id=$(create_record devices "{\"entranceId\":\"$service_gate_id\",\"deviceName\":\"Service Gate Handheld\",\"deviceType\":\"handheld\",\"clientId\":\"ESF-SERVICE-01\",\"lastSeenAt\":\"2026-08-27T13:05:00-04:00\",\"credentialsStatus\":\"revoked\",\"isActive\":false}")

create_record clickEvents "{\"deviceId\":\"$north_device_id\",\"entranceId\":\"$north_gate_id\",\"operatorId\":\"$admin_id\",\"eventType\":\"entry\",\"delta\":1,\"occurredAt\":\"2026-08-27T15:36:04-04:00\",\"receivedAt\":\"2026-08-27T15:36:05-04:00\",\"idempotencyToken\":\"evt-hbc-1001\",\"processed\":true,\"metadata\":{\"source\":\"clicker\"}}" >/dev/null
create_record clickEvents "{\"deviceId\":\"$north_device_id\",\"entranceId\":\"$north_gate_id\",\"operatorId\":\"$admin_id\",\"eventType\":\"entry\",\"delta\":1,\"occurredAt\":\"2026-08-27T15:37:18-04:00\",\"receivedAt\":\"2026-08-27T15:37:18-04:00\",\"idempotencyToken\":\"evt-hbc-1002\",\"processed\":true,\"metadata\":{\"source\":\"clicker\"}}" >/dev/null
create_record clickEvents "{\"deviceId\":\"$south_device_id\",\"entranceId\":\"$south_exit_id\",\"operatorId\":\"$admin_id\",\"eventType\":\"exit\",\"delta\":-1,\"occurredAt\":\"2026-08-27T15:38:43-04:00\",\"receivedAt\":\"2026-08-27T15:38:44-04:00\",\"idempotencyToken\":\"evt-hbc-1003\",\"processed\":true,\"metadata\":{\"source\":\"clicker\"}}" >/dev/null
create_record clickEvents "{\"deviceId\":\"$east_device_id\",\"entranceId\":\"$east_lobby_id\",\"operatorId\":\"$admin_id\",\"eventType\":\"entry\",\"delta\":1,\"occurredAt\":\"2026-08-27T15:39:12-04:00\",\"receivedAt\":\"2026-08-27T15:39:13-04:00\",\"idempotencyToken\":\"evt-esf-2001\",\"processed\":true,\"metadata\":{\"source\":\"clicker\"}}" >/dev/null
create_record clickEvents "{\"deviceId\":\"$east_device_id\",\"entranceId\":\"$east_lobby_id\",\"operatorId\":\"$admin_id\",\"eventType\":\"correction\",\"delta\":-2,\"occurredAt\":\"2026-08-27T15:40:00-04:00\",\"receivedAt\":\"2026-08-27T15:40:00-04:00\",\"idempotencyToken\":\"evt-esf-2002\",\"processed\":true,\"metadata\":{\"reason\":\"turnstile recount\"}}" >/dev/null

create_record occupancySnapshots "{\"venueId\":\"$harbor_id\",\"count\":398,\"source\":\"click_event\",\"recordedAt\":\"2026-08-27T15:00:00-04:00\"}" >/dev/null
create_record occupancySnapshots "{\"venueId\":\"$harbor_id\",\"count\":412,\"source\":\"click_event\",\"recordedAt\":\"2026-08-27T15:45:00-04:00\"}" >/dev/null
create_record occupancySnapshots "{\"venueId\":\"$fieldhouse_id\",\"count\":251,\"source\":\"click_event\",\"recordedAt\":\"2026-08-27T15:00:00-04:00\"}" >/dev/null
create_record occupancySnapshots "{\"venueId\":\"$fieldhouse_id\",\"count\":267,\"source\":\"reconciliation\",\"recordedAt\":\"2026-08-27T15:45:00-04:00\"}" >/dev/null

create_record alerts "{\"venueId\":\"$harbor_id\",\"alertType\":\"near_capacity\",\"status\":\"open\",\"triggeredAt\":\"2026-08-27T15:32:00-04:00\",\"message\":\"Harbor Center has reached 82% of capacity.\",\"metadata\":{\"threshold\":80,\"occupancy\":412}}" >/dev/null
create_record alerts "{\"venueId\":\"$fieldhouse_id\",\"alertType\":\"device_offline\",\"status\":\"acknowledged\",\"triggeredAt\":\"2026-08-27T13:10:00-04:00\",\"message\":\"Service Gate Handheld has not checked in for two hours.\",\"metadata\":{\"deviceId\":\"$service_device_id\"}}" >/dev/null
create_record alerts "{\"venueId\":\"$fieldhouse_id\",\"resolvedById\":\"$admin_id\",\"alertType\":\"count_mismatch\",\"status\":\"resolved\",\"triggeredAt\":\"2026-08-27T14:20:00-04:00\",\"resolvedAt\":\"2026-08-27T14:34:00-04:00\",\"message\":\"Manual floor count differed from the clicker total by two.\",\"metadata\":{\"difference\":2}}" >/dev/null

create_record notificationSubscriptions "{\"userId\":\"$admin_id\",\"venueId\":\"$harbor_id\",\"channel\":\"email\",\"target\":\"operations@nocobase.local\",\"enabled\":true}" >/dev/null
create_record notificationSubscriptions "{\"userId\":\"$admin_id\",\"venueId\":\"$fieldhouse_id\",\"channel\":\"teams\",\"target\":\"Operations channel\",\"enabled\":true}" >/dev/null

create_record auditLogs "{\"actorId\":\"$admin_id\",\"actionType\":\"create\",\"entityType\":\"venue\",\"entityId\":\"$harbor_id\",\"details\":{\"field\":\"status\",\"value\":\"open\"},\"occurredAt\":\"2026-08-27T12:00:00-04:00\"}" >/dev/null
create_record auditLogs "{\"actorId\":\"$admin_id\",\"actionType\":\"update\",\"entityType\":\"device\",\"entityId\":\"$east_device_id\",\"details\":{\"field\":\"credentialsStatus\",\"value\":\"expiring\"},\"occurredAt\":\"2026-08-27T13:00:00-04:00\"}" >/dev/null
create_record auditLogs "{\"actorId\":\"$admin_id\",\"actionType\":\"manual_correction\",\"entityType\":\"venue\",\"entityId\":\"$fieldhouse_id\",\"details\":{\"delta\":-2,\"reason\":\"turnstile recount\"},\"occurredAt\":\"2026-08-27T15:40:00-04:00\"}" >/dev/null

printf 'Added sample venues, entrances, devices, events, snapshots, alerts, subscriptions, and audit records.\n'
