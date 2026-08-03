output "github_actions_role_arn" {
  description = "Set as the role-to-assume in the CI/CD workflow's OIDC step."
  value       = aws_iam_role.github_actions.arn
}
