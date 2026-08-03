terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reads the EKS cluster's outputs via local-backend remote state — no
# S3/DynamoDB, same reasoning as every other terraform/*/providers.tf here.
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
