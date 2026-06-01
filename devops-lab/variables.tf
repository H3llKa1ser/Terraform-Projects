variable "aws_region" {
  description = "AWS region (any value works for LocalStack)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for all resources"
  type        = string
  default     = "devops-lab"
}
