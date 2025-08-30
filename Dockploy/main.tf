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

# Latest Ubuntu 24.04 LTS AMI (Canonical owner: 099720109477)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "dokploy" {
  name        = "dokploy-sg"
  description = "Security group driven by ingress/egress variables"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = local.effective_ingress_rules
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

  tags = merge(var.tags, { Name = "dokploy-sg" })
}

resource "aws_instance" "dokploy" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.dokploy.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  # Install Dokploy (installs Docker if missing)
  user_data = <<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl
    curl -sSL https://dokploy.com/install.sh | sh
  EOF

  tags = merge(var.tags, { Name = "dokploy-server" })
}
