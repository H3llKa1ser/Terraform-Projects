#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx certbot python3-certbot-nginx ssl-cert ufw

# Host firewall (SG is primary control)
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# --- Reverse proxy: public HTTPS -> GoPhish phishing server (private) ---
cat > /etc/nginx/sites-available/phish.conf <<'NGINX'
server {
    listen 80;
    server_name ${server_name};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${server_name};

    # Snakeoil placeholder until certbot installs a real cert.
    ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers   HIGH:!aNULL:!MD5;

    # Forward all landing-page traffic to GoPhish.
    # Preserve client IP so GoPhish logs/captures are accurate.
    location / {
        proxy_pass              http://${gophish_ip}:${gophish_phish_port};
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_read_timeout      90s;
        proxy_connect_timeout   90s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/phish.conf /etc/nginx/sites-enabled/phish.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl restart nginx

# --- Real cert via Let's Encrypt (only if a real domain is set) ---
if [ "${server_name}" != "_" ]; then
  certbot --nginx -n --agree-tos --register-unsafely-without-email \
    -d "${server_name}" || echo "certbot failed; continuing with snakeoil cert"
fi

echo "Phishing redirector provisioned: $(date -u)" > /var/log/provision-status.log
