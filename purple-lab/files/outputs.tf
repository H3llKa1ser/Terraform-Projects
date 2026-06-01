output "bastion_public_ip" {
  description = "Bastion - SSH entry point"
  value       = aws_instance.bastion.public_ip
}

output "siem_private_ip" {
  value = aws_instance.siem.private_ip
}

output "target_private_ip" {
  value = aws_instance.target.private_ip
}

output "caldera_private_ip" {
  value = aws_instance.caldera.private_ip
}

# Tunnel the Wazuh dashboard to https://localhost:8443
output "tunnel_wazuh_dashboard" {
  description = "Forward Wazuh dashboard through the bastion"
  value       = "ssh -J ubuntu@${aws_instance.bastion.public_ip} -L 8443:${aws_instance.siem.private_ip}:443 ubuntu@${aws_instance.siem.private_ip}"
}

# Tunnel the Caldera UI to http://localhost:8888
output "tunnel_caldera_ui" {
  description = "Forward Caldera UI through the bastion"
  value       = "ssh -J ubuntu@${aws_instance.bastion.public_ip} -L 8888:${aws_instance.caldera.private_ip}:8888 ubuntu@${aws_instance.caldera.private_ip}"
}

output "ssh_target" {
  value = "ssh -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.target.private_ip}"
}
