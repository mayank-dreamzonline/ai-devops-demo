# github-oidc

**Request:** Create a GitHub OIDC identity provider + IAM role + EKS access
entry so the CI/CD workflow can authenticate to AWS/EKS without static
access keys, per the CI/CD demo design pinned in `PROGRESS_ci_cd_demo.md`
(Mayank, in-conversation request).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/6 —
merged, applied (5 resources: OIDC provider, IAM role, IAM role policy,
EKS access entry, EKS access policy association). Verified via
`aws eks list-access-entries` — `ai-devops-demo-github-actions` role
present. Role ARN:
`arn:aws:iam::713415772392:role/ai-devops-demo-github-actions`.
