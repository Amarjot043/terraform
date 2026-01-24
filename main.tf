
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

backend "s3" {
    bucket         = "malu-terraform-state-001"
    key            = "cloud-ops/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
}
}

provider "aws" {
  region = var.region
}

# ----------------------------
# Security Group allowing SSH for admin access
# and HTTP for public web traffic
#IGNORE THIS LINE
# ----------------------------
resource "aws_security_group" "cloud_ops_sg" {
  name        = "cloud-ops-sg"
  description = "Allow SSH and HTTP access"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-ops-security-group"
  }
}

# ----------------------------
# EC2 Instance change
# ----------------------------
resource "aws_instance" "cloud_ops_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.cloud_ops_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "terraform-cloud-ops-ec2"
  }
}

# ----------------------------
# Output
# ----------------------------
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.cloud_ops_ec2.public_ip
}
