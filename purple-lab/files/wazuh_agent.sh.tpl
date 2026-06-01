#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SIEM_IP="${siem_ip}"

apt-get update -y
apt-get install -y curl

curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh || true

# Install the agent pointed at the manager
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update -y

WAZUH_MANAGER="$SIEM_IP" apt-get install -y wazuh-agent

systemctl daemon-reload
systemctl enable --now wazuh-agent

echo "Wazuh agent installed, manager=$SIEM_IP : $(date -u)" > /var/log/provision-status.log
