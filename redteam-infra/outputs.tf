output "bastion_public_ip" {
  description = "Bastion host - SSH entry point"
  value       = aws_instance.bastion.public_ip
}

output "team_server_private_ip" {
  description = "Team server private IP (reachable only via bastion / redirectors)"
  value       = aws_instance.team_server.private_ip
}

output "redirector_public_ip" {
  description = "HTTP(S) redirector public IP"
  value       = aws_instance.redirector.public_ip
}

output "dns_redirector_public_ip" {
  description = "DNS redirector public IP (set as ns1 glue)"
  value       = aws_instance.dns_redirector.public_ip
}

output "redirector_domain" {
  value = var.redirector_domain != "" ? var.redirector_domain : "not configured"
}

output "dns_c2_domain" {
  value = var.dns_c2_domain != "" ? var.dns_c2_domain : "not configured"
}

# Convenience: SSH to team server by jumping through the bastion.
output "ssh_team_server_via_bastion" {
  description = "ProxyJump command to reach the private team server"
  value       = "ssh -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.team_server.private_ip}"
}

# Tunnel the C2 management console (port 31337) through the bastion.
output "tunnel_c2_console" {
  description = "Forward team server C2 console to localhost:31337"
  value       = "ssh -J ubuntu@${aws_instance.bastion.public_ip} -L 31337:${aws_instance.team_server.private_ip}:31337 ubuntu@${aws_instance.team_server.private_ip}"
}

output "gophish_private_ip" {
  description = "GoPhish private IP (reachable only via bastion / redirector)"
  value       = aws_instance.gophish.private_ip
}

output "phish_redirector_public_ip" {
  description = "Phishing redirector public IP"
  value       = aws_instance.phish_redirector.public_ip
}

output "phishing_domain" {
  value = var.phishing_domain != "" ? var.phishing_domain : "not configured"
}

# Tunnel the GoPhish admin UI through the bastion to your localhost.
output "tunnel_gophish_admin" {
  description = "Forward GoPhish admin UI to https://localhost:3333"
  value = "ssh -J ubuntu@${aws_instance.bastion.public_ip} -L ${var.gophish_admin_port}:${aws_instance.gophish.private_ip}:${var.gophish_admin_port} ubuntu@${aws_instance.gophish.private_ip}"
}

# Retrieve the auto-generated GoPhish admin password.
output "get_gophish_password_cmd" {
  description = "Run on the GoPhish host to retrieve the initial admin password"
  value       = "journalctl -u gophish | grep -i 'please login'"
}
