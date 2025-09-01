terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }
}

provider "aws" {
  region = var.region
}

# Default VPC (used if var.vpc_id is null)
data "aws_vpc" "default" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

locals {
  vpc_id = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default[0].id
}

# A subnet in the chosen VPC
data "aws_subnets" "in_vpc" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Latest Ubuntu 24.04 LTS AMI (Canonical owner: 099720109477)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# Ingress/Egress defaults
# -------------------------
locals {
  default_ingress = [
    { from_port = 80,   to_port = 80,   protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP"  },
    { from_port = 443,  to_port = 443,  protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidrs = [var.admin_cidr], description = "SSH (admin)" },
    { from_port = 8000, to_port = 8000, protocol = "tcp", cidrs = [var.admin_cidr], description = "Coolify bootstrap UI" }
  ]

  effective_ingress = length(var.ingress_rules) > 0 ? var.ingress_rules : local.default_ingress
}

resource "aws_security_group" "coolify" {
  name        = "coolify-sg"
  description = "Ingress/egress for Coolify host"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = local.effective_ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidrs
      description = try(ingress.value.description, null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidrs
      description = try(egress.value.description, null)
    }
  }

  tags = merge(var.tags, { Name = "coolify-sg" })
}

resource "aws_instance" "coolify" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.in_vpc.ids[0]
  vpc_security_group_ids      = [aws_security_group.coolify.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  # Install Coolify (installs Docker & Traefik)
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
  EOF

  tags = merge(var.tags, { Name = "coolify-server" })
}

# -------------------------
# Variables
# -------------------------
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "key"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.medium"
}

variable "root_volume_gb" {
  description = "Root volume size for the instance"
  type        = number
  default     = 50
}

variable "vpc_id" {
  description = "Optional VPC ID. If null, the default VPC is used."
  type        = string
  default     = null
}

variable "admin_cidr" {
  description = "CIDR allowed for SSH and first-run UI on 8000 (set to YOUR_IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ingress_rules" {
  description = "Override ingress rules; if empty, secure defaults are applied"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidrs       = list(string)
    description = optional(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "Variable-driven egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidrs       = list(string)
    description = optional(string)
  }))
  default = [
    { from_port = 0, to_port = 0, protocol = "-1", cidrs = ["0.0.0.0/0"], description = "Allow all egress" }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project   = "coolify"
    ManagedBy = "terraform"
  }
}

# -------------------------
# Outputs
# -------------------------
output "public_ip" {
  value       = aws_instance.coolify.public_ip
  description = "Public IP of the Coolify host"
}

output "public_dns" {
  value       = aws_instance.coolify.public_dns
  description = "Public DNS of the Coolify host"
}

output "bootstrap_url" {
  value       = "http://${aws_instance.coolify.public_ip}:8000"
  description = "Open this for first-run setup, then move to your domain over HTTPS"
}
