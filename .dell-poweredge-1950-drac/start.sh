#!/usr/bin/env bash
set -euo pipefail

IFACE="enp4s0"
STATIC_IP="192.168.0.100/24"
DHCP_RANGE_START="192.168.0.50"
DHCP_RANGE_END="192.168.0.110"
DHCP_NETMASK="255.255.255.0"
FACTORY_DEFAULT_IP="192.168.0.120"
IMAGE_NAME="drac-legacy:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEASE_FILE="$SCRIPT_DIR/dnsmasq.leases"
CERT_DIR="$SCRIPT_DIR/certs"
STUNNEL_CONF="$SCRIPT_DIR/stunnel-drac.conf"

echo "Make sure the DRAC ethernet port is connected to $IFACE and the server is powered on."

STALE_CONTAINERS=$(docker ps -a --filter "name=drac-" -q)
if [ -n "$STALE_CONTAINERS" ]; then
  echo "Removing stale drac-* containers..."
  docker rm -f $STALE_CONTAINERS
fi

sudo ip addr add "$STATIC_IP" dev "$IFACE" 2>/dev/null || true

cleanup_fw() {
  while sudo iptables -C nixos-fw -i "$IFACE" -p udp --dport 67 -j ACCEPT 2>/dev/null; do
    sudo iptables -D nixos-fw -i "$IFACE" -p udp --dport 67 -j ACCEPT
  done
}
cleanup_fw
trap cleanup_fw EXIT

sudo iptables -I nixos-fw 1 -i "$IFACE" -p udp --dport 67 -j ACCEPT

echo "Waiting for DRAC DHCP lease (up to 180s)..."
sudo timeout 180 nix run nixpkgs#dnsmasq -- -d --port=0 --interface="$IFACE" --bind-interfaces \
  --dhcp-range="$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_NETMASK,1h" \
  --dhcp-leasefile="$LEASE_FILE" --log-dhcp > "$SCRIPT_DIR/dnsmasq.log" 2>&1 || true

DRAC_IP=$(awk '{print $3}' "$LEASE_FILE" 2>/dev/null | tail -1)

cleanup_fw
trap - EXIT

if [ -z "${DRAC_IP:-}" ]; then
  echo "No DHCP lease captured. Checking factory default static IP $FACTORY_DEFAULT_IP..."
  if ping -c 2 -W 2 "$FACTORY_DEFAULT_IP" >/dev/null 2>&1; then
    DRAC_IP="$FACTORY_DEFAULT_IP"
  else
    echo "No response at $FACTORY_DEFAULT_IP either. Is the DRAC powered on and connected to $IFACE?"
    echo "Check $SCRIPT_DIR/dnsmasq.log for details."
    exit 1
  fi
fi

echo "DRAC found at $DRAC_IP"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Building legacy TLS image (Debian Jessie + OpenSSL 1.0.1 + stunnel)..."
  docker rm -f drac-legacy-build 2>/dev/null || true
  docker pull debian:jessie
  docker run --name drac-legacy-build debian:jessie sh -c "
    sed -i 's/deb.debian.org/archive.debian.org/g; s/security.debian.org/archive.debian.org/g' /etc/apt/sources.list
    apt-get -o Acquire::Check-Valid-Until=false update
    apt-get -o Acquire::Check-Valid-Until=false install -y --allow-unauthenticated openssl curl stunnel4
  "
  docker commit drac-legacy-build "$IMAGE_NAME"
  docker rm drac-legacy-build
fi

mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/proxy-combined.pem" ]; then
  echo "Generating self-signed proxy certificate..."
  docker rm -f drac-cert-gen 2>/dev/null || true
  docker run --name drac-cert-gen "$IMAGE_NAME" openssl req -x509 -newkey rsa:2048 -keyout /tmp/key.pem -out /tmp/cert.pem -days 365 -nodes -subj "/CN=127.0.0.1"
  docker cp drac-cert-gen:/tmp/key.pem "$CERT_DIR/key.pem"
  docker cp drac-cert-gen:/tmp/cert.pem "$CERT_DIR/cert.pem"
  docker rm drac-cert-gen
  cat "$CERT_DIR/key.pem" "$CERT_DIR/cert.pem" > "$CERT_DIR/proxy-combined.pem"
fi

cat > "$STUNNEL_CONF" << EOF
foreground = yes
debug = 5

[incoming]
client = no
accept = 127.0.0.1:443
connect = 127.0.0.1:8080
cert = /etc/stunnel/proxy-combined.pem

[outgoing]
client = yes
accept = 127.0.0.1:8080
connect = $DRAC_IP:443
EOF

docker rm -f drac-stunnel 2>/dev/null || true

docker run -d --name drac-stunnel --network host \
  -v "$STUNNEL_CONF:/etc/stunnel/stunnel.conf" \
  -v "$CERT_DIR/proxy-combined.pem:/etc/stunnel/proxy-combined.pem" \
  "$IMAGE_NAME" stunnel4 /etc/stunnel/stunnel.conf

echo ""
echo "Proxy running. Open https://127.0.0.1/ in your browser."
echo "Accept the self-signed certificate warning to reach the DRAC login."
echo "DRAC is at $DRAC_IP"
echo ""
echo "To stop the proxy: docker rm -f drac-stunnel"
