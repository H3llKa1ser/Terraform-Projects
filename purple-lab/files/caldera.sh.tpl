#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y git python3 python3-pip python3-venv golang-go ufw

# --- Host firewall ---
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 8888/tcp
ufw --force enable

# --- Clone & set up Caldera ---
CALDERA_DIR=/opt/caldera
git clone https://github.com/mitre/caldera.git --recursive "$CALDERA_DIR"
cd "$CALDERA_DIR"

python3 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# --- systemd service (insecure default config generates random creds) ---
cat > /etc/systemd/system/caldera.service <<UNIT
[Unit]
Description=MITRE Caldera
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/caldera
ExecStart=/opt/caldera/venv/bin/python3 /opt/caldera/server.py --insecure
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now caldera.service

echo "Caldera provisioned on :8888 : $(date -u)" > /var/log/provision-status.log
echo "Default creds (insecure mode): see /opt/caldera/conf/default.yml (red/blue users)" >> /var/log/provision-status.log

# Note: --insecure uses Caldera's default config with built-in users (red/admin, etc.). For anything beyond an isolated lab, generate a hardened config with strong credentials. Since the UI is only reachable via the bastion tunnel here, the lab exposure is contained. 
