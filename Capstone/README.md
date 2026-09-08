# Venue Occupancy Management System — NocoBase Prototype

This project provides a Docker Compose setup for deploying NocoBase, an open-source no-code/low-code platform. Use it to build a Venue Occupancy Management System that tracks occupancy across venues with real-time monitoring, access control, and alerts.

## System Overview

This system manages:
- Venues: Buildings, halls, and rooms with capacity limits
- Entrances & Devices: Entry points with sensors/cameras tracking movement
- Users & Access Control: Admin and staff roles with granular permissions
- Events & Alerts: Device events and automated alerts when capacity is exceeded
- Audit Logs: Complete record of all system activities

## Prerequisites

Install the following:
- Docker Desktop (Windows/macOS) or Docker Engine (Linux) with Docker Compose v2
  - Windows: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
  - macOS: https://desktop.docker.com/mac/main/amd64/Docker.dmg
  - Linux: https://docs.docker.com/engine/install/
- Web browser (Chrome, Firefox, Safari, or Edge)

## Understanding Bind Mounts

Bind mounts connect local directories on your computer to directories inside Docker containers. Any changes made in NocoBase are saved locally and persist even if containers are removed.

This setup uses:
- `./data/nocobase-storage` - Stores NocoBase configuration and files
- `./data/postgres-data` - Stores database records

Without bind mounts, all data is lost when containers are deleted.

## Setup Instructions

### Step 1: Create Data Directories

Navigate to the project directory and create folders for persistent data storage:

```bash
# On Windows (PowerShell)
cd "C:\Users\YourUsername\OneDrive\Documents\GitHub\capstone-deliverable1-nocobase\Capstone"
mkdir -p data/nocobase-storage
mkdir -p data/postgres-data

# On macOS/Linux
cd ~/OneDrive/Documents/GitHub/capstone-deliverable1-nocobase/Capstone
mkdir -p data/nocobase-storage
mkdir -p data/postgres-data
```

### Step 2: Start Services

In the project directory, run:

```bash
docker compose up -d
```

This downloads the required images (first run takes 5-10 minutes) and starts two containers: NocoBase application and PostgreSQL database. The `-d` flag runs containers in the background.

### Step 3: Verify Services Are Running

Check container status:

```bash
docker compose ps
```

Both containers should show status "Up". Monitor startup logs to verify NocoBase has initialized:

```bash
docker compose logs -f nocobase-app
```

Look for confirmation that the application has started successfully. Press Ctrl+C to exit logs.

### Step 4: Access NocoBase

Open a web browser and navigate to:

```
http://localhost:13000
```

Log in with default credentials:
- Email: admin@nocobase.com
- Password: admin123

IMPORTANT: Change this password immediately after first login via the user profile settings.

## Initial Page Setup

On the first login, create these three pages in the NocoBase desktop. These pages are the main sections of the prototype. Page configuration is stored in the bind-mounted application storage, so it remains available after restarting Docker.

1. Open the page or desktop settings from the left navigation.
2. Create a page named `Core Occupancy`.
3. Create a page named `Access Control`.
4. Create a page named `Events & Monitoring`.
5. Set `Core Occupancy` as the home page.
6. Save the desktop/navigation configuration.

Add the following collections to each page using a table or grid block:

| Page | Collections |
|------|-------------|
| Core Occupancy | Venues, Entrances, Devices |
| Access Control | Users, Roles, Permissions, RolePermission |
| Events & Monitoring | ClickEvent, OccupancySnapshot, Alerts, AuditLog, NotificationSubscription |

If the page editor uses the terms `desktop`, `menu`, or `schema` instead of `page`, use the equivalent option for creating a navigation item and assign the same names above. Create the collections in the order listed in the prototype section so linked-record fields can reference tables that already exist.

## Building the Prototype

Complete step-by-step instructions for creating all 12 database tables.

### General Steps for Creating Any Table

