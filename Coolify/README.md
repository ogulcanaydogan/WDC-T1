# Coolify on AWS EC2 (Terraform)

Provision an Ubuntu EC2 instance, open the right ports, and install Coolify automatically via cloud-init.

## What it deploys
- EC2 (Ubuntu 24.04 LTS)
- Security Group:
  - 80/443 open to the internet
  - 8000 (bootstrap UI) and 22 (SSH) restricted to `admin_cidr` by default
- Coolify installation via the official install script

## Prerequisites
- Terraform >= 1.5
- AWS credentials in your shell (e.g. AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- Existing EC2 key pair name (variable `key_name`)
- Your public IP to restrict admin ports (`admin_cidr`, e.g. `X.X.X.X/32`)

## Quick start
1) Create `terraform.tfvars` in this folder (example):

```
region         = "us-east-1"
key_name       = "key"
instance_type  = "t3a.medium"
root_volume_gb = 50
admin_cidr     = "YOUR_IP/32"

# Optional: override ingress
# ingress_rules = [
#   { from_port = 80,  to_port = 80,  protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP" },
#   { from_port = 443, to_port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
#   { from_port = 8000,to_port = 8000,protocol = "tcp", cidrs = ["YOUR_IP/32"], description = "Coolify bootstrap UI" },
#   { from_port = 22,  to_port = 22,  protocol = "tcp", cidrs = ["YOUR_IP/32"], description = "SSH" }
# ]
```

2) Initialize and apply:

```
terraform init
terraform apply -auto-approve
```

## Outputs
- `public_ip` / `public_dns`
- `bootstrap_url` (http://PUBLIC_IP:8000)

Open the bootstrap URL from a machine within `admin_cidr`.

## Accessing Coolify
- First-run: http://PUBLIC_IP:8000 (restricted to `admin_cidr`).
- After setup, configure a domain + HTTPS in Coolify.
  - Keep 80/443 open for HTTP->HTTPS and certificate issuance.
  - You can then tighten/remove the 8000 rule.

## SSH access
Default Ubuntu user:

```
ssh -i /path/to/key.pem ubuntu@PUBLIC_IP
```

## Cleanup

```
terraform destroy -auto-approve
```

## Variables (high level)
- `region` (string, default: us-east-1)
- `key_name` (string) – existing EC2 key pair name
- `instance_type` (string, default: t3a.medium)
- `root_volume_gb` (number, default: 50)
- `vpc_id` (string, default: null for default VPC)
- `admin_cidr` (string, default: 0.0.0.0/0; set YOUR_IP/32!)
- `ingress_rules` (list(object), default: [] – uses sane defaults)
- `egress_rules` (list(object), default: allow all)
- `tags` (map(string))
