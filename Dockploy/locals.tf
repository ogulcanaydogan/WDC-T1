locals {
  # Default rules (HTTP/HTTPS open; 3000 and 22 restricted to admin_cidr)
  ingress_rules_default = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
    { from_port = 3000, to_port = 3000, protocol = "tcp", cidrs = [var.admin_cidr], description = "Dokploy UI (setup)" },
    { from_port = 22, to_port = 22, protocol = "tcp", cidrs = [var.admin_cidr], description = "SSH" }
  ]

  # Use user-supplied ingress_rules if provided; else use our default above
  effective_ingress_rules = coalesce(var.ingress_rules, local.ingress_rules_default)
}
