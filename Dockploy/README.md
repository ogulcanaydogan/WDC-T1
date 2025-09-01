# Dokploy on AWS EC2 (Terraform)

Provision an Ubuntu EC2 instance, open the right ports, and install Dokploy automatically via cloud-init.

## What it deploys
- EC2 (Ubuntu 24.04 LTS)
- Security Group:
  - 80/443 open to the internet
  - 3000 (Dokploy UI) and 22 (SSH) restricted to `admin_cidr` by default
- Dokploy installation via the official install script

## Prerequisites
- Terraform >= 1.5
- AWS credentials in your shell (e.g. AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- Existing EC2 key pair name (variable `key_name`)
- Your public IP to restrict admin ports (`admin_cidr`, e.g. `X.X.X.X/32`)

## Quick start
1) Create `terraform.tfvars` in this folder (example):

```
region         = "us-east-1"
key_name       = "key"            # existing EC2 key pair name
instance_type  = "t3a.small"
root_volume_gb = 40
admin_cidr     = "YOUR_IP/32"     # e.g. 54.145.46.49/32

# Optional: fully override ingress rules
# ingress_rules = [
#   { from_port = 80,  to_port = 80,  protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP" },
#   { from_port = 443, to_port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
#   { from_port = 3000,to_port = 3000,protocol = "tcp", cidrs = ["YOUR_IP/32"], description = "Dokploy UI (setup)" },
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
- `admin_panel_url_by_ip` (http://PUBLIC_IP:3000)
- `admin_panel_url_by_dns` (http://PUBLIC_DNS:3000)

Open the admin URL from a machine within `admin_cidr`.

## Accessing Dokploy
- First-run: http://PUBLIC_IP:3000 (restricted to `admin_cidr`).
- After setup, configure a domain + HTTPS inside Dokploy.
  - Keep 80/443 open for HTTP->HTTPS and certificate issuance.
  - You can then tighten/remove the 3000 rule in the Security Group.

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
- `instance_type` (string, default: t3a.small)
- `root_volume_gb` (number, default: 40)
- `vpc_id` (string, default: null for default VPC)
- `admin_cidr` (string, default: 0.0.0.0/0; set YOUR_IP/32!)
- `ingress_rules` (list(object), default: null – uses secure defaults)
- `egress_rules` (list(object), default: allow all)
- `tags` (map(string))
