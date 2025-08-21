# output "public_ip" {
#   value = aws_instance.coolify.public_ip
# }

# output "ssh_command" {
#   value = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.coolify.public_ip}"
# }

# # Coolify serves via Traefik on :80 (and later :443 after SSL)
# output "coolify_url" {
#   value = "http://${aws_instance.coolify.public_ip}"
# }
