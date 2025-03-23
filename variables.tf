# * Tags
variable "project" {
  description = "Project Name"
  type        = string
  default     = "terrasample"
}
variable "createdby" {
  description = "Current Developer"
  type        = string
}

# * General 
variable "aws_region" {
  description = "Region code"
  type        = string
}
variable "profile" {
  description = "Environment AWS Profile"
  type        = string

}
variable "environment" {
  description = "Environment Name"
  type        = string

  validation {
    condition     = var.environment == terraform.workspace
    error_message = "Workspace & Variable File Inconsistency!! Please Double Check!!"
  }
}

# Deployment
variable "enable_batch_codepipeline" {
  description = "Flag to enable batch codepipeline"
  type        = bool
  default     = true
}

# * VPC
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  description = "List of public subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "vpc_private_subnets" {
  description = "List of private subnet CIDR ranges"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
}

variable "vpc_single_nat_gateway" {
  description = "Should vpc keep one shared nat gateway or nat gateway for each AZ"
  type        = bool
}

variable "enable_nat_gateway" {
  description = "NAT Gateway or NAT Instance"
  type        = bool
}

variable "agw_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "stage_name" {
  description = "Stage Name of the API Gateway"
  type        = string
}

variable "hosted_zone_name" {
  description = "Name of the Hosted Zone of the domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name for API Gateway"
  type        = string
}

variable "domain_certificate_arn" {
  description = "Domain Name Certification ARN"
  type        = string
}

#* Application Load Balander Variables
variable "alb_name" {
  description = "Application Load Balancer Name"
  type        = string
}

variable "del_protection" {
  description = "Application load balancer delete protection"
  type        = bool
}

#* Auto Scaling Group Variables
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

variable "asg_wait_for_capacity_timeout" {
  description = "Auto scaling wait for capacity timeout"
  type        = number
  default     = "300"
}

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
variable "instance_tags" {
  description = "Tags to apply to autoscaling group"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID of the RDS instance"
  type        = string
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
}

# Batch EC2 Variables
variable "batch_image_id" {
  description = "Batch EC2 Image ID"
  type        = string
  default     = ""
}

variable "batch_instance_type" {
  description = "Batch EC2 Instance Type"
  type        = string
  default     = "t4g.small"
}

variable "batch_enable_monitoring" {
  description = "Batch EC2 Enable Monitoring"
  type        = bool
  default     = false
}

variable "batch_key_name" {
  description = "Batch EC2 Key Name"
  type        = string
  default     = ""
}

variable "batch_block_volume_size" {
  description = "Batch EC2 Block Volume Size"
  type        = number
  default     = 20
}
# * CDN Variables
variable "cdn_bucket_name" {
  description = "Name of the S3 bucket to store images"
  type        = string
}

variable "cdn_custom_domain" {
  description = "Custom domain for the CloudFront distribution"
  type        = string
}

variable "cdn_custom_domain_acm" {
  description = "ARN of the ACM Certificate for the custom domain"
  type        = string
}

variable "cdn_price_class" {
  description = "Price class for the CloudFront distribution"
  type        = string
  default     = "PriceClass_200"
}

variable "cdn_aliases" {
  description = "Additional aliases for the CloudFront distribution"
  type        = list(string)
}

variable "waf_rate_limit_value" {
  description = "WAF Rate Limit Value for request within 5 minute"
  type        = number
}

