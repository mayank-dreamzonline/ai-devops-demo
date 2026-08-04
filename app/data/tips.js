const tips = [
  { text: 'Write commit messages that explain why, not what.', category: 'git' },
  { text: 'Use .gitignore before your first commit, not after.', category: 'git' },
  { text: 'Rebase local feature branches; merge shared ones.', category: 'git' },
  { text: 'Use multi-stage builds to keep production images slim.', category: 'docker' },
  { text: 'Run containers as a non-root user whenever possible.', category: 'docker' },
  { text: 'Pin base image versions instead of using `latest`.', category: 'docker' },
  { text: 'Set resource requests and limits on every pod.', category: 'kubernetes' },
  { text: 'Use readiness probes to keep traffic off unready pods.', category: 'kubernetes' },
  { text: 'Namespace your workloads to isolate blast radius.', category: 'kubernetes' },
  { text: 'Pin provider versions to avoid surprise upgrades.', category: 'terraform' },
  { text: 'Use remote state with locking, never local `.tfstate` in a team repo.', category: 'terraform' },
  { text: 'Review `terraform plan` output before every apply.', category: 'terraform' },
];

module.exports = tips;
