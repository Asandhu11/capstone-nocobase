#!/bin/sh
# Starts one end of the WireGuard tunnel.
#
#   entrypoint.sh gateway   runs on the intranet side (vpn-server)
#   entrypoint.sh client    runs on the work-from-home side (wfh-vpn)
#
# Settings come from environment variables set in compose.yml:
#   WG_CONF      path to the WireGuard config for this end
#   WG_ADDRESS   this end's address inside the tunnel, e.g. 10.77.9.1/24
#   ADMIN_TARGET (gateway only) where to hand admin traffic, e.g. 10.77.2.10:8081
set -eu

role="${1:?usage: entrypoint.sh gateway|client}"

echo "[vpn:$role] creating WireGuard interface wg0"
ip link add wg0 type wireguard
wg setconf wg0 "$WG_CONF"
ip address add "$WG_ADDRESS" dev wg0
ip link set wg0 mtu 1380 up
# "ip address add" with a /24 already adds the route for the tunnel network.

wg show wg0

if [ "$role" = "gateway" ]; then
  # The gateway listens on its tunnel address only (never on the internet-facing
  # address) and hands each connection to the intranet proxy's admin face.
  # The proxy then sees the connection coming from the gateway's intranet address.
  tunnel_ip="${WG_ADDRESS%%/*}"
  echo "[vpn:gateway] forwarding ${tunnel_ip}:8081 -> ${ADMIN_TARGET}"
  exec socat "TCP-LISTEN:8081,bind=${tunnel_ip},fork,reuseaddr" "TCP:${ADMIN_TARGET}"
fi

echo "[vpn:client] tunnel up; keeping the container running"
exec tail -f /dev/null
