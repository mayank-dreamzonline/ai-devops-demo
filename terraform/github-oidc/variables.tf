variable "aws_profile" {
  type    = string
  default = "ai-devops-demo"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo allowed to assume the CI/CD role, as owner/repo."
  default     = "mayank-dreamzonline/ai-devops-demo"
}
