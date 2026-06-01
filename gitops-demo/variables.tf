variable "cloudflare_api_token" {
  description = "Cloudflare API token with Pages + DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID"
  type        = string
}

variable "project_name" {
  description = "Cloudflare Pages project name (becomes <name>.pages.dev)"
  type        = string
  default     = "gitops-demo"
}

variable "github_owner" {
  description = "GitHub username/org that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "gitops-demo"
}

variable "production_branch" {
  description = "Branch that triggers production deploys"
  type        = string
  default     = "main"
}

variable "custom_domain" {
  description = "Custom domain for the site (leave empty to use *.pages.dev only)"
  type        = string
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Zone ID of your domain (required only if using custom_domain)"
  type        = string
  default     = ""
}
