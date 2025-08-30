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
  description = "EC2 instance type for the Dokploy host"
  type        = string
  default     = "t3a.small"
}

variable "root_volume_gb" {
  description = "Root volume size for the instance"
  type        = number
  default     = 40
}

variable "vpc_id" {
  description = "Optional VPC ID. If null, the default VPC is used."
  type        = string
  default     = null
}

# Your admin IP/CIDR (use x.x.x.x/32). Default is wide-open; override in tfvars for safety.
variable "admin_cidr" {
  description = "CIDR allowed for SSH and Dokploy UI on 3000 (use YOUR_IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

# Let callers override, otherwise we'll supply a default via locals.
variable "ingress_rules" {
  description = "Optional override for ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidrs       = list(string)
    description = optional(string)
  }))
  default = null
}

variable "egress_rules" {
  description = "List of variable-driven egress rules"
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
    Project   = "dokploy"
    ManagedBy = "terraform"
  }
}



