terraform {
  required_version = ">= 1.7"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

# Reads the pre-provisioned base cluster's outputs via local-backend remote
# state — no S3/DynamoDB, a single-operator demo has no need for remote
# state locking.
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "${path.module}/../base/terraform.tfstate"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.base.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.base.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", data.terraform_remote_state.base.outputs.cluster_name,
      "--profile", var.aws_profile,
      "--region", data.terraform_remote_state.base.outputs.region,
    ]
  }
}
