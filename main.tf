# Check existing tag to avoid modifying existing resources on current tag change
data "aws_vpc" "existing_tags" {
  filter {
    name   = "tag:Project"
    values = [var.project]
  }
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

# Provider configuration for WAF
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

locals {
  existing_tags = data.aws_vpc.existing_tags.tags

  tags = {
    Project     = var.project
    CreatedBy   = lookup(local.existing_tags, "CreatedBy", var.createdby)
    Environment = var.environment
    TFWorkspace = terraform.workspace
  }
}

# * VPC Module
module "vpc" {
  source                 = "./modules/vpc"
  vpc_name               = var.vpc_name
  vpc_cidr               = var.vpc_cidr
  vpc_private_subnets    = var.vpc_private_subnets
  vpc_public_subnets     = var.vpc_public_subnets
  agw_name               = var.agw_name
  stage_name             = var.stage_name
  hosted_zone_name       = var.hosted_zone_name
  domain_name            = var.domain_name
  domain_certificate_arn = var.domain_certificate_arn
  alb_listeners_arn      = module.asg.http_listener_arn
  enable_nat_gateway     = var.enable_nat_gateway
  vpc_tags               = local.tags
}

# * Auto Scaling Group & Supporting Modules
module "asg" {
  source                     = "./modules/asg"
  asg_name                   = var.asg_name
  alb_name                   = var.alb_name
  vpc_id                     = module.vpc.vpc_id
  agw_sg_id                  = module.vpc.agw_sg_id
  vpc_private_subnets        = module.vpc.private_subnets
  vpc_public_subnets         = module.vpc.public_subnets
  del_protection             = var.del_protection
  asg_min_size               = var.asg_min_size
  asg_max_size               = var.asg_max_size
  asg_desired_capacity       = var.asg_desired_capacity
  ec2_connect_endpoint_sg_id = module.vpc.ec2_connect_endpoint_sg_id
  ec2_rds_sg_id              = module.rds.ec2_rds_sg_id

  #launch template
  environment           = var.environment
  asg_instance_type     = var.asg_instance_type
  asg_image_id          = var.asg_image_id
  asg_enable_monitoring = var.asg_enable_monitoring
  asg_key_name          = var.asg_key_name
  asg_block_volume_size = var.asg_block_volume_size
  asg_instance_tags = merge(
    var.instance_tags,
    local.tags
  )
  asg_tags = local.tags

}

# * RDS Supporting Module
module "rds" {
  source          = "./modules/rds"
  vpc_id          = module.vpc.vpc_id
  asg_sg_id       = module.asg.asg_sg_id
  subnet_ids      = module.vpc.private_subnets
  environment     = var.environment
  vpc_cidr_block  = var.vpc_cidr_block
  batch_rds_sg_id = module.batch.batch_rds_sg_id

  rds_tags = local.tags
}


# * WAF Module
module "waf" {
  source               = "./modules/waf"
  cdn_bucket_name      = var.cdn_bucket_name
  waf_rate_limit_value = var.waf_rate_limit_value
  profile              = var.profile
}

# * CDN Module
module "cdn" {
  source                = "./modules/cdn"
  cdn_bucket_name       = var.cdn_bucket_name
  cdn_custom_domain     = var.cdn_custom_domain
  cdn_aliases           = var.cdn_aliases
  cdn_hosted_zone       = var.hosted_zone_name
  cdn_custom_domain_acm = var.cdn_custom_domain_acm
  waf_arn               = module.waf.waf_arn
  cdn_tags              = local.tags
}
