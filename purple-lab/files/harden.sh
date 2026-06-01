#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y unattended-upgrades fail2ban ufw curl

dpkg-reconfigure -f noninteractive unattended-upgrades

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

systemctl enable --now fail2ban

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

echo "Hardening complete: $(date -u)" > /var/log/provision-status.log
