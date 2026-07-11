terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reads the VPC layer's outputs directly via local-backend remote state — no
# S3/DynamoDB, a single-operator demo has no need for remote state locking
# (same reasoning as terraform/app/providers.tf). Use
# data.terraform_remote_state.vpc.outputs.{vpc_id,private_subnet_ids,
# vpc_cidr_block} for the DB subnet group and security group — don't
# duplicate the network definition here, and don't go through terraform/eks/
# for this, it doesn't hold VPC state.
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
