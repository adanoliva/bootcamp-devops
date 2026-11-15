terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "lab-vpc"
  cidr = "10.0.0.0/16"

  azs                     = ["eu-west-3a"]
  public_subnets          = ["10.0.1.0/24"]
  map_public_ip_on_launch = true
  enable_dns_hostnames    = true

  enable_nat_gateway = false
}

variable "my_ip" {
  description = "IP pública desde la que se permite SSH"
  type        = string
}

resource "aws_security_group" "web" {
  name        = "lab-web-sg"
  description = "HTTP para todos y SSH solo desde mi IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde mi IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab-web-sg"
  }
}

resource "aws_key_pair" "lab" {
  key_name   = "lab-key"
  public_key = file(pathexpand("~/.ssh/lab-ec2.pub"))
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.lab.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "lab-web"
  }
}

output "public_ip" {
  description = "IP pública de la instancia"
  value       = aws_instance.web.public_ip
}
