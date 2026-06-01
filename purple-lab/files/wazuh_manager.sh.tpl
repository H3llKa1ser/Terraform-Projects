#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl

# Official Wazuh all-in-one installer (manager + indexer + dashboard)
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
bash ./wazuh-install.sh -a -i 2>&1 | tee /var/log/wazuh-install.log

# Credentials for the 'admin' dashboard user are written here by the installer:
#   tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
echo "Wazuh all-in-one installed: $(date -u)" > /var/log/provision-status.log
echo "Retrieve dashboard password from wazuh-install-files.tar (wazuh-passwords.txt)" >> /var/log/provision-status.log
