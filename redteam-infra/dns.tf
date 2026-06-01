# --- HTTP redirector A record ---
resource "cloudflare_record" "redirector" {
  count   = var.redirector_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.redirector_domain
  type    = "A"
  content = aws_instance.redirector.public_ip
  proxied = false
  ttl     = 120
  comment = "Authorized engagement: ${var.engagement_name}"
}

# --- DNS C2 delegation ---
# 1) A record for the nameserver host (glue), e.g. ns1.<domain>
resource "cloudflare_record" "dns_ns_glue" {
  count   = var.dns_c2_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "ns1.${var.dns_c2_domain}"
  type    = "A"
  content = aws_instance.dns_redirector.public_ip
  proxied = false
  ttl     = 120
  comment = "DNS C2 nameserver glue: ${var.engagement_name}"
}

# 2) Delegate the C2 subdomain to that nameserver via NS record
resource "cloudflare_record" "dns_delegation" {
  count   = var.dns_c2_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.dns_c2_domain
  type    = "NS"
  content = "ns1.${var.dns_c2_domain}"
  ttl     = 120
  comment = "Delegate DNS C2 zone to redirector: ${var.engagement_name}"
}

# --- Phishing landing domain A record -> phishing redirector ---
resource "cloudflare_record" "phish_redirector" {
  count   = var.phishing_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.phishing_domain
  type    = "A"
  content = aws_instance.phish_redirector.public_ip
  proxied = false
  ttl     = 120
  comment = "Authorized phishing engagement: ${var.engagement_name}"
}
