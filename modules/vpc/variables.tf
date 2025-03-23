# * VPC variables
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


variable "vpc_tags" {
  description = "Tags to apply to vpc peering for api x data vpc"
  type        = map(string)
}

variable "vpc_single_nat_gateway" {
  description = "Should vpc keep one shared nat gateway"
  type        = bool
  default     = true
}

variable "vpc_one_natgateway_per_az" {
  description = "One Nat Gateway Per AZ for high relaiability"
  type        = bool
  default     = false
}

# * API Gateway Variables
variable "agw_sg_name" {
  description = "Name of the API Gateway Security Group"
  type        = string
  default     = "agw_sg"
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

variable "agw_vpc_link_name" {
  description = "Name of the API Gateway VPC Link"
  type        = string
  default     = "agw_vpc_link"
}
variable "alb_listeners_arn" {
  description = "Name of the API Gateway VPC Link"
  type        = string
}

variable "enable_nat_gateway" {
  description = "NAT Gateway or NAT Instance"
  type        = bool
}

variable "nat_instance_image_id" {
  description = "NAT instance image id"
  type        = string
  default     = "ami-01ca4016fdc24128c"
}
