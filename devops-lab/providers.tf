terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"

  # Skip credential/account checks (LocalStack doesn't need real ones)
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requested_account_id   = true

  # Force path-style S3 access for LocalStack
  s3_use_path_style = true

  # Point every AWS service at LocalStack's edge port
  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
  }
}
