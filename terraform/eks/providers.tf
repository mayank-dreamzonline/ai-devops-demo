terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Reads the (also pre-provisioned, separately-applied) VPC layer's outputs
# via local-backend remote state — same pattern terraform/app/ and
# terraform/rds/ use to read this directory's own outputs. VPC and EKS are
# split into separate state files/directories so each is an independent
# logical component, matching the production-grade layout the rest of
# terraform/* follows — split later than the others since this cluster was
# already live, so it happened via `terraform state mv`, not from scratch.
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}

# Exec-based auth re-invokes `aws eks get-token` on every provider call, so a
# long-running apply/plan never hits the ~15 minute static-token expiry.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--profile", var.aws_profile,
      "--region", var.aws_region,
    ]
  }
}
