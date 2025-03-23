variable "environment" {
  description = "The environment (e.g., dev, stage, prod)"
  type        = string
}

# * Security Group Variables
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "agw_sg_id" {
  description = "Auto Scaling Group Security Group ID"
  type        = string
}
variable "ec2_rds_sg_id" {
  description = "Auto Scaling Group Security Group ID"
  type        = string
}

variable "ec2_connect_endpoint_sg_id" {
  description = "EC2 Connect VPC Endpoint Security Group ID"
  type        = string
}

# * Auto Scaling Group Variables
variable "vpc_private_subnets" {
  description = "Private subnet list of the VPC"
  type = set(string)
}

variable "vpc_public_subnets" {
  description = "Private subnet list of the VPC"
  type = set(string)
}

variable "asg_name" {
  description = "Application Load Balancer Name"
  type        = string

}

variable "asg_min_size" {
  description = "Auto scaling minimum size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Auto scaling maximum size"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Auto scaling desired capacity"
  type        = number
  default     = 1
}

variable "asg_health_check_type" {
  description = "Auto scaling health check type"
  type        = string
  default     = "EC2"
}


# * Launch Template
variable "asg_image_id" {
  description = "Auto scaling group image id"
  type        = string

}

variable "asg_instance_type" {
  description = "Auto scaling group instance type"
  type        = string
}
variable "asg_enable_monitoring" {
  description = "Auto scaling group enable monitoring"
  type        = bool
  default     = true
}

variable "asg_key_name" {
  description = "Auto scaling group instance keypair key"
  type        = string
  default     = "terrasample-gps-asg-key"
}

variable "asg_block_volume_size" {
  description = "Auto scaling instances block volume size"
  type        = number
  default     = 20
}
variable "asg_tags" {
  description = "Tags to apply to autoscaling group"
  type = map(string)
}
variable "asg_instance_tags" {
  description = "Tags to apply to autoscaling group"
  type = map(string)
}
variable "asg_volume_tags" {
  description = "Tags to apply to autoscaling group"
  type = map(string)
  default = {}
}

#* Application Load Balander Variables
variable "alb_name" {
  description = "Application Load Balancer Name"
  type        = string
}

variable "del_protection" {
  description = "Application load balancer delete protection"
  type        = bool
  default     = true
}



