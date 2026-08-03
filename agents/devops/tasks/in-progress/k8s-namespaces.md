# k8s-namespaces

**Request:** Create `dev`/`staging`/`prod` Kubernetes namespaces on the
existing EKS cluster, via Terraform, per the CI/CD demo design pinned in
`PROGRESS_ci_cd_demo.md` (Mayank, in-conversation request — not from a
written `inbox/` brief this time).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/4 —
`terraform validate` clean. Waiting on merge before plan/apply (also
needs `terraform/eks` live first — currently 0 resources).
