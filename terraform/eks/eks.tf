# The fault-injection/recovery beat's lever is a node-group taint, not node
# count — three dead ends got ruled out first (see
# docs/internal/architecture.md for the full story):
#
# 1. desired_size can't be it — the module sets
#    `lifecycle { ignore_changes = [scaling_config[0].desired_size] }` on the
#    underlying aws_eks_node_group (so Terraform doesn't fight a cluster
#    autoscaler), so Terraform changes to desired_size are silently ignored
#    after creation.
# 2. max_size = 0 isn't accepted — AWS/the provider require at least 1.
# 3. max_size < current desired_size isn't accepted either, and because of
#    (1) desired_size is permanently stuck at whatever it was at creation —
#    so max_size can never be lowered below it through Terraform, at all.
#
# A NO_SCHEDULE taint sidesteps all of that: it doesn't touch scaling_config,
# it's unambiguously Terraform-managed, and it deterministically blocks
# scheduling regardless of how much node capacity is technically free.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = var.cluster_name

  cluster_endpoint_public_access = true

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  # v20.x defaults this to false, which is the #1 "created the cluster but
  # kubectl says Unauthorized" trap — this grants the applying principal an
  # EKS Access Entry automatically.
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3

      # NO_EXECUTE, not NO_SCHEDULE: whoami is already running from Beat 1 by
      # the time this fault fires, and NO_SCHEDULE only blocks *new*
      # scheduling — the already-running pod would just sit there Running,
      # untouched, with nothing visibly broken. NO_EXECUTE actively evicts
      # pods that don't tolerate it, which then fail to reschedule anywhere
      # (every node carries the same taint) — that's the actual "damage."
      taints = var.fault_active ? {
        fault_injected = {
          key    = "fault-injected"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      } : {}
    }
  }
}
