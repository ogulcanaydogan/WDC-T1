variable "aws_region" {
  description = "AWS region (e.g., eu-west-2)"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.small"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in the chosen region"
  type        = string
  default     = "key"
}

variable "ssh_cidr" {
  description = "CIDR allowed for SSH (e.g., 1.2.3.4/32). Defaults to open."
  type        = string
  default     = "0.0.0.0/0"
}

variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "coolify"
}

