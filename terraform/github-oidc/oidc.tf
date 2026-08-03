# Lets this repo's GitHub Actions workflows authenticate to AWS via OIDC —
# no static access keys stored as GitHub secrets. See PROGRESS_ci_cd_demo.md
# for the full reasoning.

# The well-known GitHub Actions OIDC thumbprint. AWS provider versions before
# 6.x require this field even though AWS no longer actually validates it for
# GitHub's provider at runtime (GitHub rotated intermediates without
# breaking existing configs) — kept as the documented standard value rather
# than omitted, since we're on the ~> 5.0 provider line used elsewhere in
# this project.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policy: only workflow runs from this specific repo (any branch/PR)
# may assume the role below. Scoped by repo, not narrowed further to
# specific branches — this is a single-repo demo, not a shared account.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "ai-devops-demo-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

# Deliberately narrow: just enough to resolve the cluster's connection
# details (aws eks update-kubeconfig calls this under the hood). Actual
# in-cluster permissions come from the EKS access entry below, not from IAM.
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${data.terraform_remote_state.eks.outputs.cluster_name}"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_eks_describe" {
  name   = "eks-describe-cluster"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

# Bridges the IAM role into the cluster's own (separate) RBAC system. Scoped
# to just the three CI/CD namespaces with edit (not admin) permissions —
# the role can deploy/update workloads there, nothing cluster-wide.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
}

resource "aws_eks_access_policy_association" "github_actions_edit" {
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["dev", "staging", "prod"]
  }
}
