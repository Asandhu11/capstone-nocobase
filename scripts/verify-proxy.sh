#!/usr/bin/env bash
# Proves the Caddy proxy rule from three places:
#   outside = this computer, through the published port (the public internet)
#   office  = a machine on the intranet
#   home    = a work-from-home machine on the internet, connected through the WireGuard VPN
# Run after: docker compose up -d --wait --wait-timeout 600
# Every probe is read-only or unauthenticated: nothing in Clicker is changed.
set -u
cd "$(dirname "$0")/.."
OUT="http://localhost:${CLICKER_PORT:-13005}"
PROXY_INTRANET="http://10.0.2.10"   # the proxy's intranet address
pass=0; fail=0

# code <where> <url> [curl args...] -> prints "<status> <x-clicker-proxy header>"
code() {
  local where=$1 url=$2; shift 2
  local fmt='%{http_code} %header{x-clicker-proxy}'
  case $where in
    outside) curl -s -o /dev/null -m 15 -w "$fmt" "$@" "$url" ;;
    office)  docker compose exec -T office curl -s -o /dev/null -m 15 -w "$fmt" "$@" "$url" ;;
    home)    docker compose exec -T home curl -s -o /dev/null -m 15 -w "$fmt" "$@" "$url" ;;
  esac
}
check() { # check <description> <expected regex> <where> <url> [curl args]
  local desc=$1 want=$2; shift 2
  local got; got=$(code "$@" 2>/dev/null) || true
  if [[ $got =~ $want ]]; then echo "PASS  $desc  ($got)"; pass=$((pass+1));
  else echo "FAIL  $desc  (got '$got', want /$want/)"; fail=$((fail+1)); fi
}
BLOCKED='^403 blocked$'
NOT_BLOCKED='^[0-9]{3} ?$'   # any answer from NocoBase itself, never the proxy's block

echo "== Outside: public routes work"
check "home page"                    '^(200|302) ?$' outside "$OUT/"
check "sign-in page"                 '^200 ?$'       outside "$OUT/signin"
check "app info API"                 '^200 ?$'       outside "$OUT/api/app:getInfo"
check "attendant sign-in API"        '^200 ?$'       outside "$OUT/api/auth:signIn" -X POST -H 'Content-Type: application/json' -H 'X-Authenticator: basic' -d '{"account":"entry@clicker.test","password":"admin123"}'
check "enabled plugins list (needed by every page load)" '^200 ?$' outside "$OUT/api/pm:listEnabled"

echo "== Outside: admin routes are blocked by the proxy"
check "settings page"                "$BLOCKED" outside "$OUT/admin/settings"
check "plugin manager page"          "$BLOCKED" outside "$OUT/admin/pm/list"
check "enable a plugin"              "$BLOCKED" outside "$OUT/api/pm:enable" -X POST
check "create a collection"          "$BLOCKED" outside "$OUT/api/collections:create" -X POST
check "add a field"                  "$BLOCKED" outside "$OUT/api/collections/venues/fields:create" -X POST
check "edit a page layout"           "$BLOCKED" outside "$OUT/api/uiSchemas:insertAdjacent/abc" -X POST
check "save a page model"            "$BLOCKED" outside "$OUT/api/flowModels:save" -X POST
check "create a role"                "$BLOCKED" outside "$OUT/api/roles:create" -X POST
check "change role permissions"      "$BLOCKED" outside "$OUT/api/roles/member/dataSourceResources:update" -X POST
check "create a user"                "$BLOCKED" outside "$OUT/api/users:create" -X POST
check "change system settings"       "$BLOCKED" outside "$OUT/api/systemSettings:update/1" -X POST
check "restart the app"              "$BLOCKED" outside "$OUT/api/app:restart" -X POST

echo "== Outside: tricks do not get around the rule"
check "upper-case path"              "$BLOCKED" outside "$OUT/API/Collections:Create" -X POST
check "double slash"                 "$BLOCKED" outside "$OUT//api//collections:create" -X POST
check "encoded colon"                "$BLOCKED" outside "$OUT/api/collections%3Acreate" -X POST
check "forged X-Forwarded-For"       "$BLOCKED" outside "$OUT/api/collections:create" -X POST -H 'X-Forwarded-For: 10.0.2.50'
check "app port not exposed directly" '^000'    outside "http://localhost:${NOCOBASE_PORT:-13003}/"

echo "== Office (intranet): admin routes reach NocoBase"
check "settings page"                "$NOT_BLOCKED" office "$PROXY_INTRANET/admin/settings"
check "enable a plugin (unauthenticated, NocoBase refuses)" "$NOT_BLOCKED" office "$PROXY_INTRANET/api/pm:enable" -X POST
check "create a collection (unauthenticated, NocoBase refuses)" "$NOT_BLOCKED" office "$PROXY_INTRANET/api/collections:create" -X POST

echo "== Home: the public address behaves like the internet"
check "public site works from home"  '^200 ?$' home "http://10.0.1.10/signin"
check "admin blocked on the public address" "$BLOCKED" home "http://10.0.1.10/admin/settings"

echo "== Home: through the VPN, admin routes reach NocoBase"
check "settings page via VPN"        "$NOT_BLOCKED" home "$PROXY_INTRANET/admin/settings"
check "create a collection via VPN (unauthenticated, NocoBase refuses)" "$NOT_BLOCKED" home "$PROXY_INTRANET/api/collections:create" -X POST

echo "== Home: the VPN is what makes the difference"
route=$(docker compose exec -T home ip route get 10.0.2.10 2>/dev/null)
if [[ $route == *"dev wg0"* ]]; then echo "PASS  intranet traffic leaves home through the WireGuard tunnel (wg0)"; pass=$((pass+1));
else echo "FAIL  intranet route does not use wg0: $route"; fail=$((fail+1)); fi
docker compose exec -T home wg-quick down wg0 >/dev/null 2>&1
check "with the VPN off, the intranet proxy is unreachable" '^000' home "$PROXY_INTRANET/admin/settings" -m 5
docker compose exec -T home wg-quick up wg0 >/dev/null 2>&1
check "with the VPN back on, admin works again" "$NOT_BLOCKED" home "$PROXY_INTRANET/admin/settings"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
