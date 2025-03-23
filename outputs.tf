# * General Outputs
output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "project" {
  description = "The project name"
  value       = var.project
}

# * VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# * ASG Outputs
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.asg.asg_autoscaling_group_name
}

output "asg_instance_security_group_id" {
  description = "The ID of the security group for the ASG instances"
  value       = module.asg.asg_autoscaling_group_id
}

# CodeDeploy Outputs
output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = module.codedeploy.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = module.codedeploy.deployment_group_name
}

# CodePipeline Outputs
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.codepipeline.pipeline_name
}

output "codepipeline_artifact_bucket" {
  description = "Name of the artifact S3 bucket"
  value       = module.codepipeline.artifact_bucket
}

