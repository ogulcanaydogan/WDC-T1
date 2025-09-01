output "public_ip" {
  description = "Public IPv4 of the Dokploy host"
  value       = aws_instance.dokploy.public_ip
}

output "public_dns" {
  description = "Public DNS of the Dokploy host"
  value       = aws_instance.dokploy.public_dns
}

output "admin_panel_url_by_ip" {
  description = "URL to access the Dokploy admin panel via Public IP (port 3000)"
  value       = "http://${aws_instance.dokploy.public_ip}:3000"
}

output "admin_panel_url_by_dns" {
  description = "URL to access the Dokploy admin panel via Public DNS (port 3000)"
  value       = "http://${aws_instance.dokploy.public_dns}:3000"
}
