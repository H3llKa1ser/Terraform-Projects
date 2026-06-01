#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y unzip curl ufw jq

# --- Base SSH hardening (matches harden.sh) ---
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# --- Host firewall (SG is primary control) ---
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow ${gophish_admin_port}/tcp
ufw allow ${gophish_phish_port}/tcp
ufw --force enable

# --- Install GoPhish (latest release) ---
GP_DIR=/opt/gophish
mkdir -p "$GP_DIR"
cd "$GP_DIR"

GP_URL=$(curl -s https://api.github.com/repos/gophish/gophish/releases/latest \
  | jq -r '.assets[] | select(.name | test("linux-64bit")) | .browser_download_url')
curl -L -o gophish.zip "$GP_URL"
unzip -o gophish.zip
chmod +x gophish

# --- Configure: admin binds to all interfaces (bastion-tunnel reaches it),
#     phishing server binds to all interfaces (redirector reaches it) ---
cat > "$GP_DIR/config.json" <<CFG
{
  "admin_server": {
    "listen_url": "0.0.0.0:${gophish_admin_port}",
    "use_tls": true,
    "cert_path": "gophish_admin.crt",
    "key_path": "gophish_admin.key"
  },
  "phish_server": {
    "listen_url": "0.0.0.0:${gophish_phish_port}",
    "use_tls": false,
    "cert_path": "example.crt",
    "key_path": "example.key"
  },
  "db_name": "sqlite3",
  "db_path": "gophish.db",
  "migrations_prefix": "db/db_",
  "contact_address": "",
  "logging": {
    "filename": "",
    "level": ""
  }
}
CFG

# --- systemd service ---
cat > /etc/systemd/system/gophish.service <<UNIT
[Unit]
Description=GoPhish phishing framework
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/gophish
ExecStart=/opt/gophish/gophish
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now gophish.service

# Initial admin password is printed in the GoPhish log on first start.
echo "GoPhish provisioned: $(date -u)" > /var/log/provision-status.log
echo "Retrieve the initial admin password with: journalctl -u gophish | grep -i 'please login'" >> /var/log/provision-status.log
