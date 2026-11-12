#!/bin/sh
# Checks the HAProxy rules from two vantage points. Run it with the commands in README.md.
#
#   verify-proxy.sh outside   a visitor on the internet with no VPN   (service: outsider)
#   verify-proxy.sh vpn       the work-from-home laptop with the VPN  (service: wfh-vpn)
#
# "Blocked" means HAProxy itself answered 403 with its "Blocked by HAProxy" message.
# "Through" means the request got past HAProxy and NocoBase answered it.
# These checks only read data or send requests that NocoBase refuses (no token), so they
# never change your data or configuration. Exit code is 0 only if every check passes.

mode="${1:-outside}"
PUBLIC=http://10.77.1.10:8080         # HAProxy public face, over the "internet" network
ADMIN_TUNNEL=http://10.77.9.1:8081    # VPN gateway address inside the tunnel -> HAProxy admin face
ADMIN_INTRANET=http://10.77.2.10:8081 # HAProxy admin face, intranet address
TMP=$(mktemp -d)
pass=0
fail=0

# request METHOD URL [extra curl args...]  -> sets: code blocked face (and keeps body in $TMP/body)
request() {
  method=$1; url=$2; shift 2
  code=$(curl -s -m 8 --connect-timeout 4 --path-as-is -X "$method" -D "$TMP/head" -o "$TMP/body" -w '%{http_code}' "$@" "$url")
  blocked=no; grep -q "Blocked by HAProxy" "$TMP/body" 2>/dev/null && blocked=yes
  face=$(tr -d '\r' < "$TMP/head" 2>/dev/null | sed -n 's/^[Xx]-[Pp]roxy-[Ff]ace: *//p' | head -n 1)
}

report() { # report PASS|FAIL description detail
  if [ "$1" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
  printf '  %-4s %s  (%s)\n' "$1" "$2" "$3"
}

expect_blocked() { # description method url [curl args]
  desc=$1; shift; request "$@"
  if [ "$code" = 403 ] && [ "$blocked" = yes ]; then report PASS "$desc" "HTTP $code, blocked by HAProxy"
  else report FAIL "$desc" "wanted a HAProxy 403, got HTTP $code blocked=$blocked"; fi
}

expect_through() { # description method url [curl args]
  desc=$1; shift; request "$@"
  if [ "$code" != 000 ] && [ "$blocked" = no ]; then report PASS "$desc" "HTTP $code from NocoBase via the $face face"
  else report FAIL "$desc" "wanted an answer from NocoBase, got HTTP $code blocked=$blocked"; fi
}

expect_unreachable() { # description url
  desc=$1; url=$2
  if curl -s -m 5 --connect-timeout 3 -o /dev/null "$url"; then report FAIL "$desc" "connection worked but should not"
  else report PASS "$desc" "no connection, as intended"; fi
}

sign_in() { # sets TOKEN for the entry attendant
  TOKEN=$(curl -s -m 8 -X POST -H 'Content-Type: application/json' -H 'X-Authenticator: basic' \
    -d '{"account":"entry@clicker.test","email":"entry@clicker.test","password":"admin123"}' \
    "$PUBLIC/api/auth:signIn" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  if [ -n "$TOKEN" ]; then report PASS "attendant can sign in through the public face" "token received"
  else report FAIL "attendant can sign in through the public face" "no token returned"; fi
}

public_checks() {
  echo "Public face ($PUBLIC): public routes must work"
  expect_through "sign-in page loads"                      GET  "$PUBLIC/signin"
  expect_through "app shell loads"                         GET  "$PUBLIC/admin"
  expect_through "login screen settings (publicList)"      GET  "$PUBLIC/api/authenticators:publicList"
  sign_in
  if [ -n "$TOKEN" ]; then
    expect_through "list events as the attendant"          GET  "$PUBLIC/api/attendanceEvents:list?pageSize=5" -H "Authorization: Bearer $TOKEN"
  fi

  echo "Public face ($PUBLIC): admin routes must be refused"
  expect_blocked "NocoBase settings page"                  GET  "$PUBLIC/admin/settings"
  expect_blocked "plugin manager page"                     GET  "$PUBLIC/admin/settings/plugin-manager"
  expect_blocked "sign-up page"                            GET  "$PUBLIC/signup"
  expect_blocked "create an account (API)"                 POST "$PUBLIC/api/auth:signUp" -H 'Content-Type: application/json' -d '{}'
  expect_blocked "enable or disable a plugin"              POST "$PUBLIC/api/pm:enable"
  expect_blocked "list plugins"                            GET  "$PUBLIC/api/applicationPlugins:list"
  expect_blocked "create a collection (change the data model)" POST "$PUBLIC/api/collections:create" -H 'Content-Type: application/json' -d '{}'
  expect_blocked "edit page layout (UI schema)"            POST "$PUBLIC/api/uiSchemas:insert" -H 'Content-Type: application/json' -d '{}'
  expect_blocked "create a role"                           POST "$PUBLIC/api/roles:create" -H 'Content-Type: application/json' -d '{}'
  expect_blocked "list users"                              GET  "$PUBLIC/api/users:list"
  expect_blocked "update a record with PUT"                PUT  "$PUBLIC/api/venues:update"
  expect_blocked "dot-dot trick to reach settings"         GET  "$PUBLIC/admin/../admin/settings"
  expect_blocked "encoded dot-dot trick"                   GET  "$PUBLIC/admin/%2e%2e/admin/settings"
  expect_blocked "method override header"                  GET  "$PUBLIC/api/collections:create" -H 'X-HTTP-Method-Override: POST'
}

case "$mode" in
  outside)
    echo "== Visitor on the internet, no VPN =="
    public_checks
    echo "Everything else must be out of reach"
    expect_unreachable "admin face on the internet address" "http://10.77.1.10:8081/"
    expect_unreachable "admin face on the intranet address"  "$ADMIN_INTRANET/"
    expect_unreachable "NocoBase itself (app)"               "http://app/"
    ;;
  vpn)
    echo "== Work-from-home laptop, VPN up =="
    if [ "$(wg show wg0 latest-handshakes 2>/dev/null | awk '{print $2}' | head -n 1)" -gt 0 ] 2>/dev/null; then
      report PASS "VPN handshake completed" "wg0 is up"
    else
      report FAIL "VPN handshake completed" "wg0 has no handshake"
    fi
    echo "Admin face through the VPN ($ADMIN_TUNNEL): admin routes must work"
    expect_through "NocoBase settings page"                GET  "$ADMIN_TUNNEL/admin/settings"
    expect_through "plugin manager page"                   GET  "$ADMIN_TUNNEL/admin/settings/plugin-manager"
    expect_through "list plugins"                          GET  "$ADMIN_TUNNEL/api/applicationPlugins:list"
    expect_through "enable-plugin call reaches NocoBase (no token, so NocoBase refuses it)" POST "$ADMIN_TUNNEL/api/pm:enable"
    if [ "$face" = admin ]; then report PASS "answer came from the admin face" "X-Proxy-Face: admin"
    else report FAIL "answer came from the admin face" "X-Proxy-Face was '$face'"; fi
    echo "Without the VPN path, the same laptop gets nothing extra"
    expect_unreachable "intranet address directly (no route)" "$ADMIN_INTRANET/"
    public_checks
    ;;
  *)
    echo "usage: $0 outside|vpn"; exit 2 ;;
esac

rm -rf "$TMP"
echo
echo "Result: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
