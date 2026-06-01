variable "engagement_name" {
  description = "Short identifier for this authorized engagement"
  type        = string
  default     = "engagement-001"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "ssh_public_key" {
  description = "Your SSH public key for operator access"
  type        = string
}

# CRITICAL: restrict all management access to these IPs only.
variable "operator_cidrs" {
  description = "List of operator source IPs (CIDR) allowed to manage hosts"
  type        = list(string)
  # Example: ["203.0.113.10/32"]
}

variable "team_server_instance_type" {
  type    = string
  default = "t3.small"
}

variable "redirector_instance_type" {
  type    = string
  default = "t3.micro"
}

# C2 listener port the redirector forwards to the team server
variable "c2_listener_port" {
  type    = number
  default = 443
}

# Optional Cloudflare DNS for the redirector
variable "cloudflare_api_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

variable "redirector_domain" {
  description = "FQDN for the redirector (leave empty to skip DNS)"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "dns_redirector_instance_type" {
  type    = string
  default = "t3.micro"
}

# DNS-beacon listener port on the team server
variable "dns_listener_port" {
  type    = number
  default = 53
}

# Operator's DNS C2 domain (NS-delegated to the DNS redirector).
# Must be in your RoE scope.
variable "dns_c2_domain" {
  description = "Domain delegated for DNS C2 (e.g., ns.example-engagement.com)"
  type        = string
  default     = ""
}
