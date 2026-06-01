#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SIEM_IP="${siem_ip}"

apt-get update -y
apt-get upgrade -y
apt-get install -y curl git auditd ufw powershell || true

# --- Linux audit telemetry ---
systemctl enable --now auditd || true

# --- Host firewall ---
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

# --- Wazuh agent -> SIEM ---
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update -y
WAZUH_MANAGER="$SIEM_IP" apt-get install -y wazuh-agent
systemctl daemon-reload
systemctl enable --now wazuh-agent

# --- Atomic Red Team (via PowerShell, the supported invoker) ---
# Installs the Invoke-AtomicRedTeam module + the atomics library.
pwsh -NoProfile -Command "
  Install-Module -Name invoke-atomicredteam -Scope AllUsers -Force -ErrorAction SilentlyContinue;
  IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
  Install-AtomicRedTeam -getAtomics -Force
" || echo "Atomic Red Team install step encountered an issue; review manually."

echo "Target provisioned (Wazuh agent + auditd + Atomic Red Team): $(date -u)" > /var/log/provision-status.log
echo "Run a technique example: pwsh -c \"Invoke-AtomicTest T1059.004\"" >> /var/log/provision-status.log
