terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Uncomment once you've created the state bucket + lock table.
  # backend "s3" {
  #   bucket         = "REPLACE-ME-terraform-state-bucket"
  #   key            = "three-tier-ha-aws/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "REPLACE-ME-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Random provider is used in database.tf to generate the DB master password.
provider "random" {}