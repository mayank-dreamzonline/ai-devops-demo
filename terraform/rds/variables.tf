variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "ai-devops-demo"
}

variable "db_identifier" {
  type    = string
  default = "ai-devops-demo-db"
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}
