################################################################################
# Supporting Resources
################################################################################

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "terrasample-rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = "terrasample-rds-sg" },
    var.rds_tags
  )
}

# EC2 to RDS Security Group
resource "aws_security_group" "ec2_rds_sg" {
  name        = "terrasample-ec2-rds-sg"
  description = "EC2 to RDS Security Group"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = "terrasample-ec2-rds-sg" },
    var.rds_tags
  )
}

# RDS Security Group Rules
resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ec2_rds_sg.id
}

# EC2 to RDS Security Group Rules
resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_rds_sg.id
  source_security_group_id = aws_security_group.rds_sg.id
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "terrasample-db-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Terrasample Subnet Group"

  tags = merge(
    { Name = "terrasample-db-subnet-group" },
    var.rds_tags
  )
}


