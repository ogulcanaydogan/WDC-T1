terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Networking: use the default VPC & a public subnet ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- AMI: Ubuntu 22.04 LTS (Jammy) ---
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security Group: SSH + HTTP/HTTPS only ---
resource "aws_security_group" "coolify_sg" {
  name_prefix = "${var.name_prefix}-" # AWS ensures uniqueness
  description = "Allow SSH and HTTP/HTTPS for Coolify"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr != "" ? var.ssh_cidr : "0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TEMP: Coolify UI on port 8000 until you set a hostname + SSL
  ingress {
    description = "Coolify UI (temporary)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Realtime WebSocket ports for Coolify UI
  ingress {
    description = "Coolify Realtime"
    from_port   = 6001
    to_port     = 6002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Outbound: allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

# --- cloud-init user_data (install Docker + Coolify as root) ---
locals {
  user_data = <<-BASH
    #!/usr/bin/env bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl git jq ca-certificates gnupg htop

    # Install Docker and enable it
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker

    # Optional: add small swap (2G) to help with builds
    if ! swapon --summary | grep -q '.'; then
      fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    # Install Coolify as ROOT (recommended)
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

    # Ensure the stack is up
    docker compose -f /root/.coolify/docker-compose.yml up -d
  BASH
}

# --- Instance ---
resource "aws_instance" "coolify" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default_public.ids, 0)
  vpc_security_group_ids      = [aws_security_group.coolify_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data                   = local.user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${var.name_prefix}-vm"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }
}
