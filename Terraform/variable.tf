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

# Default opens 80/443 to world + 3000 for Dokploy UI 
# For production, override in terraform.tfvars and restrict 3000 (and 22) to YOUR.IP/32.
variable "ingress_rules" {
  description = "List of variable-driven ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidrs       = list(string)
    description = optional(string)
  }))
  default = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
    { from_port = 3000, to_port = 3000, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "Dokploy UI (setup)" }
  ]
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
