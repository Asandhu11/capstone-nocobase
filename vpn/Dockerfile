# Small helper image used for three things in the Sprint 5 network:
#   vpn-server  the WireGuard gateway on the intranet
#   wfh-vpn     the work-from-home side of the tunnel
#   outsider    a plain machine on the "internet" network used to check the proxy
# The scripts and keys are bind-mounted from ./vpn and ./scripts, so only the tools live here.
FROM alpine:3.20
RUN apk add --no-cache wireguard-tools iproute2 socat curl
