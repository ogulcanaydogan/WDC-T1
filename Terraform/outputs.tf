# --- Outputs ---
output "public_ip" {
  value = aws_instance.coolify.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.coolify.public_ip}"
}

output "coolify_url" {
  value = "http://${aws_instance.coolify.public_ip}"
}
