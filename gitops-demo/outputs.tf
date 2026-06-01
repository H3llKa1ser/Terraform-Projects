output "pages_url" {
  description = "Default Pages URL"
  value       = "https://${cloudflare_pages_project.site.subdomain}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "not configured"
}
