################################################################################
# Local variables
################################################################################

locals {
  user_data = <<-EOT
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "export env=${var.environment}" >> /etc/environment
source /etc/environment

echo "Starting CodeDeploy agent installation..."

# Update the instance
sudo yum -y update

# Install required packages
sudo yum -y install ruby wget

# Download the CodeDeploy agent installation script
cd /home/ec2-user
wget https://aws-codedeploy-us-west-2.s3.us-west-2.amazonaws.com/latest/install

# Make the installation script executable
chmod +x ./install

# Install the CodeDeploy agent
sudo ./install auto

echo "CodeDeploy agent installation completed."

# Check the status of the CodeDeploy agent
sudo service codedeploy-agent status

EOT
}

################################################################################
# Supporting Resources
################################################################################

# Security group for Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "terrasample-alb-sg"
  description = "Maintain access of load balancer traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.agw_sg_id]
  }

  tags = merge(
    { Name = "terrasample-alb-sg" },
    var.asg_tags
  )
}

# Security Group for Auto Scaling Group
resource "aws_security_group" "asg_sg" {
  name        = "terrasample-asg-sg"
  description = "Maintain access of Auto Scaling Group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.ec2_connect_endpoint_sg_id]
  }

  tags = merge(
    { Name = "terrasample-asg-sg" },
    var.asg_tags
  )
}

# Create IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_iam_role" {
  name                  = "terrasample-ec2-iam-role"
  description           = "Allows EC2 instances to call AWS services on your behalf."
  force_detach_policies = false
  max_session_duration  = 3600
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
    Version = "2012-10-17"
  })
  tags = var.asg_tags
}


# EC2 IAM Role policy attachement
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  ])

  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = each.value
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "terrasample-ec2-instance-profile"
  role = aws_iam_role.ec2_iam_role.name
}

################################################################################
# * Application load balancer (ALB)
################################################################################
module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "9.13.0"
  name                       = var.alb_name
  vpc_id                     = var.vpc_id
  subnets                    = var.vpc_public_subnets
  internal                   = true
  security_groups            = [aws_security_group.alb_sg.id]
  enable_deletion_protection = var.del_protection


  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "tg-asg"
      }
    }
  }

  target_groups = {
    tg-asg = {
      name                              = "terrasample-${var.environment}-tg"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      stickiness                        = { "enabled" = true, "type" = "lb_cookie" }
      load_balancing_cross_zone_enabled = true
      create_attachment                 = false
      health_check = {
        enabled             = true
        interval            = 180
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    },
  }

  tags = var.asg_tags
}


################################################################################
# * Autoscaling scaling group (ASG)
################################################################################
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.1"

  # Autoscaling group configs
  name = var.asg_name

  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = var.asg_health_check_type
  vpc_zone_identifier = var.vpc_private_subnets
  # security_groups           = [aws_security_group.asg_sg.id]

  user_data = base64encode(local.user_data)
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances"
  ]


  # Traffic source attachment
  traffic_source_attachments = {
    tg-alb = {
      traffic_source_identifier = module.alb.target_groups["tg-asg"].arn
      traffic_source_type       = "elbv2"
    }
  }

  # EC2 Launch template
  launch_template_name        = "terrasample-${var.environment}-lt"
  launch_template_description = "terrasample-${var.environment}-lt"
  update_default_version      = true
  image_id                    = var.asg_image_id
  instance_type               = var.asg_instance_type
  enable_monitoring           = var.asg_enable_monitoring
  key_name                    = var.asg_key_name

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_name   = aws_iam_instance_profile.ec2_instance_profile.name

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.asg_block_volume_size
        volume_type           = "gp3"
      }
    }
  ]

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [aws_security_group.asg_sg.id, var.ec2_rds_sg_id]
    }
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = var.asg_instance_tags
    },
    {
      resource_type = "volume"
      tags          = var.asg_volume_tags
    }
  ]

  # Auto Scaling Policies
  scaling_policies = {
    avg-cpu-policy = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 80.0
      }
    },
  }

  tags = var.asg_tags
}
