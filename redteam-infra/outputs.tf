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
