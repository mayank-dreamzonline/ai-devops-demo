# GHCR image-pull secret for each namespace — GHCR stays private (see
# PROGRESS_ci_cd_demo.md), so the cluster needs credentials to pull the
# CI/CD demo app's image. The token itself is never hardcoded here: supply
# it via a gitignored terraform.tfvars (see terraform.tfvars.example) or
# TF_VAR_ghcr_token, never commit the real value.

variable "ghcr_username" {
  type        = string
  description = "GitHub username/org that owns the GHCR packages."
}

variable "ghcr_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages scope, for pulling the private GHCR image. Supply via a gitignored terraform.tfvars or TF_VAR_ghcr_token — never commit the real value."
}

locals {
  ghcr_dockerconfigjson = jsonencode({
    auths = {
      "ghcr.io" = {
        username = var.ghcr_username
        password = var.ghcr_token
        auth     = base64encode("${var.ghcr_username}:${var.ghcr_token}")
      }
    }
  })
}

resource "kubernetes_secret" "ghcr_pull" {
  for_each = {
    dev     = kubernetes_namespace.dev.metadata[0].name
    staging = kubernetes_namespace.staging.metadata[0].name
    prod    = kubernetes_namespace.prod.metadata[0].name
  }

  metadata {
    name      = "ghcr-pull-secret"
    namespace = each.value
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.ghcr_dockerconfigjson
  }
}