1. Click "+" in left sidebar or click "Create New"
2. Select "Create Collection"
3. Enter table name
4. Click Create
5. Add fields using the "+" icon in column header
6. Configure field properties (primary key, required, defaults)
7. Add sample data by clicking "+" to add new records

### Table Creation Sequence

Create tables in this order:

1. Venues
2. Entrances
3. Devices
4. Roles
5. Permissions
6. RolePermission
7. Users
8. ClickEvent
9. OccupancySnapshot
10. Alerts
11. AuditLog
12. NotificationSubscription

### Phase 1: Core Occupancy Tables

#### Table 1: Venues

| Field | Type | Settings |
|-------|------|----------|
| venue_id | Text | Primary Key |
| name | Text | Required |
| timezone | Text | Optional |
| max_capacity | Number | Optional |
| current_count | Number | Default: 0 |
| created_at | DateTime | Auto-set on create |
| updated_at | DateTime | Auto-set on update |

Sample Data:
- venue_id: VENUE-001, name: Main Conference Hall, max_capacity: 500
- venue_id: VENUE-002, name: East Wing Meeting Room, max_capacity: 50
- venue_id: VENUE-003, name: Auditorium, max_capacity: 1000

#### Table 2: Entrances

| Field | Type | Settings |
|-------|------|----------|
| entrance_id | Text | Primary Key |
| venue_id | Link Records | Link to Venues |
| name | Text | Required |
| direction_type | Text | Optional (entry/exit/bidirectional) |
| location | Text | Optional |
| status | Text | Optional (active/inactive/maintenance) |

Sample Data:
- entrance_id: ENT-001, venue_id: VENUE-001, name: Front Door, direction_type: entry
- entrance_id: ENT-002, venue_id: VENUE-001, name: Emergency Exit, direction_type: exit
- entrance_id: ENT-003, venue_id: VENUE-002, name: Main Entry, direction_type: bidirectional

#### Table 3: Devices

| Field | Type | Settings |
|-------|------|----------|
| device_id | Text | Primary Key |
| entrance_id | Link Records | Link to Entrances |
| name | Text | Required |
| device_type | Text | Optional (camera/motion_sensor/etc) |
| client_id | Text | Optional |
| serial | Text | Optional |
| last_seen | DateTime | Optional |
| credentials | Text | Optional (Long Text) |

Sample Data:
- device_id: DEV-001, entrance_id: ENT-001, name: Front Door Camera, device_type: camera
- device_id: DEV-002, entrance_id: ENT-002, name: Emergency Exit Motion Sensor, device_type: motion_sensor
- device_id: DEV-003, entrance_id: ENT-003, name: Meeting Room Entry Camera, device_type: camera

### Phase 2: Access Control

#### Table 4: Roles

| Field | Type | Settings |
|-------|------|----------|
| role_id | Text | Primary Key |
| name | Text | Required |

Sample Data:
- role_id: ROLE-001, name: Admin
- role_id: ROLE-002, name: Manager
- role_id: ROLE-003, name: Monitor
- role_id: ROLE-004, name: Guest

#### Table 5: Permissions

| Field | Type | Settings |
|-------|------|----------|
| permission_id | Text | Primary Key |
| name | Text | Required |

Sample Data:
- permission_id: PERM-001, name: view_venues
- permission_id: PERM-002, name: edit_venues
- permission_id: PERM-003, name: delete_venues
- permission_id: PERM-004, name: view_reports
- permission_id: PERM-005, name: manage_users
- permission_id: PERM-006, name: manage_alerts

#### Table 6: RolePermission

Junction table linking roles to permissions.

| Field | Type | Settings |
|-------|------|----------|
| role_permission_id | Text | Primary Key |
| role_id | Link Records | Link to Roles |
| permission_id | Link Records | Link to Permissions |

