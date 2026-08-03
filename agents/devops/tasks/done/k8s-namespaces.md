# k8s-namespaces

**Request:** Create `dev`/`staging`/`prod` Kubernetes namespaces on the
existing EKS cluster, via Terraform, per the CI/CD demo design pinned in
`PROGRESS_ci_cd_demo.md` (Mayank, in-conversation request — not from a
written `inbox/` brief this time).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/4 —
merged. `terraform/vpc` and `terraform/eks` applied for real first (19 +
35 resources, cluster `ai-devops-demo` live, 2 nodes Ready), then
`terraform/namespaces` planned (3 to add) and applied clean. Verified:
`kubectl get namespaces dev staging prod` — all three `Active`.
