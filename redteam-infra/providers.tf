terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Remote state — keep engagement state out of local disk / git.
  backend "s3" {
    bucket         = "CHANGE-ME-redteam-tfstate"
    key            = "engagement/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "redteam-tf-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Engagement = var.engagement_name
      ManagedBy  = "terraform"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
