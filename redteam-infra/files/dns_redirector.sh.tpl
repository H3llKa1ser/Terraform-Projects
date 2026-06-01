#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y socat ufw

# Host firewall: allow DNS + SSH only (SG is primary control)
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 53/udp
ufw allow 53/tcp
ufw --force enable

# --- UDP relay: public :53/udp  ->  team server :${dns_listener_port}/udp ---
cat > /etc/systemd/system/dns-redirect-udp.service <<UNIT
[Unit]
Description=DNS C2 UDP redirector (socat)
After=network.target

[Service]
ExecStart=/usr/bin/socat -T15 UDP4-LISTEN:53,reuseaddr,fork UDP4:${team_server_ip}:${dns_listener_port}
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

# --- TCP relay: public :53/tcp  ->  team server :${dns_listener_port}/tcp ---
cat > /etc/systemd/system/dns-redirect-tcp.service <<UNIT
[Unit]
Description=DNS C2 TCP redirector (socat)
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:53,reuseaddr,fork TCP4:${team_server_ip}:${dns_listener_port}
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now dns-redirect-udp.service
systemctl enable --now dns-redirect-tcp.service

echo "DNS redirector provisioned: $(date -u)" > /var/log/provision-status.log