Sample Data (link Admin to all permissions):
- role_permission_id: RP-001, role_id: ROLE-001, permission_id: PERM-001
- role_permission_id: RP-002, role_id: ROLE-001, permission_id: PERM-002
- role_permission_id: RP-003, role_id: ROLE-001, permission_id: PERM-003
- role_permission_id: RP-004, role_id: ROLE-001, permission_id: PERM-004
- role_permission_id: RP-005, role_id: ROLE-001, permission_id: PERM-005
- role_permission_id: RP-006, role_id: ROLE-001, permission_id: PERM-006

#### Table 7: Users

| Field | Type | Settings |
|-------|------|----------|
| user_id | Text | Primary Key |
| email | Email | Required, unique |
| username | Text | Required |
| display_name | Text | Optional |
| password | Text | Required (Long Text) |
| phone | Text | Optional |
| roles | Link Records | Link to Roles (allow multiple) |
| created_at | DateTime | Auto-set on create |
| last_login | DateTime | Optional |

Sample Data:
- user_id: USER-001, email: admin@venue.com, username: admin, display_name: Administrator, roles: ROLE-001
- user_id: USER-002, email: manager@venue.com, username: manager, display_name: Sarah Manager, roles: ROLE-002
- user_id: USER-003, email: monitor@venue.com, username: monitor, display_name: John Monitor, roles: ROLE-003
- user_id: USER-004, email: guest@venue.com, username: guest, display_name: Guest User, roles: ROLE-004

### Phase 3: Events & Monitoring

#### Table 8: ClickEvent

| Field | Type | Settings |
|-------|------|----------|
| click_id | Text | Primary Key |
| device_id | Link Records | Link to Devices |
| entrance_id | Link Records | Link to Entrances |
| user_id | Link Records | Link to Users (optional) |
| event_type | Text | Optional (motion_detected/person_entered/etc) |
| direction | Text | Optional (entry/exit/unknown) |
| timestamp | DateTime | Required |
| processed_flag | Checkbox | Default: unchecked |
| metadata | Text | Optional (Long Text for JSON) |

Sample Data:
- click_id: CLICK-001, device_id: DEV-001, entrance_id: ENT-001, event_type: person_entered, direction: entry
- click_id: CLICK-002, device_id: DEV-001, entrance_id: ENT-001, event_type: person_entered, direction: entry
- click_id: CLICK-003, device_id: DEV-002, entrance_id: ENT-002, event_type: motion_detected, direction: exit

#### Table 9: OccupancySnapshot

| Field | Type | Settings |
|-------|------|----------|
| snapshot_id | Text | Primary Key |
| venue_id | Link Records | Link to Venues |
| count | Number | Current occupancy |
| source | Text | Optional (device_count/manual_entry) |
| created_at | DateTime | When snapshot taken |

Sample Data:
- snapshot_id: SNAP-001, venue_id: VENUE-001, count: 125, source: device_count
- snapshot_id: SNAP-002, venue_id: VENUE-001, count: 150, source: device_count
- snapshot_id: SNAP-003, venue_id: VENUE-001, count: 175, source: device_count
- snapshot_id: SNAP-004, venue_id: VENUE-002, count: 8, source: device_count

#### Table 10: Alerts

| Field | Type | Settings |
|-------|------|----------|
| alert_id | Text | Primary Key |
| venue_id | Link Records | Link to Venues |
| created_by_user_id | Link Records | Link to Users |
| alert_type | Text | Optional (capacity_exceeded/device_offline/anomaly) |
| triggered_at | DateTime | When alert triggered |
| resolved_at | DateTime | Optional, when resolved |
| message | Text | Alert description |
| metadata | Text | Optional (Long Text) |

Sample Data:
- alert_id: ALERT-001, venue_id: VENUE-001, created_by_user_id: USER-001, alert_type: capacity_exceeded, message: Main Conference Hall exceeded 90% capacity
- alert_id: ALERT-002, venue_id: VENUE-002, created_by_user_id: USER-002, alert_type: device_offline, message: Camera DEV-003 went offline
- alert_id: ALERT-003, venue_id: VENUE-001, created_by_user_id: USER-002, alert_type: anomaly, message: Unusual occupancy spike detected

