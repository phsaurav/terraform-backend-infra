#* Security Group Variables
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "asg_sg_id" {
  description = "RDS security group ID"
  type        = string
}

variable "rds_tags" {
  description = "Tags to apply to autoscaling group"
  type        = map(string)
}

variable "subnet_ids" {
  description = "Set of private subnet ids"
  type        = set(string)
}

variable "environment" {
  description = "The environment (e.g., dev, stage, prod)"
  type        = string
}
