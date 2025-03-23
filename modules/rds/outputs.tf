# * Security Group Outputs
output "ec2_rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.ec2_rds_sg.id
}

output "ec2_rds_sg_name" {
  description = "Security group name for RDS"
  value       = aws_security_group.ec2_rds_sg.name
}


