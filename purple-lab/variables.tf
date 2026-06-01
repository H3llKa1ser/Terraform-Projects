variable "lab_name" {
  type    = string
  default = "purple-lab"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "ssh_public_key" {
  description = "Operator SSH public key"
  type        = string
}

variable "operator_cidrs" {
  description = "Operator source IPs (CIDR) allowed to reach the bastion"
  type        = list(string)
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "siem_instance_type" {
  description = "Wazuh needs RAM; t3.large minimum recommended"
  type        = string
  default     = "t3.large"
}

variable "target_instance_type" {
  type    = string
  default = "t3.small"
}

variable "caldera_instance_type" {
  type    = string
  default = "t3.medium"
}
