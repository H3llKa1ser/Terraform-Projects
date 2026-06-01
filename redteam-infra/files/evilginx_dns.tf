# Glue: ns1.<evilginx_domain> -> Evilginx public IP
resource "cloudflare_record" "evilginx_ns_glue" {
  count   = var.evilginx_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "ns1.${var.evilginx_domain}"
  type    = "A"
  content = aws_instance.evilginx.public_ip
  proxied = false
  ttl     = 120
  comment = "Evilginx NS glue: ${var.engagement_name}"
}

# Delegate the evilginx subdomain to that nameserver
resource "cloudflare_record" "evilginx_delegation" {
  count   = var.evilginx_domain != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.evilginx_domain
  type    = "NS"
  content = "ns1.${var.evilginx_domain}"
  ttl     = 120
  comment = "Delegate zone to Evilginx: ${var.engagement_name}"
}
