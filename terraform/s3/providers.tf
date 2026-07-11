terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# No terraform_remote_state read here — S3 buckets don't need placement in
# the base VPC, unlike terraform/rds/. Keep this directory's only dependency
# on base being "the AWS account/region," not a network resource.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
