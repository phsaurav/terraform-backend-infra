################################################################################
# Supporting Resources
################################################################################

# Security group for API Gateway
resource "aws_security_group" "agw-sg" {
  name        = "terrasample-agw-sg"
  description = "For API Gateway Connected with VPC Link"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "terrasample-agw-sg" },
    var.vpc_tags
  )
}

# Security group for EC2 Instance Connect Endpoint
resource "aws_security_group" "ec2-connect-endpoint-sg" {
  name        = "terrasample-ec2-connect-endpoint-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  tags = merge(
    { Name = "terrasample-ec2-connect-endpoint-sg" },
    var.vpc_tags
  )
}

################################################################################
# Virtual private cloud (VPC)
################################################################################

# Get the availability zones
data "aws_availability_zones" "available" {}

# Get the first 3 availability zones
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Create the VPC
module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "5.18.1"
  name                   = var.vpc_name
  cidr                   = var.vpc_cidr
  azs                    = local.azs
  private_subnets        = var.vpc_private_subnets
  public_subnets         = var.vpc_public_subnets
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.vpc_single_nat_gateway
  one_nat_gateway_per_az = var.vpc_one_natgateway_per_az
  tags                   = var.vpc_tags
}

# Prevent the VPC from being destroyed
resource "null_resource" "prevent_destroy" {

  depends_on = [
    module.vpc
  ]

  triggers = {
    vpc_id = module.vpc.vpc_id
  }

  lifecycle {
    prevent_destroy = true
  }
}

################################################################################
# NAT Instancce Setup
################################################################################
locals {
  user_data = <<-EOT
#!/bin/bash
# Update and install iptables
sudo yum update -y
sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo /sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save
EOT
}


# NAT instance (only for dev for cost optimization)
resource "aws_instance" "nat" {
  count         = var.enable_nat_gateway ? 0 : 1
  ami           = var.nat_instance_image_id
  instance_type = "t4g.nano"
  subnet_id     = module.vpc.public_subnets[0]

  associate_public_ip_address = true
  source_dest_check           = false

  vpc_security_group_ids = [aws_security_group.nat[0].id]



  user_data = base64encode(local.user_data)

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-instance"
    },
    var.vpc_tags
  )
}

# Security group for NAT instance (only for dev)
resource "aws_security_group" "nat" {
  count       = var.enable_nat_gateway ? 0 : 1
  name        = "${var.vpc_name}-nat-sg"
  description = "Security group for NAT instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.vpc_private_subnets
    description = "Allow all Private Subnet"
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-sg"
    },
    var.vpc_tags
  )
}

# Add this new resource to update existing private route tables
resource "aws_route" "private_nat_instance" {
  count                  = var.enable_nat_gateway ? 0 : length(module.vpc.private_route_table_ids)
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[0].primary_network_interface_id

  timeouts {
    create = "5m"
  }
}

################################################################################
# API Gateway
################################################################################
module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "5.2.1"

  cors_configuration = {
    allow_headers = []
    allow_methods = []
    allow_origins = []
  }

  description  = "HTTP API Gateway with VPC links"
  name         = var.agw_name
  stage_name   = var.stage_name
  deploy_stage = true

  # Custom Domain
  hosted_zone_name            = var.hosted_zone_name
  domain_name                 = var.domain_name
  domain_name_certificate_arn = var.domain_certificate_arn


  # Routes & Integration(s)
  routes = {
    "ANY /" = {
      integration = {
        connection_type = "VPC_LINK"
        type            = "HTTP_PROXY"
        method          = "ANY"
        uri             = var.alb_listeners_arn
        vpc_link_key    = "agw_vpc_link"
      }
    }

    "ANY /{proxy+}" = {
      integration = {
        connection_type = "VPC_LINK"
        uri             = var.alb_listeners_arn
        type            = "HTTP_PROXY"
        method          = "ANY"
        vpc_link_key    = "agw_vpc_link"
      }
    }

  }

  # VPC Link
  vpc_links = {
    agw_vpc_link = {
      name               = var.agw_vpc_link_name
      security_group_ids = [aws_security_group.agw-sg.id]
      subnet_ids         = module.vpc.public_subnets
    }
  }

  tags = var.vpc_tags

}


################################################################################
# EC2 Instance Connect Endpoint
################################################################################
resource "aws_ec2_instance_connect_endpoint" "ec2-connect-endpoint" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.ec2-connect-endpoint-sg.id]

  tags = merge(
    { Name = "terrasample-ec2-connect-endpoint" },
    var.vpc_tags
  )
}