#### Table 11: AuditLog

| Field | Type | Settings |
|-------|------|----------|
| audit_id | Text | Primary Key |
| actor_user_id | Link Records | Link to Users |
| entity_type | Text | What was changed (venue/user/alert) |
| entity_id | Text | ID of what changed |
| details | Text | Description of change |
| created_at | DateTime | When action occurred |

Sample Data:
- audit_id: AUDIT-001, actor_user_id: USER-001, entity_type: venue, entity_id: VENUE-001, details: Updated max_capacity from 400 to 500
- audit_id: AUDIT-002, actor_user_id: USER-001, entity_type: user, entity_id: USER-002, details: Created new user manager@venue.com
- audit_id: AUDIT-003, actor_user_id: USER-002, entity_type: alert, entity_id: ALERT-001, details: Marked alert as resolved

#### Table 12: NotificationSubscription

| Field | Type | Settings |
|-------|------|----------|
| subscription_id | Text | Primary Key |
| user_id | Link Records | Link to Users |
| venue_id | Link Records | Link to Venues (optional) |
| channel_type | Text | How to notify (email/sms/in_app/slack) |
| target | Text | Destination (email address, phone, etc) |
| enabled | Checkbox | Subscription active |

Sample Data:
- subscription_id: SUB-001, user_id: USER-002, venue_id: VENUE-001, channel_type: email, target: manager@venue.com, enabled: checked
- subscription_id: SUB-002, user_id: USER-001, venue_id: null, channel_type: sms, target: +1-555-0001, enabled: checked
- subscription_id: SUB-003, user_id: USER-003, venue_id: VENUE-002, channel_type: in_app, target: monitor@venue.com, enabled: unchecked

### Phase 4: Views and Filters

For each table:
1. Click the table in left sidebar
2. Click the dropdown next to table name
3. Select "New View"
4. Choose view type (Grid, List, Form, Gallery)
5. Name the view
6. Save

Suggested views:

For Alerts:
- Active Alerts: Filter resolved_at is empty
- Resolved Alerts: Filter resolved_at is not empty

For Users:
- Admins: Filter roles contains Admin
- Active Users: Filter last_login is not empty

For Venues:
- Near Capacity: Filter current_count > max_capacity * 0.8

For ClickEvents:
- Unprocessed: Filter processed_flag = false
- Today's Entries: Filter direction = entry AND date(timestamp) = today

### Testing

1. Create new records in each table
2. Link related records (create alert for venue)
3. Edit existing records
4. Use filters to view subsets of data
5. Sort records by different fields
6. Verify data persists after container restart

## Command Reference

| Task | Command |
|------|---------|
| Start services | `docker compose up -d` |
| Stop services (preserves data) | `docker compose down` |
| Check container status | `docker compose ps` |
| View application logs | `docker compose logs -f nocobase-app` |
| View database logs | `docker compose logs -f nocobase-db` |
| Restart services | `docker compose restart` |
| Remove everything (deletes data) | `docker compose down -v` |

All commands must be run from the directory containing compose.yml.

## Troubleshooting

Port 13000 already in use: Edit compose.yml and change "13000:80" to "13001:80", then visit http://localhost:13001

Database connection error: Database may still be initializing. Wait 30 seconds, refresh the page, or check logs with `docker compose logs nocobase-db`

Permission denied errors (macOS/Linux): Run `sudo usermod -aG docker $USER`

Data loss after running docker compose down -v: The -v flag removes all volumes including your data. Use `docker compose down` alone to preserve data.

## Security

- Change the default password immediately after first login
- For production: Update APP_KEY and database password in compose.yml
- Never commit the data/ folder to version control
- Do not expose port 13000 to the internet without proper authentication

## Resources

- NocoBase Documentation: https://docs.nocobase.com/
- Docker Compose Guide: https://docs.docker.com/compose/
- Bind Mounts Reference: https://docs.docker.com/engine/storage/bind-mounts/
