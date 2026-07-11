variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "ai-devops-demo"
}

# S3 bucket names are globally unique across all AWS accounts, so this is a
# prefix, not the final name — the account ID gets appended in s3.tf.
variable "bucket_name_prefix" {
  type    = string
  default = "ai-devops-demo-data"
}
