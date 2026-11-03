#!/usr/bin/with-contenv bash
# Runs when the work-from-home container starts: installs the VPN profile the server
# generated for the "home" peer. The DNS line is dropped (the test network has no VPN DNS);
# only intranet traffic (10.0.2.0/24) goes through the tunnel, everything else stays local.
for i in $(seq 1 60); do [ -f /peer/peer_home.conf ] && break; sleep 2; done
mkdir -p /config/wg_confs
sed '/^DNS/d' /peer/peer_home.conf > /config/wg_confs/wg0.conf
chmod 600 /config/wg_confs/wg0.conf
