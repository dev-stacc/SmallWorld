#!/usr/bin/env bash
set -euo pipefail

IFACE="enp4s0"
WAN_IFACE="${WAN_IFACE:-wlan0}"
SERVER_IP="192.168.0.100"
SERVER_CIDR="$SERVER_IP/24"
SUBNET="192.168.0.0/24"
DHCP_RANGE_START="192.168.0.50"
DHCP_RANGE_END="192.168.0.110"
DHCP_NETMASK="255.255.255.0"
UPSTREAM_DNS="1.1.1.1"
HTTP_PORT="8080"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFTP_ROOT="$SCRIPT_DIR/tftp"
HTTP_ROOT="$SCRIPT_DIR/www"
LEASE_FILE="$SCRIPT_DIR/dnsmasq-pxe.leases"
LOG_FILE="$SCRIPT_DIR/dnsmasq-pxe.log"

for r in result result-1 result-2 result-3; do
  if [ ! -e "$SCRIPT_DIR/$r" ]; then
    echo "Missing $SCRIPT_DIR/$r"
    echo "Build the netboot artifacts first:"
    echo "  cd $SCRIPT_DIR && nix build --impure -f netboot.nix netbootRamdisk netbootIpxeScript kernel ipxe -o result"
    exit 1
  fi
done

DARKHTTPD="$(nix build --no-link --print-out-paths nixpkgs#darkhttpd)/bin/darkhttpd"

echo "Staging TFTP and HTTP roots..."
rm -rf "$TFTP_ROOT" "$HTTP_ROOT"
mkdir -p "$TFTP_ROOT" "$HTTP_ROOT"

IPXE_DIR="$(readlink -f "$SCRIPT_DIR/result-3")"
install -m 0644 "$IPXE_DIR/undionly.kpxe" "$TFTP_ROOT/undionly.kpxe"
if [ -f "$IPXE_DIR/ipxe.pxe" ]; then install -m 0644 "$IPXE_DIR/ipxe.pxe" "$TFTP_ROOT/ipxe.pxe"; fi

install -m 0644 "$(readlink -f "$SCRIPT_DIR/result-1")/netboot.ipxe" "$HTTP_ROOT/netboot.ipxe"
install -m 0644 "$(readlink -f "$SCRIPT_DIR/result-2")/bzImage" "$HTTP_ROOT/bzImage"
install -m 0644 "$(readlink -f "$SCRIPT_DIR/result")/initrd" "$HTTP_ROOT/initrd"

echo "initrd: $(du -h "$HTTP_ROOT/initrd" | cut -f1)   bzImage: $(du -h "$HTTP_ROOT/bzImage" | cut -f1)"

sudo ip addr add "$SERVER_CIDR" dev "$IFACE" 2>/dev/null || true
sudo ip link set "$IFACE" up

sudo sysctl -qw net.ipv4.ip_forward=1

FW_RULES=(
  "nixos-fw -i $IFACE -p udp --dport 67 -j ACCEPT"
  "nixos-fw -i $IFACE -p udp --dport 69 -j ACCEPT"
  "nixos-fw -i $IFACE -p tcp --dport $HTTP_PORT -j ACCEPT"
)

cleanup() {
  set +e
  for rule in "${FW_RULES[@]}"; do
    while sudo iptables -C $rule 2>/dev/null; do sudo iptables -D $rule; done
  done
  while sudo iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$WAN_IFACE" -j MASQUERADE 2>/dev/null; do
    sudo iptables -t nat -D POSTROUTING -s "$SUBNET" -o "$WAN_IFACE" -j MASQUERADE
  done
  while sudo iptables -C FORWARD -i "$IFACE" -o "$WAN_IFACE" -j ACCEPT 2>/dev/null; do
    sudo iptables -D FORWARD -i "$IFACE" -o "$WAN_IFACE" -j ACCEPT
  done
  while sudo iptables -C FORWARD -i "$WAN_IFACE" -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; do
    sudo iptables -D FORWARD -i "$WAN_IFACE" -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
  done
  [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2>/dev/null
  echo "Cleaned up."
}
trap cleanup EXIT INT TERM

cleanup 2>/dev/null || true
trap cleanup EXIT INT TERM

for rule in "${FW_RULES[@]}"; do sudo iptables -I $rule; done
sudo iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$WAN_IFACE" -j MASQUERADE
sudo iptables -I FORWARD 1 -i "$IFACE" -o "$WAN_IFACE" -j ACCEPT
sudo iptables -I FORWARD 1 -i "$WAN_IFACE" -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT

"$DARKHTTPD" "$HTTP_ROOT" --addr "$SERVER_IP" --port "$HTTP_PORT" >/dev/null 2>&1 &
HTTP_PID=$!
echo "HTTP server on $SERVER_IP:$HTTP_PORT (pid $HTTP_PID)"

echo ""
echo "Move the ethernet cable from the DRAC port to onboard Gb1, then power on and let it PXE boot."
echo "Ctrl-C here to tear everything down."
echo ""

sudo nix run nixpkgs#dnsmasq -- -d --port=0 --interface="$IFACE" --bind-interfaces \
  --dhcp-range="$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_NETMASK,1h" \
  --dhcp-option=3,"$SERVER_IP" \
  --dhcp-option=6,"$UPSTREAM_DNS" \
  --dhcp-leasefile="$LEASE_FILE" \
  --enable-tftp --tftp-root="$TFTP_ROOT" \
  --dhcp-match=set:ipxe,175 \
  --dhcp-boot=tag:!ipxe,undionly.kpxe \
  --dhcp-boot=tag:ipxe,"http://$SERVER_IP:$HTTP_PORT/netboot.ipxe" \
  --log-dhcp 2>&1 | tee "$LOG_FILE"
