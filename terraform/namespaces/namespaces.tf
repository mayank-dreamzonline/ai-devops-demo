# Three tiers for the CI/CD demo's promotion flow (see
# PROGRESS_ci_cd_demo.md — gitignored, local only): `dev` is auto-deployed
# on every merge to the app's `QA` branch, no approval gate; `staging` and
# `prod` are both gated by required-reviewer approval on their GitHub
# Environments. Same image tag flows through all three unchanged, never
# rebuilt per environment.

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
    labels = {
      tier = "dev"
    }
  }
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
    labels = {
      tier = "staging"
    }
  }
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = {
      tier = "prod"
    }
  }
}
