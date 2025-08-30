output "public_ip" {
  description = "Public IPv4 of the Dokploy host"
  value       = aws_instance.dokploy.public_ip
}

output "public_dns" {
  description = "Public DNS of the Dokploy host"
  value       = aws_instance.dokploy.public_dns
}
